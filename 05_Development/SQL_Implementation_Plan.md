# SQL IMPLEMENTATION PLAN

Version: 1.0

Project:
NorthStar Retail Group
Inventory Visibility Pilot — Electronics & Home Goods, Southwest Region

Status: Ready for Development
Scope Note: This is the direct execution roadmap for Claude Code (or manual implementation) to follow. Corrected to include Fact_Inventory_Snapshot, which was absent from the enterprise sequence's numbered roadmap — the same gap identified and fixed three times already in this project (ERD, Source-to-Target Mapping, and now here). No Dim_Customer or customer-analysis queries — no CRM data exists in this pilot.

---

# SQL Development Objectives (Unchanged Principle)

Validate generated data, support the 5 KPIs in KPI_Catalog.md, build reusable reporting views, produce a trusted dataset ready for the Power BI semantic model — same objectives as the enterprise version, scaled to this pilot's actual scope.

---

# Development Phases

## Phase 1 — Database Setup

- Create database (SQLite or Postgres — see Fact_Table_Specification.md volume analysis; either is appropriate at ~1.6M total rows)
- Create tables: `Dim_Date`, `Dim_Store`, `Dim_Product` (with SCD Type 2 structure), `Fact_Sales`, `Fact_Inventory_Snapshot`
- Load generated CSV data (per Data_Generation_Pipeline_Design.md)
- Validate all six relationships from Star_Schema.md load with zero orphaned foreign keys

## Phase 2 — Data Validation

Directly implements Data_Quality_Assessment_Framework.md's profiling checklist:
- Duplicate primary key detection (both fact tables, all three dimensions)
- Missing value check against Data_Dictionary.md's null-allowed rules
- Referential integrity (every Store_Key/Product_Key/Date_Key in both fact tables resolves)
- Business rule validation (BR-002, BR-007, BR-008, BR-008a, BR-008b — spot-check each)
- Row count validation against Fact_Table_Specification.md's calculated expected volume (~343K Fact_Sales, ~1.26M Fact_Inventory_Snapshot)
- SCD Type 2 validation: confirm the one deliberately-reclassified SKU has exactly two Dim_Product rows with non-overlapping effective date ranges, and confirm fact-table joins resolve to the historically correct version

## Phase 3 — Business Queries (Implementing the 5 KPIs)

- KPI-P01: In-Stock Rate by store/day
- KPI-P02: Estimated Lost Margin (requires baseline sales rate calculation + stockout period join)
- KPI-P03: Distribution vs. Shortage Classification (the pilot's core hypothesis test — see the reference query pattern already documented in SQL_Development_Standards.md)
- KPI-P04: Total Revenue
- KPI-P05: Gross Margin % by product

**Explicitly excluded (enterprise categories with no supporting pilot data):** Customer Analysis, most Operational Metrics beyond what the 5 KPIs cover.

## Phase 4 — Reporting Views

Named consistently with SQL_Development_Standards.md's naming convention:
- `vw_InStockRate` — store/day-level in-stock rate, ready for Power BI
- `vw_EstimatedLostMargin` — store/SKU-level lost margin estimate
- `vw_StockoutClassification` — per-stockout distribution/shortage label (KPI-P03)
- `vw_PilotRevenueSummary` — supports KPI-P04 context

**Excluded:** `vw_CustomerInsights` (no CRM data), generic `vw_ExecutiveDashboard` (this pilot has one dashboard, not a suite — the views above feed it directly rather than needing a separate aggregation view).

## Phase 5 — Performance Review (Right-Sized)

Given the calculated pilot volume (~1.6M total rows), this phase is intentionally light: confirm queries return in a reasonable time on a local machine, confirm primary key indexes exist. **No execution plan deep-dive, custom indexing strategy, or benchmarking suite is warranted at this scale** — consistent with the right-sizing principle already established in Fact_Table_Specification.md. If a specific query (likely KPI-P03's pooled-inventory comparison) runs slowly, the documented optimization path is a window function rewrite (noted already in SQL_Development_Standards.md) — but only if actually needed, not preemptively.

---

# SQL Folder Structure (Simplified)

```
/05_Development/SQL
    /schema          -- table creation scripts
    /load            -- CSV-to-database load scripts
    /validation       -- Phase 2 validation queries
    /analysis         -- Phase 3 KPI queries
    /views            -- Phase 4 reporting views
```

**Simplified from enterprise version:** no separate `/functions` or `/stored_procedures` folders — this pilot's scale doesn't require stored procedures or custom functions; plain queries and views are sufficient and more transparent for a portfolio reviewer to read directly.

---

# Query Documentation Standard (Unchanged — Already Established)

Every script uses the header block already defined in SQL_Development_Standards.md: Purpose, Business Requirement (FR-P0X), Business Rule (BR-XXX), Author, Created Date, Dependencies.

---

# Numbered Query Roadmap (Corrected and Pilot-Scoped)

```
001_Create_Database.sql
002_Create_Dim_Date.sql
003_Create_Dim_Product.sql          -- includes SCD Type 2 structure
004_Create_Dim_Store.sql
005_Create_Fact_Sales.sql
006_Create_Fact_Inventory_Snapshot.sql   -- ADDED: absent from enterprise sequence, same gap fixed 3x already in this project
007_Load_Dimensions.sql
008_Load_Fact_Sales.sql
009_Load_Fact_Inventory_Snapshot.sql     -- ADDED
010_Data_Validation.sql
011_KPI_P01_InStockRate.sql
012_KPI_P02_EstimatedLostMargin.sql
013_KPI_P03_DistributionVsShortage.sql
014_KPI_P04_Revenue.sql
015_KPI_P05_GrossMargin.sql
016_Create_Reporting_Views.sql
```

**Removed from enterprise sequence:** `005_Create_Dim_Customer.sql`, `013_Customer_Analysis.sql` — no CRM data in this pilot.

---

# Validation Strategy (Unchanged Principle)

Every query validated by: comparing row counts against Fact_Table_Specification.md's calculated expectations, testing the deliberately-generated known test cases (one "Distribution Issue" stockout, one "True Shortage" stockout, one SCD Type 2 reclassification — all per Data_Generation_Pipeline_Design.md), reviewing NULLs against Data_Dictionary.md's rules, confirming business rule compliance against Business_Rules_Catalog.md.

---

# Definition of Done

SQL implementation is complete when: the database is created and loaded per the corrected 16-script sequence above, all Phase 2 validation checks pass, all 5 KPI queries return results consistent with the deliberately-generated test scenarios, the 4 reporting views are created and named per SQL_Development_Standards.md's conventions, and Power BI can connect and build the semantic model described in Power_BI_Semantic_Model_Design.md without further SQL changes needed.
