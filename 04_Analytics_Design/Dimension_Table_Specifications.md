# DIMENSION TABLE SPECIFICATIONS

Version: 1.0

Project:
NorthStar Retail Group
Inventory Visibility Pilot — Electronics & Home Goods, Southwest Region

Status: Approved for Development
Scope Note: Covers the pilot's three dimensions only (Dim_Date, Dim_Product, Dim_Store). Dim_Customer, Dim_Employee, Dim_Promotion excluded per established pilot scope (no CRM/HR/promotions data). Dim_Product implements a deliberate, narrowly-scoped SCD Type 2 exercise on the Category attribute — the only dimension change modeled in this pilot; all other attributes across all three dimensions are treated as static for the 12-month window.

---

# Design Standards

- Surrogate primary keys for all dimensions
- Descriptive, business-friendly attributes (no raw codes visible to report users)
- One dimension (Dim_Product) intentionally implements SCD Type 2 on a single attribute (Category) as a scoped practice exercise — documented explicitly below, not silently applied everywhere

---

# Dimension: Dim_Date

**Business Purpose:** Standard calendar reference for all time-based analysis.

**Primary Key:** Date_Key (surrogate, e.g., YYYYMMDD integer)

**Business Key:** Full_Date

**Attributes:** Full_Date, Day_Name, Day_Number, Week_Number, Month, Month_Name, Quarter, Year, Weekend_Indicator

**Trimmed from enterprise version:** Fiscal_Month/Fiscal_Quarter/Fiscal_Year, Holiday_Indicator — not required for a 12-month trend pilot without fiscal-calendar-specific or holiday-specific reporting requirements.

**Change Handling:** Static by nature — dates don't change. No SCD logic applicable or needed.

**Business Questions Supported:** In-stock rate trend by month/week; day-of-week sales pattern (useful context for KPI-P02's baseline sales rate calculation).

---

# Dimension: Dim_Store

**Business Purpose:** Describes each pilot store and the regional distribution center.

**Primary Key:** Store_Key (surrogate)

**Business Key:** Store_ID

**Attributes:** Store_Name, Location_Type ("Store" or "Distribution_Center"), Region (fixed: "Southwest"), State, Store_Size

**Trimmed from enterprise version:** ZIP_Code, District, Store_Manager, Square_Footage (kept as simplified Store_Size instead), Opening_Date, Store_Type — not needed at pilot scale.

**Change Handling:** Treated as static for the pilot's 12-month window (documented assumption in Star_Schema.md: no store openings/closures modeled). This is a deliberate scope decision, not an oversight — if asked, the answer is "the pilot window is short enough and the store list stable enough that dimension history tracking wasn't a priority; SCD Type 2 would be the correct tool if it were needed" (see Dim_Product below for a worked example of that approach).

---

# Dimension: Dim_Product (SCD Type 2 Applied to Category)

**Business Purpose:** Product reference data for the Electronics/Home Goods pilot assortment.

**Primary Key:** Product_Key (surrogate — note: this is *not* the same as SKU, which is the natural/business key; this distinction is what makes SCD Type 2 possible)

**Business Key:** SKU

**Attributes:** Product_Name, Category, Unit_Cost, Retail_Price

**Trimmed from enterprise version:** Brand, Subcategory, Department, Supplier, Package_Size, Launch_Date, Discontinued_Date, Status.

### Why Category Gets SCD Type 2 Treatment (and Nothing Else Does)

A product's Category can plausibly be reclassified mid-year in a real retail business — e.g., a smart home hub initially filed under "Electronics" might get reclassified to "Home Goods" as NorthStar's merchandising team refines category definitions. If we simply overwrote the Category field when this happens, any historical stockout analysis run *after* the change would incorrectly show that product's earlier stockouts under its *new* category — silently corrupting the category-level rollups (e.g., "Electronics in-stock rate" for an earlier month would be wrong if a product later reclassified out of Electronics gets excluded from that historical calculation).

**Every other attribute in every other dimension is treated as static in this pilot** (per the scope decisions above) — this is the one deliberate exception, done specifically to practice and demonstrate the technique correctly, not because the pilot's business scenario strictly demanded it everywhere.

### SCD Type 2 Structure for Dim_Product

Instead of one row per SKU, Dim_Product allows **multiple rows per SKU** when Category changes, using effective-dating:

| Column | Purpose |
|---|---|
| Product_Key | Surrogate key — unique per *version* of a product record, not per SKU |
| SKU | Natural/business key — same value across all versions of the same product |
| Product_Name | Descriptive attribute |
| Category | The attribute being tracked historically |
| Unit_Cost, Retail_Price | Other attributes (treated as static in this pilot — not SCD-tracked, to keep the exercise scoped) |
| Effective_Start_Date | Date this version of the record became true |
| Effective_End_Date | Date this version stopped being true (NULL = current/active version) |
| Is_Current | Boolean flag — TRUE for the currently active version, FALSE for historical versions |

**Worked example:**

| Product_Key | SKU | Category | Effective_Start_Date | Effective_End_Date | Is_Current |
|---|---|---|---|---|---|
| 1001 | SKU-4471 | Electronics | 2025-01-01 | 2025-07-14 | FALSE |
| 1002 | SKU-4471 | Home Goods | 2025-07-15 | NULL | TRUE |

**How Fact_Sales and Fact_Inventory_Snapshot join to this correctly:** Both fact tables store `Product_Key` (the surrogate, version-specific key), not `SKU` directly. When a fact row is generated, it's joined to whichever `Product_Key` was `Is_Current = TRUE` (or effective) *on that transaction/snapshot date* — not simply the latest one. This is what preserves correct historical category rollups: a January sale of SKU-4471 correctly joins to Product_Key 1001 (Electronics), even after the reclassification happens in July.

**Business Questions This Enables:** "What was our Electronics in-stock rate in Q1?" returns a historically correct answer even after a mid-year category change — this is precisely the kind of accuracy issue that a naive (Type 1, overwrite-in-place) dimension would get wrong.

---

# Relationship Standards

- Dimensions connect to both fact tables via surrogate keys (Date_Key, Store_Key, Product_Key), one-to-many, single-direction cross-filter.
- Dimensions do not relate directly to each other in this model.
- Dim_Product's SCD Type 2 structure means a single SKU may correspond to multiple Product_Key values over time — fact table joins must resolve to the *effective* Product_Key for the transaction/snapshot date, not simply "the latest" one.

---

# Data Quality Rules

- Dim_Date, Dim_Store: one active row per business key (Full_Date, Store_ID) — no SCD logic, straightforward uniqueness.
- Dim_Product: multiple rows per SKU are *expected and correct* if a Category change occurred — but Effective_Start_Date/Effective_End_Date ranges must never overlap for the same SKU, and exactly one row per SKU must have `Is_Current = TRUE` at any time.

---

# Refresh Strategy

Static load for this pilot (synthetic data generated once for the 12-month window) — no live daily refresh, consistent with the Fact Table Specification's refresh strategy.

---

# Definition of Done

This specification is complete when Dim_Date and Dim_Store are implemented as simple static tables, and Dim_Product correctly implements SCD Type 2 on Category — verifiable by confirming that a query for "Electronics in-stock rate, January" returns results based on January's category assignment, even if that same product was reclassified later in the year.
