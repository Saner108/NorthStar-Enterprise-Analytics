# PILOT DATA MODEL (STAR SCHEMA SPECIFICATION)

Version: 1.0

Project:
NorthStar Retail Group
Inventory Visibility Pilot — Electronics & Home Goods, Southwest Region

Status: Approved for Design
Scope Note: This is a significant structural departure from the enterprise ERD, not just a trim. The enterprise version treats inventory as a "future expansion" fact table — but Fact_Inventory is the single most important table in this pilot, since KPI-P01, P02, and P03 all depend on it. Building from the enterprise ERD as-written would have produced a schema unable to answer this pilot's core business question.

---

# Design Principle: Two Fact Tables, Not One

Unlike the enterprise model's single `Fact_Sales` table, this pilot requires **two fact tables at two different grains**:

- **Fact_Sales** — grain: one row per SKU sold per transaction (event-based, matches enterprise pattern)
- **Fact_Inventory_Snapshot** — grain: one row per store/SKU/day (daily state, not event-based — per the earlier documented trade-off decision)

These cannot be merged into one fact table because they answer fundamentally different questions at fundamentally different grains: Fact_Sales tells you what *happened* (a transaction), Fact_Inventory_Snapshot tells you what *was true* at a point in time (a state). Forcing them together would either lose the daily inventory granularity or artificially inflate the sales table with redundant daily rows.

---

# Fact Table 1: Fact_Sales

**Business Purpose:** Records completed in-store sales for the pilot's stores/category.

**Grain:** One row per SKU per transaction.

**Primary Key:** Sales_Key (surrogate)

**Foreign Keys:** Date_Key, Store_Key, Product_Key

**Measures:**
- Quantity_Sold
- Unit_Price
- Sales_Amount (derived: Quantity_Sold × Unit_Price)

**Explicitly excluded from enterprise version's Fact_Sales:** Customer_Key, Employee_Key, Promotion_Key (no CRM/HR/promotions data), Discount_Amount, Cost_of_Goods_Sold at transaction level (margin is calculated via Dim_Product instead — see KPI-P05), Tax_Amount (not modeled in pilot).

---

# Fact Table 2: Fact_Inventory_Snapshot

**Business Purpose:** The pilot's core table — daily inventory state by location and SKU. Supports KPI-P01, P02, and P03 directly.

**Grain:** One row per location (store or DC) per SKU per day.

**Primary Key:** Composite of Date_Key + Store_Key + Product_Key (or a surrogate Snapshot_Key)

**Foreign Keys:** Date_Key, Store_Key (includes the regional DC as a special "location"), Product_Key

**Measures:**
- Quantity_On_Hand

**Design note:** This table does not exist in the enterprise ERD (listed only as a "future expansion" item, `Fact_Inventory`). It is promoted to a primary fact table here because the pilot's entire business question — is this a distribution problem or a shortage — cannot be answered without daily, location-level inventory state.

---

# Dimension Tables (Pilot Scope)

## Dim_Date

**Purpose:** Standard calendar dimension, unchanged in principle from enterprise version — date logic doesn't need to shrink just because the pilot is smaller.

**Fields:** Date_Key, Full_Date, Day, Week, Month, Quarter, Year, Weekend_Indicator

**Trimmed from enterprise version:** Fiscal_Month/Fiscal_Quarter/Fiscal_Year and Holiday_Indicator omitted — not needed for a 12-month trend pilot without fiscal-calendar-specific reporting requirements. Can be added later if genuinely needed.

---

## Dim_Store

**Purpose:** Describes pilot stores and the regional DC.

**Fields:** Store_Key, Store_ID, Store_Name, Location_Type ("Store" or "Distribution_Center"), Region (fixed: "Southwest"), State, Store_Size

