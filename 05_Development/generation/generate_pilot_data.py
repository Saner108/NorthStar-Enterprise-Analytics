#!/usr/bin/env python3
"""
NorthStar Retail Group — Inventory Visibility Pilot
Synthetic Data Generation Script (Stage 1 of the pipeline)

Purpose:
    Produce the five raw CSV staging files that feed the pilot star schema, as
    specified in:
      - 05_Development/Data_Generation_Pipeline_Design.md
      - 03_Data_Discovery/Source_to_Target_Mapping.md
      - 04_Analytics_Design/Dimension_Table_Specifications.md  (SCD Type 2)
      - 04_Analytics_Design/Fact_Table_Specification.md         (grain / volume)
      - 03_Data_Discovery/Business_Rules_Catalog.md             (BR-008/8a/8b)

Design notes (see IMPLEMENTATION_BRIEF.md — "The 8 Decisions That Matter Most"):
    * Two fact tables at two grains: Fact_Sales (per SKU per transaction) and
      Fact_Inventory_Snapshot (per location per SKU per day). Not merged.
    * Fact_Inventory_Snapshot uses a full DAILY SNAPSHOT grain (not event-based
      logging) — a deliberate risk-reduction trade-off.
    * Dim_Product implements SCD Type 2 on Category ONLY, for exactly one
      deliberately-reclassified SKU (Electronics -> Home Goods mid-year), which
      produces two Dim_Product rows sharing one SKU but two Product_Keys.
    * Surrogate keys (Date_Key, Store_Key, Product_Key) are resolved HERE, at
      generation time, so the fact CSVs are load-ready. Product_Key is resolved
      to the version EFFECTIVE ON the fact row's date, not simply the current
      version.
    * Deliberate known-answer test cases are injected so KPI-P03 and the SCD2
      join can be validated against a known truth, not merely run without error:
        - >= 1 stockout classified "Distribution Issue" (pooled regional QOH > 0)
        - >= 1 stockout classified "True Shortage"      (pooled regional QOH = 0)
        - the one SCD Type 2 category-reclassification SKU

Output (written to <out_dir>, default: ../data/staging):
    dim_store.csv, dim_product.csv, dim_date.csv,
    fact_sales.csv, fact_inventory_snapshot.csv
    _known_test_cases.json  (records the injected cases for validation/reference)

The script is deterministic: the same --seed always produces the same output.
Standard library only — no third-party dependencies.
"""

import argparse
import csv
import json
import os
import random
import math
from datetime import date, timedelta

# ---------------------------------------------------------------------------
# Fixed pilot parameters (per the planning documents)
# ---------------------------------------------------------------------------
PILOT_START = date(2025, 1, 1)
PILOT_END = date(2025, 12, 31)          # 365-day, 12-month window
N_STORES = 22                            # selling stores
N_SKUS = 150                             # Electronics / Home Goods assortment
CATEGORIES = ("Electronics", "Home Goods")

# Southwest-region states (Dim_Store.State must be within the SW region)
SW_STATES = ("AZ", "NM", "NV", "TX", "CA", "UT")
STORE_SIZES = ("Small", "Medium", "Large")

# SCD Type 2 reclassification (Decision 4): one SKU moves Electronics -> Home Goods.
RECLASSIFIED_SKU = "SKU-1099"
RECLASS_DATE = date(2025, 7, 15)         # v2 effective start; v1 ends the day before

# Known-answer stockout injections (Decision 3 / BR-008b) -------------------
# Distribution Issue: this one store is out, but stock exists elsewhere in region.
DIST_ISSUE = {"store_id": "STR-005", "sku": "SKU-1010", "day": date(2025, 6, 10)}
# True Shortage: every location (all stores + DC) is out of this SKU that day.
TRUE_SHORTAGE = {"sku": "SKU-1020", "day": date(2025, 9, 5)}


def daterange(start, end):
    """Yield each date from start to end inclusive."""
    d = start
    while d <= end:
        yield d
        d += timedelta(days=1)


