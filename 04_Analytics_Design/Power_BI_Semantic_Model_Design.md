# POWER BI SEMANTIC MODEL DESIGN

Version: 1.0

Project:
NorthStar Retail Group
Inventory Visibility Pilot — Electronics & Home Goods, Southwest Region

Status: Approved for Development
Scope Note: Trimmed to the pilot's two fact tables and three dimensions. Row-Level Security is deliberately excluded — this is a solo portfolio project with no real multi-user audience to restrict, and implementing RLS anyway would be unjustified complexity with no scenario behind it (see project discussion log / Decision Log for this reasoning). Hierarchies, measures, and perspectives are all reduced to match what Dim_Product and Dim_Store actually contain per Dimension_Table_Specifications.md — not the enterprise version's fuller attribute set.

---

# Purpose

Defines the Power BI semantic layer between the loaded star schema (SQLite/Postgres) and the dashboard. This is the direct implementation spec for the Power BI `.pbix` file — precise enough that Claude Code (or the analyst) can build the model without further design decisions.

---

# Model Architecture

```
SQLite/Postgres Database (star schema, per Star_Schema.md)
        ↓
Power BI Semantic Model (this document)
        ↓
Single Pilot Dashboard
```

No enterprise-style "Executive Dashboards → Business Users" fan-out — this is one dashboard, one primary audience (the roleplay VP Ops / Store Manager personas from Stakeholder_Register.md).

---

# Included Tables

**Fact Tables:** `Fact_Sales`, `Fact_Inventory_Snapshot`

**Dimension Tables:** `Dim_Date`, `Dim_Store`, `Dim_Product`

**Explicitly excluded:** Dim_Customer, Dim_Employee, Dim_Promotion, and all "future fact tables" (Fact_Returns, Fact_Budget, Fact_Forecast) listed in the enterprise version — none have supporting data in this pilot.

---

# Relationships

| From | To | Type | Cross-Filter |
|---|---|---|---|
| Fact_Sales | Dim_Date | Many-to-One | Single (Dim → Fact) |
| Fact_Sales | Dim_Store | Many-to-One | Single |
| Fact_Sales | Dim_Product | Many-to-One | Single |
| Fact_Inventory_Snapshot | Dim_Date | Many-to-One | Single |
| Fact_Inventory_Snapshot | Dim_Store | Many-to-One | Single |
| Fact_Inventory_Snapshot | Dim_Product | Many-to-One | Single |

All relationships use surrogate keys (Date_Key, Store_Key, Product_Key), consistent with Star_Schema.md. No bi-directional filtering — per the Power BI best practices already documented there.

---

# Measures (DAX) — Directly Implementing the KPI Catalog

Per the Power BI best practices already established: **these are DAX measures, not calculated columns**, so they recalculate correctly under any filter context (store, date range, category selection).

**In-Stock Rate (KPI-P01):**
```dax
In-Stock Rate % = 
DIVIDE(
    CALCULATE(COUNTROWS(Fact_Inventory_Snapshot), Fact_Inventory_Snapshot[Quantity_On_Hand] > 0),
    COUNTROWS(Fact_Inventory_Snapshot)
) * 100
```