**Trimmed from enterprise version:** Store_Manager (name-level detail unnecessary), Opening_Date, District (single-region pilot doesn't need district-level grouping), Store_Type (all pilot locations are same general format).

**Important design note:** The regional DC is included as a row in Dim_Store (with Location_Type = "Distribution_Center") rather than as a separate dimension. This is a deliberate simplification — it lets Fact_Inventory_Snapshot reference the DC through the same foreign key structure as stores, which is exactly what BR-008b (pooled inventory comparison) needs: summing Quantity_On_Hand across stores *and* the DC using one consistent join.

---

## Dim_Product

**Purpose:** Product attributes for the pilot category.

**Fields:** Product_Key, SKU, Product_Name, Category (fixed: "Electronics" or "Home Goods"), Unit_Cost, Retail_Price

**Trimmed from enterprise version:** Brand, Subcategory, Department, Supplier, Status — not needed at this pilot's scale (single category, no supplier performance analysis, no discontinued-product logic).

---

# Dimensions Explicitly Excluded from the Pilot

| Enterprise Dimension | Why Excluded |
|---|---|
| Dim_Customer | No CRM data in scope; no customer-level analysis in this pilot |
| Dim_Employee | No HR data in scope; no sales-attribution-by-employee analysis |
| Dim_Promotion | No promotions/discount data modeled in this pilot |

---

# Star Schema Diagram (Pilot Version)

```
                    Dim_Date
                    /      \
                   /        \
          Fact_Sales    Fact_Inventory_Snapshot
                   \        /
                    \      /
                  Dim_Store
                        |
                  Dim_Product
```

Both fact tables connect to the same three dimensions (Dim_Date, Dim_Store, Dim_Product) — this is what's sometimes called a "shared dimension" or "conformed dimension" design, and it's what allows Power BI to let a user filter by store or date and see both sales and inventory update together, even though the two facts are at different grains.

---

# Relationships

| From | To | Type | Cross-Filter Direction |
|---|---|---|---|
| Fact_Sales | Dim_Date | Many-to-One | Single |
| Fact_Sales | Dim_Store | Many-to-One | Single |
| Fact_Sales | Dim_Product | Many-to-One | Single |
| Fact_Inventory_Snapshot | Dim_Date | Many-to-One | Single |
| Fact_Inventory_Snapshot | Dim_Store | Many-to-One | Single |
| Fact_Inventory_Snapshot | Dim_Product | Many-to-One | Single |

---

# Modeling Standards Applied

- Surrogate keys used for all dimension primary keys (Date_Key, Store_Key, Product_Key) rather than natural keys (Store_ID, SKU) directly in fact tables — standard dimensional modeling practice, makes the model resilient if natural keys ever need to change.
- Both fact tables contain only numeric measures and foreign keys — no descriptive text (descriptions live in dimensions).
- Conformed dimensions (Dim_Date, Dim_Store, Dim_Product) shared across both fact tables, avoiding duplicated dimension logic.

---

# Business Questions This Model Supports

Directly maps to the KPI Catalog:

- What is the in-stock rate by store, by day? → Fact_Inventory_Snapshot + Dim_Store + Dim_Date (KPI-P01)
- What is the estimated lost margin from stockouts? → Fact_Inventory_Snapshot + Fact_Sales + Dim_Product (KPI-P02)
- Is a given stockout a distribution issue or a true shortage? → Fact_Inventory_Snapshot self-comparison across Dim_Store (KPI-P03)
- What is total pilot-region revenue? → Fact_Sales + Dim_Date (KPI-P04)

---

# Assumptions

- Every Fact_Sales and Fact_Inventory_Snapshot row references valid, existing dimension records (referential integrity enforced at data-generation time, per the Data Quality Assessment Framework).
- Dim_Store, Dim_Product are treated as static for the pilot's 12-month window (no mid-pilot store openings/closures or product discontinuations modeled) — a reasonable simplification for a contained pilot.

---

# Future Expansion (If Pilot Scales to Full Enterprise)

If this pilot is approved to scale, the following would need to be added back, consistent with the original enterprise ERD: Dim_Customer, Dim_Employee, Dim_Promotion, additional fact tables (Fact_Returns, Fact_Purchases), and fiscal calendar attributes in Dim_Date. This pilot's schema is designed so those additions would extend the model, not require redesigning it — the same principle the enterprise ERD states for its own future expansion.

---

# Power BI Implementation Best Practices (Applies to Phase 4 Build)

These apply once this model is actually loaded into Power BI:

- **Hide surrogate keys from report view.** Date_Key, Store_Key, Product_Key are join plumbing — a store manager viewing the dashboard should never see them. Keep natural/business-friendly fields (Store_Name, SKU, Product_Name) visible instead.
- **Prefer measures (DAX) over calculated columns** for anything derived — e.g., In-Stock Rate and Estimated Lost Margin (KPI-P01, KPI-P02) should be DAX measures, not pre-calculated columns baked into the fact table. Measures recalculate dynamically based on whatever filter context the user applies (store, date range, category), which calculated columns can't do as flexibly.
- **Keep relationships single-direction (Dimension → Fact), not bi-directional**, unless a specific report page genuinely requires it. Bi-directional filtering is a common source of ambiguous/incorrect results in Power BI models and should be the exception, not the default.
- **Both fact tables (Fact_Sales, Fact_Inventory_Snapshot) relate to the shared dimensions (Dim_Date, Dim_Store, Dim_Product) independently** — Power BI does not require them to relate to each other directly. Cross-fact analysis (like KPI-P02, which needs both sales and inventory) happens through the shared dimensions, not a direct fact-to-fact relationship.

---

# Definition of Done

This data model is complete when every relationship above has been implemented in the actual pilot database, and every KPI in the KPI Catalog can be calculated using only these two fact tables and three dimensions — no undocumented table or field required.