def date_key(d):
    """Surrogate Date_Key as a YYYYMMDD integer."""
    return d.year * 10000 + d.month * 100 + d.day


# ---------------------------------------------------------------------------
# Dimension builders
# ---------------------------------------------------------------------------
def build_dim_date():
    """Standard calendar dimension for the 12-month window."""
    rows = []
    for d in daterange(PILOT_START, PILOT_END):
        iso_year, iso_week, _ = d.isocalendar()
        rows.append({
            "Date_Key": date_key(d),
            "Full_Date": d.isoformat(),
            "Day_Name": d.strftime("%A"),
            "Day_Number": d.day,
            "Week_Number": iso_week,
            "Month": d.month,
            "Month_Name": d.strftime("%B"),
            "Quarter": (d.month - 1) // 3 + 1,
            "Year": d.year,
            "Weekend_Indicator": 1 if d.weekday() >= 5 else 0,
        })
    return rows


def build_dim_store(rng):
    """22 selling stores + 1 regional distribution center (23 locations)."""
    rows = []
    store_key = 1
    for i in range(1, N_STORES + 1):
        store_id = f"STR-{i:03d}"
        state = rng.choice(SW_STATES)
        rows.append({
            "Store_Key": store_key,
            "Store_ID": store_id,
            "Store_Name": f"NorthStar {state} #{i:02d}",
            "Location_Type": "Store",
            "Region": "Southwest",
            "State": state,
            "Store_Size": rng.choice(STORE_SIZES),
        })
        store_key += 1
    # The single regional DC — a row in Dim_Store (Decision: shared dimension),
    # included in pooling (BR-008b) but excluded from store-level in-stock rate.
    rows.append({
        "Store_Key": store_key,
        "Store_ID": "DC-001",
        "Store_Name": "NorthStar Southwest Regional DC",
        "Location_Type": "Distribution_Center",
        "Region": "Southwest",
        "State": "AZ",
        "Store_Size": "Large",
    })
    return rows


def build_dim_product(rng):
    """
    150 SKUs. Exactly one SKU (RECLASSIFIED_SKU) is SCD Type 2 on Category,
    producing two rows (two Product_Keys, one SKU) with non-overlapping
    effective-date ranges. Every other attribute on every SKU is static.

    Returns:
        rows          : list of Dim_Product dicts (151 rows total)
        version_index : {sku: [(product_key, start_date, end_date_or_None), ...]}
                        used to resolve the effective Product_Key at a given date.
        attr_by_sku   : {sku: {"Unit_Cost":.., "Retail_Price":..}} (static attrs)
    """
    rows = []
    version_index = {}
    attr_by_sku = {}
    product_key = 1

    for i in range(N_SKUS):
        sku = f"SKU-{1000 + i}"
        # Log-uniform price draw: a realistic assortment is mostly low-priced
        # items with a thin tail of expensive ones. A flat uniform(5,800) drew a
        # ~$400 mean cost, which made 2 categories out-earn a whole store's
        # all-category average vs. the company profile. Log-uniform [5,250] lands
        # ~20% of the parent's per-store revenue for Electronics + Home Goods.
        cost = round(math.exp(rng.uniform(math.log(5.0), math.log(250.0))), 2)
        retail = round(cost * rng.uniform(1.20, 2.20), 2)   # Retail_Price >= Cost
        product_name = f"NorthStar Product {1000 + i}"
        attr_by_sku[sku] = {"Unit_Cost": cost, "Retail_Price": retail,
                            "Product_Name": product_name}

        if sku == RECLASSIFIED_SKU:
            # Version 1 — Electronics, effective start of pilot .. day before reclass
            v1_key = product_key
            product_key += 1
            v1_end = RECLASS_DATE - timedelta(days=1)
            rows.append({
                "Product_Key": v1_key, "SKU": sku, "Product_Name": product_name,
                "Category": "Electronics",
                "Unit_Cost": cost, "Retail_Price": retail,
                "Effective_Start_Date": PILOT_START.isoformat(),
                "Effective_End_Date": v1_end.isoformat(),
                "Is_Current": 0,
            })
            # Version 2 — Home Goods, effective reclass date .. current
            v2_key = product_key
            product_key += 1
            rows.append({
                "Product_Key": v2_key, "SKU": sku, "Product_Name": product_name,
                "Category": "Home Goods",
                "Unit_Cost": cost, "Retail_Price": retail,
                "Effective_Start_Date": RECLASS_DATE.isoformat(),
                "Effective_End_Date": "",          # NULL = current/active version
                "Is_Current": 1,
            })
            version_index[sku] = [
                (v1_key, PILOT_START, v1_end),
                (v2_key, RECLASS_DATE, None),
            ]
        else:
            key = product_key
            product_key += 1
            category = CATEGORIES[0] if (i % 5 < 3) else CATEGORIES[1]  # ~60/40 split
            rows.append({
                "Product_Key": key, "SKU": sku, "Product_Name": product_name,
                "Category": category,
                "Unit_Cost": cost, "Retail_Price": retail,
                "Effective_Start_Date": PILOT_START.isoformat(),
                "Effective_End_Date": "",
                "Is_Current": 1,
            })
            version_index[sku] = [(key, PILOT_START, None)]

    return rows, version_index, attr_by_sku


