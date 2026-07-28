# FACT TABLE SPECIFICATION

Version: 1.0

Project:
NorthStar Retail Group
Inventory Visibility Pilot — Electronics & Home Goods, Southwest Region

Status: Approved for Development
Scope Note: Covers both pilot fact tables (Fact_Sales, Fact_Inventory_Snapshot). Volume, performance, and refresh assumptions are recalculated for actual pilot scale — not carried over from enterprise-scale assumptions (180M rows/year, 7-year retention, incremental nightly loads), which are appropriate for NorthStar's full 250-store enterprise but would be a significant over-engineering for a 22-store, single-category, 12-month pilot.

---

# Fact_Sales

**Business Event:** Customer purchases a product in a pilot store.

**Grain:** One row = one SKU sold within one completed transaction, at one pilot store, on one date.

**Primary Key:** Sales_Key (surrogate)

**Foreign Keys:** Date_Key → Dim_Date, Store_Key → Dim_Store, Product_Key → Dim_Product

**Measures:**

| Measure | Definition | Aggregation | Business Rule |
|---|---|---|---|
| Quantity_Sold | Units sold | SUM | Must be > 0 (BR-002 context) |
| Unit_Price | Price per unit at sale | N/A (not additive — use AVERAGE if aggregated) | Must be > $0.00 |
| Sales_Amount | Quantity_Sold × Unit_Price | SUM | BR-002 |

**Explicitly excluded (present in enterprise version, not needed for pilot):** Discount_Amount, Cost_of_Goods_Sold (transaction-level — margin instead calculated via Dim_Product per KPI-P05), Tax_Amount.

---

# Fact_Inventory_Snapshot

**Business Event:** Daily recorded inventory state — not a transactional event, a periodic state capture.

**Grain:** One row = one location (store or DC) × one SKU × one day.

**Primary Key:** Composite (Date_Key, Store_Key, Product_Key) or surrogate Snapshot_Key.

**Foreign Keys:** Date_Key → Dim_Date, Store_Key → Dim_Store (includes DC), Product_Key → Dim_Product

**Measures:**

| Measure | Definition | Aggregation | Business Rule |
|---|---|---|---|
| Quantity_On_Hand | Units physically present at this location on this date | SUM (across locations, for pooling) / AVERAGE (for trend) depending on question | BR-007, must be ≥ 0 |

**Note on aggregation:** Unlike Fact_Sales, Quantity_On_Hand should generally **not** simply be summed across dates (summing a store's daily inventory across a year produces a meaningless number). It's summed across *locations* for a given date (BR-008b pooling) or viewed as a trend/snapshot per date — the correct aggregation depends on the business question, which is why this is flagged explicitly rather than left ambiguous.

---

# Data Quality Rules (Both Fact Tables)

- Primary keys must be unique (no duplicate Sales_Key; no duplicate Date/Store/Product combination in Fact_Inventory_Snapshot)
- All foreign keys must resolve to an existing dimension record — no orphaned Store_Key or Product_Key
- No future-dated records
- Fact_Sales: Quantity_Sold and Sales_Amount cannot be negative (no returns modeled in this pilot — see BRD scope)
- Fact_Inventory_Snapshot: Quantity_On_Hand cannot be negative

---

# Refresh Strategy (Pilot-Appropriate)

This pilot uses **synthetic, generated data loaded once** for the 12-month analysis window — there is no live production source system to refresh from, so "refresh frequency" in the enterprise sense (daily 2 AM incremental loads) does not apply.

**If this pilot were extended to a live/ongoing proof-of-concept** (not currently in scope, but worth noting as a documented forward-looking consideration): a daily batch load would be appropriate given the actual data volume — no need for the enterprise's real-time/near-real-time infrastructure at this scale.

---

# Expected Volume (Calculated for Pilot Scale, Not Assumed)

Rather than carrying over enterprise-scale figures (180 million rows/year), volume is calculated directly from the pilot's actual scope:

**Assumptions:**
- ~22 pilot stores + 1 DC = 23 locations
- ~150 SKUs in the Electronics/Home Goods pilot assortment
- 365-day analysis window
- Average ~2 transactions per SKU per store per week (a reasonable estimate for mid-frequency, high-ticket goods — lower frequency than grocery, higher than furniture)

**Fact_Inventory_Snapshot:** 23 locations × 150 SKUs × 365 days = **~1,259,750 rows**

**Fact_Sales:** 22 stores × 150 SKUs × ~2 transactions/week × 52 weeks ≈ **~343,200 rows**

**Why this matters:** Both figures are well within what any free-tier relational database (SQLite, Postgres, Azure SQL free tier) handles trivially — no partitioning, indexing strategy, or incremental-load architecture is needed at this scale. Building enterprise-grade performance infrastructure for ~1.6 million total rows would be over-engineering, not rigor. A basic primary key index and the foreign key relationships already documented are sufficient.

---

# Performance Considerations (Right-Sized)

- Standard primary key constraints are sufficient — no custom partitioning needed at ~1.3M rows.
- Foreign key indexes are good practice regardless of scale and cost nothing to include.
- No compression or retention-tier strategy needed for a single 12-month analysis window with no ongoing accumulation.

---

# Validation Checklist Before Loading Data

- [ ] Primary key uniqueness confirmed in both fact tables
- [ ] All foreign keys resolve to existing Dim_Store / Dim_Product / Dim_Date records
- [ ] No negative Quantity_Sold, Sales_Amount, or Quantity_On_Hand
- [ ] No future-dated records
- [ ] Row counts roughly match the calculated expected volume above (a large deviation signals a generation script bug, not necessarily a data quality issue in the traditional sense)

---

# Dependencies

Both fact tables depend on: Dim_Date, Dim_Store, Dim_Product (Star_Schema.md), Business_Rules_Catalog.md, Data_Dictionary.md, KPI_Catalog.md — all of which must remain consistent with this specification.

---

# Reporting Impact

Supports all five pilot KPIs (KPI-P01 through KPI-P05) and the single Power BI dashboard planned for this pilot — not the six enterprise dashboards listed in the original specification (Finance, Operations, Customer Analytics, etc.), which require data sources this pilot doesn't have.

---

# Definition of Done

This specification is complete when both fact tables' grain, measures, and business rules are documented clearly enough that the actual SQL `CREATE TABLE` statements (Phase 4) can be written directly from this document without further design decisions needed.
