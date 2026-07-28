# SOURCE-TO-TARGET MAPPING (STM)

Version: 1.0

Project:
NorthStar Retail Group
Inventory Visibility Pilot — Electronics & Home Goods, Southwest Region

Status: Approved for Development
Scope Note: "Source" here means the Python generation script's output (raw CSV staging files), not a live operational system — consistent with Data_Generation_Pipeline_Design.md. This document is the direct implementation contract for that script: it specifies exactly which generated field maps to which target column, with which transformation, so the generation and load code can be written without ambiguity. Critically, this version adds a Fact_Inventory_Snapshot mapping, which is absent from the enterprise STM entirely (same gap identified earlier in the Star Schema and Fact Table Specification documents).

---

# Generated Data Sources (Replaces Live Source Systems)

| Generated Source | Simulates | Purpose |
|---|---|---|
| `dim_store.csv` | Store master data | Store/DC reference |
| `dim_product.csv` | Product Master | Product reference, including SCD Type 2 history |
| `dim_date.csv` | Standard calendar generation | Date reference |
| `fact_sales.csv` | POS transactions | Sales events |
| `fact_inventory_snapshot.csv` | WMS daily inventory | Inventory state |

---

# Mapping: fact_sales.csv → Fact_Sales

| Generated Field | Target Column | Transformation | Validation |
|---|---|---|---|
| transaction_id | Sales_Key | Direct (already unique from generation) | Must be unique |
| transaction_date | Date_Key | Lookup Dim_Date | Must exist in Dim_Date |
| store_id | Store_Key | Lookup Dim_Store | Must exist in Dim_Store; must be Location_Type = "Store" (DC does not sell directly) |
| sku | Product_Key | Lookup Dim_Product **using the version effective on transaction_date** (SCD Type 2 — see note below) | Must exist in Dim_Product |
| quantity | Quantity_Sold | Direct | Must be > 0 |
| unit_price | Unit_Price | Round to 2 decimals | Must be > $0.00 |

**Derived field — Sales_Amount:** `Quantity_Sold × Unit_Price`. No discount/tax logic (not modeled in this pilot per BRD scope).

**SCD Type 2 lookup note:** Unlike a simple dimension lookup, the Product_Key resolution here must check `Effective_Start_Date`/`Effective_End_Date` against `transaction_date` to find the *correct historical version* of the product record — not simply join to whichever Product_Key is currently marked `Is_Current = TRUE`. This is the exact mechanism documented in Dimension_Table_Specifications.md and is the most technically important transformation in this entire mapping.

---

# Mapping: fact_inventory_snapshot.csv → Fact_Inventory_Snapshot