**Estimated Lost Margin (KPI-P02):** Implemented as a more involved measure requiring the historical baseline sales rate calculation — Claude Code should implement per the formula in KPI_Catalog.md (BR-008a), likely requiring an intermediate calculated table or complex DAX (e.g., `AVERAGEX` over in-stock days joined with stockout period length). This measure is the most technically demanding one in the model and should be built and validated carefully, ideally with a known test case (per Data_Generation_Pipeline_Design.md's deliberately-generated test scenarios).

**Distribution vs. Shortage Classification (KPI-P03):** Best implemented as a calculated column or separate query table rather than a pure measure, since it's a per-row classification rather than an aggregate — this is a reasonable, documented exception to the "measures over calculated columns" rule, since KPI-P03 isn't being aggregated the same way P01/P02 are.

**Total Revenue (KPI-P04):**
```dax
Total Revenue = SUM(Fact_Sales[Sales_Amount])
```

**Gross Margin % (KPI-P05):**
```dax
Gross Margin % = 
DIVIDE(
    SUMX(Dim_Product, Dim_Product[Retail_Price] - Dim_Product[Unit_Cost]),
    SUMX(Dim_Product, Dim_Product[Retail_Price])
) * 100
```

**Excluded from enterprise measure list (no supporting data):** Inventory Turnover, Average Order Value, Customer Count.

---

# Calculated Columns (Minimal, Per Established Best Practice)

Per Star_Schema.md's guidance, calculated columns are used sparingly. The one necessary exception:

- **KPI-P03 classification** (Distribution Issue / True Shortage) — a per-row label, appropriately a calculated column or pre-computed table rather than a measure.

No other calculated columns are needed at this pilot's scope — no Age Group, Preferred Channel Classification, or similar enterprise examples apply (no customer data).

---

# Hierarchies (Reduced to Match Actual Dimension Attributes)

**Date Hierarchy:** Year → Quarter → Month → Day *(unchanged — Dim_Date structure supports this fully)*

**Geography Hierarchy:** State → Store *(reduced from the enterprise Region → State → City → Store — this pilot's Dim_Store has no City field, and Region is a fixed single value "Southwest," so it adds no navigational value as a hierarchy level)*

**Product Hierarchy:** Category → Product *(reduced from Department → Category → Subcategory → Product — this pilot's Dim_Product has neither Department nor Subcategory fields, per Dimension_Table_Specifications.md's deliberate trim)*

---

# Display Folders (Reduced to Match Actual Measures)

- **Inventory** — In-Stock Rate %, Distribution vs. Shortage Classification
- **Financial Impact** — Estimated Lost Margin, Gross Margin %
- **Revenue Context** — Total Revenue

*(Enterprise version's "Customer," "Marketing," "Operations" folders excluded — no measures exist in those categories for this pilot.)*

---

# Naming Standards (Unchanged Principle)

Business-friendly names in the model: "In-Stock Rate %," "Estimated Lost Margin," not "Inv_Rate_Calc" or "Measure_003."

---

# Formatting Standards

| Measure Type | Format |
|---|---|
| In-Stock Rate %, Gross Margin % | Percentage, 1 decimal |
| Estimated Lost Margin, Total Revenue | Currency, 2 decimals |
| Quantity_On_Hand, Quantity_Sold | Whole number |
| Dates | Short date |

---

# Row-Level Security — Deliberately Not Implemented

**Decision:** RLS is excluded from this pilot. RLS exists to restrict data visibility across real, distinct users with different access needs — this is a solo portfolio project with a single analyst and no live multi-user audience to restrict. Implementing RLS without a real scenario behind it would be unjustified complexity, inconsistent with the right-sizing principle already applied elsewhere in this project (e.g., the earlier decision not to add database partitioning for a 1.6M-row dataset).

**If asked in an interview:** the analyst should be able to explain RLS conceptually (e.g., "a Regional Manager role would see only their region's data via a DAX filter on Dim_Store") without having needed to build a fake version of it here.

---

# Performance Optimization (Applied)

- Surrogate keys (Date_Key, Store_Key, Product_Key) hidden from report view.
- Measures used instead of calculated columns wherever the calculation is a true aggregate (all but KPI-P03).
- Single-direction relationships only.
- No high-cardinality columns exist at this pilot's scale (largest dimension is ~150 products) — cardinality optimization concerns from the enterprise version don't meaningfully apply here.

---

# Data Refresh

Static load, refreshed manually if the generation script is re-run — no scheduled daily refresh, consistent with Data_Generation_Pipeline_Design.md (no live source system to refresh from).

---

# Testing

- Validate all six relationships load correctly with no orphaned keys.
- Validate each measure against a manually calculated known value (e.g., manually compute In-Stock Rate for one store on one day, compare against the DAX measure's output).
- Confirm KPI-P02 (Estimated Lost Margin) produces a sensible, non-negative result for the deliberately-generated test stockout scenarios.
- Confirm KPI-P03 correctly classifies both the deliberately-generated "Distribution Issue" and "True Shortage" test cases.

---

# Success Criteria

This semantic model is complete when all five KPI Catalog measures are implemented, validated against known test cases, and a non-technical viewer (per the Store Manager/VP Ops roleplay personas in Stakeholder_Register.md) could interpret the dashboard without requiring an explanation of the underlying DAX.
