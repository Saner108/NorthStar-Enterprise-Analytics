# Inventory Visibility Pilot — Findings

**NorthStar Retail Group · Southwest Region · Electronics & Home Goods · In-Store Channel**
Analysis period: full 12-month window (synthetic pilot dataset) · Prepared for: VP of Operations (roleplay) · Analyst: Cesar Sanchez

---

## Executive summary

Across the 22 Southwest pilot stores, average product availability sits at **92.5% in-stock** — but that regional average hides the real story. Store-level performance ranges from **87.9%** at the worst location to **96.9%** at the best, a **9-percentage-point spread** that means some stores are failing customers roughly three times as often as others while carrying the same assortment.

The pilot was built to test one hypothesis: that NorthStar's stockouts are a **distribution and visibility** problem — inventory sitting in the wrong place — rather than a true regional shortage. The data supports it decisively. **79.7% of all stockout events were classified as Distribution Issues** (the out-of-stock SKU still had sellable inventory at other pilot stores or the regional DC on that same day), versus **20.3% True Shortages** (the SKU was scarce region-wide). The pattern sharpens at the stores that need help most: at the five worst stores, **85–87%** of stockouts were distribution-driven.

The estimated cost of these stockouts is **~$2.75M in lost gross margin**, about **3.4% of the region's ~$81.1M revenue**, and it is concentrated — the five worst stores account for roughly **one-third** of it. Because most of that loss sits behind inventory that already exists elsewhere in the region, it is addressable by **redistribution**, not additional purchasing.

---

## Finding 1 — Availability is below benchmark and, more importantly, uneven

Regional in-stock rate is **92.5%**, beneath the 95–97% range typical of well-run retail. The headline number matters less than the dispersion behind it:

| Rank | Store | In-Stock % | Est. Lost Margin | Stockout events | % Distribution |
|---|---|---|---|---|---|
| 1 | NorthStar NM #04 | 87.9% | $187,264 | 6,605 | 87% |
| 2 | NorthStar AZ #09 | 88.9% | $181,727 | 6,099 | 86% |
| 3 | NorthStar TX #20 | 90.0% | $173,600 | 5,474 | 85% |
| 4 | NorthStar UT #15 | 89.7% | $171,470 | 5,660 | 85% |
| 5 | NorthStar AZ #10 | 89.2% | $170,327 | 5,909 | 86% |
| … | *(12 mid-pack stores omitted)* | | | | |
| 21 | NorthStar NM #19 | 96.5% | $64,007 | 1,916 | 56% |
| 22 | NorthStar UT #06 | 96.9% | $49,576 | 1,681 | 50% |

The worst store loses nearly **4x** the margin of the best. This dispersion is the actionable signal: a single regional average would have hidden it, and it tells operations exactly where to look first.

## Finding 2 — The problem is distribution, not supply (hypothesis confirmed)

Of ~90,400 store stockout events, **79.7% were Distribution Issues** and **20.3% True Shortages**. The distinction is the difference between two completely different fixes:

- **Distribution Issue** → the region held the stock; it was in the wrong store or stuck at the DC. Fix: rebalancing, transfers, allocation logic.
- **True Shortage** → the region was genuinely out. Fix: procurement and ordering.

Four out of five stockouts point at the first fix, and the concentration is strongest exactly where it helps most: the five worst-performing stores are **85–87% distribution-driven**, while the best store is only **50%**. Read together, Findings 1 and 2 say the same thing — the stores with the worst availability are not short of regional supply; they are on the losing end of how existing supply is allocated.

*Note on interpretation:* this split is **computed from the data, not assumed** — the classification rule (BR-008b) pools each stocked-out SKU's inventory across all other pilot locations on the same day and labels it a Distribution Issue only when a genuine redistributable surplus (≥3 units) existed elsewhere. A different dataset could return a different split; this one confirms the hypothesis.

## Finding 3 — Lost margin is material and concentrated

Estimated lost gross margin totals **~$2.75M (3.4% of revenue)**. It skews toward Electronics (**$1.68M**) over Home Goods (**$1.07M**), consistent with Electronics' higher unit margins. Critically, it is not spread evenly: the **top five stores carry ~32%** of the total, so a targeted intervention at a handful of locations reaches a disproportionate share of the opportunity. This is a prioritization result, not just a measurement — it tells the VP where a fix returns the most margin per unit of effort.

## Finding 4 — Peak season concentrates the risk

Monthly revenue runs $5.6M–$6.9M for most of the year and then jumps to **~$9.1M in both November and December** — a ~35% holiday lift. Availability problems are most expensive precisely when volume peaks, so the distribution gaps identified above carry outsized cost in Q4. Any redistribution improvement is worth sequencing ahead of the holiday window.

---

## What this means

The evidence points to a specific, bounded action: **prioritize inventory redistribution to the lowest-availability stores**, starting with the five worst, where availability is weakest, stockouts are most numerous, and the stock to fix them most reliably exists elsewhere in the region. This is an allocation and visibility problem, and it is addressable without increasing total regional inventory.

**On targets:** this pilot deliberately does **not** claim a specific improvement figure (e.g., "recover X% of the $2.75M"). No pre-intervention operational baseline exists to justify one, and committing to an invented number would be less defensible, not more. The honest statement is: the addressable opportunity is bounded above by the **~$2.19M** of lost margin currently classified as distribution-driven (79.7% of $2.75M), and a target should be set only after a baseline measurement period. *Baseline pending.*

---

## Method & caveats (for the technical reader)

- **Data is synthetic.** No live NorthStar source systems exist; the dataset was generated by a one-time, deterministic pipeline (generate → CSV staging → validate → load dimensions, then facts) and is not a production ETL feed. Figures demonstrate the analytical method, not real company performance.
- **Two fact tables, two grains.** `Fact_Sales` (one row per SKU per transaction) supplies the baseline sales rates behind the lost-margin estimate; `Fact_Inventory_Snapshot` (one row per location per SKU per day) supplies availability and the pooled-inventory classification. They answer different questions and are not merged.
- **Stockout logic is three separate rules.** Detection (`Quantity_On_Hand = 0`), impact estimation (baseline in-stock sales rate × stockout days × unit margin), and root-cause classification (same-day pooled inventory across other locations) are computed independently — a stockout is detected without any demand assumption, then separately costed, then separately classified.
- **Lost margin is an estimate.** It projects each store/SKU's average daily sales rate on in-stock days across its stockout days; it is directional, not booked.
- **One dimension is version-tracked.** A single SKU (SKU-1099) was reclassified Electronics → Home Goods mid-year and is modeled with SCD Type 2. Facts join to the category version effective on each row's date; the reporting layer rolls the two versions back up to one line for readability (detail in `vw_ProductReclassification`). This is a scoped practice exercise and is orthogonal to the availability findings above.
- **Classification threshold** for "redistributable surplus" is set at ≥3 units and is a documented, adjustable assumption; the per-stockout view exposes the raw pooled quantity so borderline cases can be re-examined.
- **Validation:** the build passes 17 automated integrity checks (row counts, grain uniqueness, referential integrity, SCD2 correctness, and known-answer classification cases); the validation totals reconcile exactly with the reported KPI-P03 totals.