*(This table has no equivalent in the enterprise STM — it was absent there just as it was absent from the enterprise ERD. It is the pilot's most important mapping.)*

| Generated Field | Target Column | Transformation | Validation |
|---|---|---|---|
| snapshot_date | Date_Key | Lookup Dim_Date | Must exist in Dim_Date |
| location_id | Store_Key | Lookup Dim_Store | Must exist in Dim_Store (may be Store or Distribution_Center type) |
| sku | Product_Key | Lookup Dim_Product using version effective on snapshot_date (same SCD Type 2 logic as above) | Must exist in Dim_Product |
| quantity_on_hand | Quantity_On_Hand | Direct | Must be ≥ 0 |

**Business rule applied downstream (not a transformation, a query-time rule):** BR-008 (stockout = Quantity_On_Hand = 0), BR-008a (impact estimation), BR-008b (distribution vs. shortage classification) all operate on this loaded table — they are analysis logic, not load-time transformations, and are documented fully in Business_Rules_Catalog.md.

---

# Mapping: dim_product.csv → Dim_Product

| Generated Field | Target Column | Transformation | Validation |
|---|---|---|---|
| sku | SKU | Direct (natural/business key) | Unique per active version |
| product_name | Product_Name | Direct | Required |
| category | Category | Direct | Must be "Electronics" or "Home Goods" |
| unit_cost | Unit_Cost | Round to 2 decimals | Must be > $0.00 |
| retail_price | Retail_Price | Round to 2 decimals | Must be ≥ Unit_Cost |
| effective_start_date | Effective_Start_Date | Direct | Required |
| effective_end_date | Effective_End_Date | Direct | NULL for current version only |
| is_current | Is_Current | Direct (boolean) | Exactly one TRUE per SKU at any time |

**Note:** `Product_Key` is generated as a new surrogate key for *each version* of a SKU record — the one deliberately-reclassified SKU will produce two Dim_Product rows (two Product_Keys), both sharing the same SKU.

---

# Mapping: dim_store.csv → Dim_Store

| Generated Field | Target Column | Transformation | Validation |
|---|---|---|---|
| store_id | Store_ID | Direct | Unique |
| store_name | Store_Name | Direct | Required |
| location_type | Location_Type | Direct | "Store" or "Distribution_Center" only |
| region | Region | Direct | Fixed: "Southwest" |
| state | State | Direct | Must be a Southwest-region state |
| store_size | Store_Size | Direct | Optional |

---

# Mapping: dim_date.csv → Dim_Date

Standard calendar generation — Full_Date, Day_Name, Day_Number, Week_Number, Month, Month_Name, Quarter, Year, Weekend_Indicator all derived directly from a generated date range covering the 12-month pilot window. No lookup/transformation complexity here — this is the simplest table in the pipeline.

---

# Business Rule Mapping (Corrected from Enterprise Version)

| Rule ID | Description | Applied To |
|---|---|---|
| BR-002 | Sales_Amount = Quantity × Unit_Price | Fact_Sales |
| BR-007 | Quantity_On_Hand represents sellable inventory only | Fact_Inventory_Snapshot |
| BR-008 | Stockout = Quantity_On_Hand = 0 (structural fact, no demand requirement) | Fact_Inventory_Snapshot |
| BR-008a | Estimated lost margin from stockouts | Fact_Sales (baseline) + Fact_Inventory_Snapshot (stockout days) + Dim_Product (margin) |
| BR-008b | Distribution vs. shortage classification | Fact_Inventory_Snapshot (pooled comparison across Dim_Store) |
| BR-014/BR-015 | Gross profit / margin % at product level | Dim_Product |

**Note:** The enterprise version's BR-010 ("Returns reduce revenue") and any Fact_Returns mapping are excluded — no returns are modeled in this pilot.

---

# Validation Rules (Applied Once, at Generation Time — Not Ongoing)

- Primary key uniqueness in every table
- Foreign key integrity — every Store_Key/Product_Key/Date_Key referenced in a fact table must exist in its dimension
- Required fields populated (per Data_Dictionary.md null rules)
- Category limited to two accepted values
- No negative Quantity_Sold, Sales_Amount, or Quantity_On_Hand
- No duplicate transaction_id or duplicate (snapshot_date, location_id, sku) combination
- Dates fall within the defined 12-month window

**Difference from enterprise version:** These checks run once, after generation and before load — there is no ongoing "exception table" or ongoing reprocessing cycle, since this isn't a recurring live feed (consistent with Data_Generation_Pipeline_Design.md's Stage 3).

---

# Data Lineage Example (Pilot Version)

```
Generated fact_inventory_snapshot.csv (snapshot_date field)
        ↓
Dim_Date.Date_Key (lookup)
        ↓
Fact_Inventory_Snapshot.Date_Key
        ↓
Power BI In-Stock Rate KPI (KPI-P01)
```

---

# Testing Requirements

- Verify generated row counts match Fact_Table_Specification.md's calculated expected volume (~343K Fact_Sales, ~1.26M Fact_Inventory_Snapshot)
- Confirm every SCD Type 2 lookup resolves to the historically correct Product_Key (spot-check the one reclassified SKU across dates before/after its Effective_Start_Date change)
- Confirm referential integrity — zero orphaned foreign keys after load
- Confirm at least one known "distribution issue" and one known "true shortage" stockout scenario load correctly and classify as expected (per BR-008b)

---

# Definition of Done

This mapping is complete when the Python generation script can be written directly from this document with no remaining ambiguity about which generated field becomes which target column, and the SCD Type 2 lookup logic for Product_Key is precise enough to implement correctly on the first attempt.