def resolve_product_key(version_index, sku, d):
    """Return the Product_Key of the version effective on date d (SCD Type 2)."""
    for key, start, end in version_index[sku]:
        if d >= start and (end is None or d <= end):
            return key
    # Should never happen — every date in the window is covered by some version.
    raise ValueError(f"No effective Dim_Product version for {sku} on {d}")


# ---------------------------------------------------------------------------
# Fact generation
# ---------------------------------------------------------------------------
def seasonal_weekday_factor(d):
    """A plausible demand multiplier: weekend uplift + Nov/Dec holiday spike."""
    factor = 1.0
    if d.weekday() >= 5:            # Sat/Sun
        factor *= 1.35
    if d.month in (11, 12):        # holiday season
        factor *= 1.45
    elif d.month in (6, 7):        # mild summer bump
        factor *= 1.10
    return factor


def generate(out_dir, seed):
    rng = random.Random(seed)
    os.makedirs(out_dir, exist_ok=True)

    # --- Dimensions -------------------------------------------------------
    dim_date = build_dim_date()
    dim_store = build_dim_store(rng)
    dim_product, version_index, attr_by_sku = build_dim_product(rng)

    store_key_by_id = {r["Store_ID"]: r["Store_Key"] for r in dim_store}
    selling_store_ids = [r["Store_ID"] for r in dim_store
                         if r["Location_Type"] == "Store"]
    dc_id = next(r["Store_ID"] for r in dim_store
                 if r["Location_Type"] == "Distribution_Center")
    all_location_ids = selling_store_ids + [dc_id]
    sku_list = [f"SKU-{1000 + i}" for i in range(N_SKUS)]
    days = list(daterange(PILOT_START, PILOT_END))

    # Per (store, sku) demand profile: expected transactions/day so that the
    # yearly total lands near ~2 transactions/SKU/store/week (~104/yr) => ~343K.
    # The seasonal/weekend factors average ~1.20x over the year, so the base
    # daily probability is divided by that to keep the annual mean at ~2/week
    # (2/7 / 1.20 = ~0.237), landing Fact_Sales near the documented ~343,200.
    base_txn_prob = (2.0 / 7.0) / 1.20

    # --- Pass 1: generate daily units sold per (store, sku, day) ----------
    # units_sold[(store_id, sku, day_ordinal)] = units (only where a txn occurs)
    # We also keep the individual transactions to write Fact_Sales rows.
    units_sold = {}
    transactions = []          # (store_id, sku, day, qty, unit_price)

    for store_id in selling_store_ids:
        for sku in sku_list:
            unit_price = attr_by_sku[sku]["Retail_Price"]
            # slight per-store/sku popularity variance
            popularity = rng.uniform(0.6, 1.4)
            for d in days:
                p = base_txn_prob * popularity * seasonal_weekday_factor(d)
                p = min(p, 0.95)
                if rng.random() < p:
                    qty = rng.randint(1, 4)
                    units_sold[(store_id, sku, d.toordinal())] = qty
                    transactions.append((store_id, sku, d, qty, unit_price))

    # --- Pass 2: simulate daily inventory per (location, sku) -------------
    # Inventory decrements to reflect recorded sales (Data_Dictionary internal
    # consistency rule) and replenishes on a simple reorder-point policy. Where
    # a day's demand would exceed on-hand, the excess sale is trimmed so that
    # Quantity_On_Hand never goes negative and sales never exceed availability.
    #
    # We first compute inventory into an in-memory structure keyed by
    # (location_id, sku) -> {day_ordinal: qoh} for the location/SKU combos we
    # must be able to pool for the injected test cases and validation. To bound
    # memory across 1.26M rows we stream inventory rows to disk while simulating,
    # but we retain the small set of injected-case lookups explicitly.

    trimmed_sales = set()      # (store_id, sku, day_ordinal) sales removed

    # Base stock levels by store size (DC carries much more).
    size_by_store = {r["Store_ID"]: r["Store_Size"] for r in dim_store}
    base_level = {"Small": 40, "Medium": 70, "Large": 110}

    # ----- Generate a realistic POPULATION of stockout events -------------
    # Per Data_Generation_Pipeline_Design.md, a deliberate subset of store/SKU/day
    # combinations is generated as true stockouts (Quantity_On_Hand = 0) with a
    # documented mix of two kinds (BR-008b):
    #   * DISTRIBUTION-ISSUE episodes — a single store runs out for a short window
    #     while stock still exists elsewhere in the region (other stores + DC).
    #   * TRUE-SHORTAGE episodes — the SKU is scarce region-wide, so every location
    #     is out for a short window.
    # Distribution issues are made the clear majority (each true-shortage day zeroes
    # ~22 store events at once, so shortage episodes are kept few). This yields a
    # plausible split consistent with the pilot's founding hypothesis that stockouts
    # are usually a distribution/visibility problem, without hard-coding the result —
    # a different seed can shift the balance, and the classification is computed, not
    # assumed. The two fixed known-answer cases below are layered on top so KPI-P03
    # and validation always have a guaranteed, coordinate-known example of each.
    forced_zero = set()        # (location_id, sku, day_ordinal) forced to QOH = 0
    forced_positive = {}       # (location_id, sku, day_ordinal) -> minimum QOH floor
    n_dist_episodes = 0
    n_shortage_episodes = 0
    max_start = len(days) - 6  # leave room for episode duration

    # Distribution-issue episodes: most SKUs get a few, each at one random store.
    for sku in sku_list:
        n_epi = rng.choices([0, 1, 2, 3], weights=[0.15, 0.35, 0.32, 0.18])[0]
        for _ in range(n_epi):
            store_id = rng.choice(selling_store_ids)
            start = rng.randint(0, max_start)
            duration = rng.randint(1, 6)
            for off in range(duration):
                forced_zero.add((store_id, sku, days[start + off].toordinal()))
            n_dist_episodes += 1

    # True-shortage episodes: a small minority of SKUs go scarce region-wide.
    for sku in sku_list:
        if rng.random() < 0.05:
            start = rng.randint(0, max_start)
            duration = rng.randint(1, 3)
            for off in range(duration):
                do = days[start + off].toordinal()
                for loc in all_location_ids:
                    forced_zero.add((loc, sku, do))
            n_shortage_episodes += 1

    # ----- Fixed known-answer injections (guaranteed coordinates) ---------
    # Distribution Issue: only the one store is zero on that day.
    forced_zero.add((DIST_ISSUE["store_id"], DIST_ISSUE["sku"],
                     DIST_ISSUE["day"].toordinal()))
    # True Shortage: every location is zero on that day for that SKU.
    for loc in all_location_ids:
        forced_zero.add((loc, TRUE_SHORTAGE["sku"], TRUE_SHORTAGE["day"].toordinal()))
    # For the Distribution Issue case, guarantee at least one other location has
    # stock that same day (force the DC to a positive floor so pooling > 0 even
    # if every other store happened to be low).
    forced_positive[(dc_id, DIST_ISSUE["sku"],
                     DIST_ISSUE["day"].toordinal())] = 25

    inv_path = os.path.join(out_dir, "fact_inventory_snapshot.csv")
    inv_count = 0
    reorder_point = 8

    with open(inv_path, "w", newline="") as invf:
        inv_writer = csv.writer(invf)
        inv_writer.writerow(
            ["Snapshot_Key", "Date_Key", "Store_Key", "Product_Key",
             "Quantity_On_Hand"])

        for location_id in all_location_ids:
            is_dc = (location_id == dc_id)
            store_key = store_key_by_id[location_id]
            if is_dc:
                # DC starts high and is topped up generously; it does not sell.
                start_stock = 400
                reorder_qty = 400
            else:
                lvl = base_level[size_by_store[location_id]]
                start_stock = lvl
                reorder_qty = lvl

            for sku in sku_list:
                on_hand = start_stock
                for d in days:
                    do = d.toordinal()

                    # Replenishment arrives at start of day if we were low.
                    if on_hand <= reorder_point:
                        on_hand = min(on_hand + reorder_qty, reorder_qty * 2)

                    # Apply that location's sales for the day (stores only).
                    if not is_dc:
                        sold = units_sold.get((location_id, sku, do), 0)
                        if sold > 0:
                            if sold > on_hand:
                                # Trim the sale to available stock; keep both
                                # tables consistent and non-negative.
                                units_sold[(location_id, sku, do)] = on_hand
                                if on_hand == 0:
                                    trimmed_sales.add((location_id, sku, do))
                                on_hand = 0
                            else:
                                on_hand -= sold

                    # Apply known-answer injections (override the simulation).
                    if (location_id, sku, do) in forced_zero:
                        on_hand = 0
                        if not is_dc:
                            # no sale can occur while forced out of stock
                            if (location_id, sku, do) in units_sold:
                                trimmed_sales.add((location_id, sku, do))
                    fp = forced_positive.get((location_id, sku, do))
                    if fp is not None and on_hand < fp:
                        on_hand = fp

                    inv_count += 1
                    product_key = resolve_product_key(version_index, sku, d)
                    inv_writer.writerow(
                        [inv_count, date_key(d), store_key, product_key, on_hand])

    # --- Write Fact_Sales (dropping trimmed / forced-out sales) -----------
    sales_path = os.path.join(out_dir, "fact_sales.csv")
    sales_count = 0
    with open(sales_path, "w", newline="") as sf:
        sales_writer = csv.writer(sf)
        sales_writer.writerow(
            ["Sales_Key", "Date_Key", "Store_Key", "Product_Key",
             "Quantity_Sold", "Unit_Price", "Sales_Amount"])
        for (store_id, sku, d, qty, unit_price) in transactions:
            do = d.toordinal()
            if (store_id, sku, do) in trimmed_sales:
                continue
            # A trimmed-but-nonzero quantity is reflected via units_sold.
            eff_qty = units_sold.get((store_id, sku, do), qty)
            if eff_qty <= 0:
                continue
            sales_count += 1
            store_key = store_key_by_id[store_id]
            product_key = resolve_product_key(version_index, sku, d)
            sales_amount = round(eff_qty * unit_price, 2)
            sales_writer.writerow(
                [sales_count, date_key(d), store_key, product_key,
                 eff_qty, f"{unit_price:.2f}", f"{sales_amount:.2f}"])

    # --- Write dimensions --------------------------------------------------
    _write_csv(os.path.join(out_dir, "dim_date.csv"), dim_date,
               ["Date_Key", "Full_Date", "Day_Name", "Day_Number",
                "Week_Number", "Month", "Month_Name", "Quarter", "Year",
                "Weekend_Indicator"])
    _write_csv(os.path.join(out_dir, "dim_store.csv"), dim_store,
               ["Store_Key", "Store_ID", "Store_Name", "Location_Type",
                "Region", "State", "Store_Size"])
    _write_csv(os.path.join(out_dir, "dim_product.csv"), dim_product,
               ["Product_Key", "SKU", "Product_Name", "Category", "Unit_Cost",
                "Retail_Price", "Effective_Start_Date", "Effective_End_Date",
                "Is_Current"])

    # --- Record injected known-answer cases (for validation/reference) ----
    known = {
        "seed": seed,
        "scd2_reclassified_sku": {
            "sku": RECLASSIFIED_SKU,
            "v1_category": "Electronics",
            "v1_effective_start": PILOT_START.isoformat(),
            "v1_effective_end": (RECLASS_DATE - timedelta(days=1)).isoformat(),
            "v2_category": "Home Goods",
            "v2_effective_start": RECLASS_DATE.isoformat(),
            "v2_effective_end": None,
        },
        "distribution_issue_case": {
            "store_id": DIST_ISSUE["store_id"],
            "sku": DIST_ISSUE["sku"],
            "date": DIST_ISSUE["day"].isoformat(),
            "date_key": date_key(DIST_ISSUE["day"]),
            "store_key": store_key_by_id[DIST_ISSUE["store_id"]],
            "product_key": resolve_product_key(version_index, DIST_ISSUE["sku"],
                                               DIST_ISSUE["day"]),
            "expected_classification": "Distribution Issue",
        },
        "true_shortage_case": {
            "sku": TRUE_SHORTAGE["sku"],
            "date": TRUE_SHORTAGE["day"].isoformat(),
            "date_key": date_key(TRUE_SHORTAGE["day"]),
            "product_key": resolve_product_key(version_index, TRUE_SHORTAGE["sku"],
                                               TRUE_SHORTAGE["day"]),
            "expected_classification": "True Shortage",
        },
        "row_counts": {
            "dim_date": len(dim_date),
            "dim_store": len(dim_store),
            "dim_product": len(dim_product),
            "fact_sales": sales_count,
            "fact_inventory_snapshot": inv_count,
        },
        "stockout_population": {
            "distribution_issue_episodes": n_dist_episodes,
            "true_shortage_episodes": n_shortage_episodes,
            "note": "Plus the two fixed known-answer cases layered on top.",
        },
    }
    with open(os.path.join(out_dir, "_known_test_cases.json"), "w") as kf:
        json.dump(known, kf, indent=2)

    # --- Console summary ---------------------------------------------------
    print("Data generation complete (seed = %d)" % seed)
    print("  dim_date.csv                 : %8d rows" % len(dim_date))
    print("  dim_store.csv                : %8d rows (22 stores + 1 DC)"
          % len(dim_store))
    print("  dim_product.csv              : %8d rows (150 SKUs + 1 SCD2 version)"
          % len(dim_product))
    print("  fact_sales.csv               : %8d rows" % sales_count)
    print("  fact_inventory_snapshot.csv  : %8d rows" % inv_count)
    print("  stockout episodes generated  : %d distribution-issue, %d true-shortage "
          "(+2 fixed known-answer cases)" % (n_dist_episodes, n_shortage_episodes))
    print("  known-answer cases           : Distribution Issue=%s/%s @ %s, "
          "True Shortage=%s @ %s, SCD2 SKU=%s"
          % (DIST_ISSUE["store_id"], DIST_ISSUE["sku"], DIST_ISSUE["day"],
             TRUE_SHORTAGE["sku"], TRUE_SHORTAGE["day"], RECLASSIFIED_SKU))
    return known


def _write_csv(path, rows, header):
    with open(path, "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=header)
        writer.writeheader()
        writer.writerows(rows)


def main():
    parser = argparse.ArgumentParser(description="Generate NorthStar pilot data.")
    default_out = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                               "..", "data", "staging")
    parser.add_argument("--out-dir", default=default_out,
                        help="Directory for the generated CSV staging files.")
    parser.add_argument("--seed", type=int, default=42,
                        help="Random seed for deterministic generation.")
    args = parser.parse_args()
    generate(os.path.normpath(args.out_dir), args.seed)


if __name__ == "__main__":
    main()
