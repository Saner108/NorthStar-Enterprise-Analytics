# KPI CATALOG

Version: 1.0

Project:
NorthStar Retail Group
Inventory Visibility Pilot — Electronics & Home Goods, Southwest Region

Status: Approved
Scope Note: Trimmed to KPIs supportable by the pilot's three in-scope data sources (POS, WMS, Product Master) and consistent with the Business Rules Catalog. KPIs requiring ERP/CRM/fulfillment data (Inventory Turnover, Inventory Accuracy, Customer Retention, Order Fulfillment Time, Dashboard Adoption) are excluded — not because they lack value, but because this pilot has no data source to support them honestly. One KPI (Stockout Rate) has been redefined from the enterprise version to fix a measurement flaw — see note below.

---

# Purpose

Defines every KPI used in this pilot's analysis and dashboard. Every KPI here must trace to a Business Rule (Business_Rules_Catalog.md) and a Functional Requirement (Business_Requirements_Document.md) — no KPI exists here "because the template listed it."

---

# KPI-P01 — In-Stock Rate

**Business Purpose:** Headline, easy-to-scan measure of store-level inventory health.

**Business Question:** What percentage of a store's Electronics/Home Goods assortment is currently in stock?

**Formula:**
```
In-Stock Rate (store, day) = 
  (Count of SKUs where Quantity_On_Hand > 0) 
  ÷ (Total SKUs in store's assortment) × 100
```

**Data Source:** Inventory_Snapshot

**Business Rule:** BR-008 (Stockout definition)

**Business Owner (Roleplay):** VP Supply Chain

**Target:** No fabricated target at Charter stage — baseline will be established from pilot data first (see Charter Success Metrics table)

**Recommended Visualization:** KPI card + trend line by store over the 12-month window; heat map by store for quick scanning

**Executive Interpretation:** A simple, intuitive top-line number. Good for spotting which stores need attention at a glance, but does not by itself indicate how *costly* those stockouts are — pair with KPI-P02.

**Known Limitation:** Treats a stockout on a best-seller the same as a stockout on a rarely-purchased item. This is intentional — it's the "simple/headline" metric, not the prioritization metric.

---

# KPI-P02 — Estimated Lost Margin from Stockouts

**Business Purpose:** The diagnostic/prioritization companion to KPI-P01 — answers "which stockouts actually matter."

**Business Question:** How much estimated gross margin is being lost due to stockouts, and where?

**Formula:**
```
Estimated Lost Units (store, SKU, stockout period) = 
  Average daily sales rate for that store/SKU on days Quantity_On_Hand > 0 
  × number of stockout days

Estimated Lost Margin = Estimated Lost Units × (Retail_Price − Cost)
```

**Data Source:** Sales_Transactions (for baseline sales rate) + Inventory_Snapshot (for stockout days) + Product_Master (for margin)

**Business Rule:** BR-008a (Stockout Impact Estimation)

**Business Owner (Roleplay):** VP Supply Chain / Finance (roleplay)

**Recommended Visualization:** Ranked bar chart — top stockout offenders by estimated lost margin, by store and by SKU

**Executive Interpretation:** This is the number that should actually drive prioritization decisions — not raw stockout count.

**Known Limitation:** This is an *estimate* based on historical baseline sales rate; it assumes customers would have bought at the same rate had the item been in stock, which may not hold if demand also shifted (e.g., a competitor promotion pulled demand away independent of the stockout). This should be stated explicitly when presenting findings — a good analyst names their model's assumptions, not just its output.

---

# KPI-P03 — Distribution vs. Shortage Classification

**Business Purpose:** Answers the pilot's core hypothesis question directly.

**Business Question:** For each detected stockout, is inventory available elsewhere in the region (distribution problem) or is it genuinely scarce company-wide within the pilot scope (shortage)?

**Formula:**
```
Pooled Regional Inventory (SKU, date) = 
  Sum(Quantity_On_Hand) across all other pilot stores + regional DC, same SKU, same date

Classification = "Distribution Issue" if Pooled Regional Inventory > 0
Classification = "True Shortage" if Pooled Regional Inventory = 0
```

**Data Source:** Inventory_Snapshot

**Business Rule:** BR-008b

**Recommended Visualization:** Simple split (e.g., donut or stacked bar) showing % of stockout events classified each way — this single chart is likely the pilot's single most important finding.

**Executive Interpretation:** If the majority of stockouts classify as "Distribution Issue," it validates the pilot's founding hypothesis and supports investing in a future optimization/rebalancing phase. If most classify as "True Shortage," it redirects the recommendation toward procurement/replenishment instead — an honest pilot has to be willing to find this result too, not just the one that confirms the original hypothesis.

---

# KPI-P04 — Revenue (Pilot Scope)

**Business Purpose:** Basic context metric — not the pilot's focus, but needed as a baseline for interpreting the other KPIs (e.g., "lost margin is $X, which is Y% of total pilot-region revenue").

**Formula:** `Sum(Sales_Amount)` for in-scope stores/category/window

**Business Rule:** BR-001, BR-002, BR-003

**Data Source:** Sales_Transactions

**Recommended Visualization:** Simple trend line, used mainly as denominator context for KPI-P02.

---

# KPI-P05 — Gross Margin % (Product-Level)

**Business Purpose:** Supports KPI-P02's margin-weighting; also useful on its own to show which SKUs are inherently higher-value.

**Formula:** `(Retail_Price − Cost) ÷ Retail_Price × 100`

**Business Rule:** BR-014, BR-015

**Data Source:** Product_Master

**Recommended Visualization:** Not typically dashboard-featured on its own — used as an input to KPI-P02's calculation and available as a filter/sort dimension.

---

# KPIs Explicitly Excluded from Pilot Scope

| Enterprise KPI | Why Excluded |
|---|---|
| Inventory Turnover | Requires Cost of Goods Sold from ERP — not in pilot data sources |
| Inventory Accuracy | Requires physical inventory count/audit data to compare against system records — not modeled in this pilot |
| Customer Retention Rate | Requires CRM/customer-level data — explicitly out of scope |
| Order Fulfillment Time | Requires order/logistics timestamps beyond this pilot's WMS snapshot grain |
| Dashboard Adoption Rate | Requires live usage tracking on a deployed dashboard — not applicable to a portfolio project with no live user base |

**Note on Stockout Rate (redefined, not excluded):** The enterprise version defined Stockout Rate as `Stockout Events ÷ Total Product Demand`. This was not carried forward as written because "total product demand" is not reliably measurable when a stockout is actively suppressing that same demand — attempting to calculate it would require assumptions doing most of the work anyway. This pilot instead splits that single flawed KPI into three honest, separately measurable ones: KPI-P01 (simple in-stock rate), KPI-P02 (estimated cost), and KPI-P03 (root cause classification).

---

# KPI Quality Checklist (Applied to Every KPI Above)

- [x] Business definition is clear
- [x] Calculation is documented with exact formula
- [x] Traces to a specific Business Rule
- [x] Traces to a specific Functional Requirement
- [x] Required data exists within the three in-scope sources
- [x] Known limitations are stated, not hidden
- [x] No fabricated numeric target without baseline data to support it

---

# Definition of Done

This KPI Catalog is complete when every visual in the Phase 4 Power BI dashboard maps to exactly one KPI listed here, and every KPI here can be explained — formula, data source, business rule, and known limitation — without notes.
