# DATA GENERATION & LOAD PIPELINE DESIGN

Version: 1.0

Project:
NorthStar Retail Group
Inventory Visibility Pilot — Electronics & Home Goods, Southwest Region

Status: Approved for Development
Scope Note: This document replaces the enterprise "ETL Architecture" concept with an honest reframing. The enterprise version assumes live source systems (POS, ERP, WMS, CRM, etc.) feeding a nightly incremental pipeline with disaster recovery, encryption-in-transit, and retry logic. This pilot has no live source systems — data is synthetically generated once for a fixed 12-month window. Rather than fabricate infrastructure that doesn't apply, this document keeps the legitimate underlying concepts (staged validation, dimensions-before-facts load order, data lineage, error handling) and applies them honestly to a generation pipeline instead of a production ETL pipeline.

---

# Why This Isn't "Real" ETL, and Why That's Stated Explicitly

A resume or interview claim of having "built an ETL pipeline" should mean something specific and honest. This pilot did not extract from a live operational system — it generated synthetic data designed to plausibly resemble what such a system would produce. Calling this a full production ETL pipeline would overstate the work. The accurate and defensible description is: **a data generation and load pipeline that mirrors real ETL staging/validation/load discipline**, built to produce a referentially sound star schema for analysis. This distinction should be stated plainly if ever discussed in an interview — overclaiming here would be an easy thing for a technical interviewer to catch and would undermine trust in every other claim in the portfolio.

---

# Pipeline Overview

```
Generation Logic (Python)
        ↓
Raw CSV Files (staging layer)
        ↓
Validation Checks (per Data_Quality_Assessment_Framework.md)
        ↓
Transformation (surrogate key assignment, SCD Type 2 logic, derived fields)
        ↓
Load into Database (Dimensions first, then Fact tables)
        ↓
Star Schema (ready for SQL/Python analysis and Power BI)
```

---

# Stage 1 — Generation (Replaces "Extract")

**Objective:** Produce synthetic records that plausibly resemble what POS, WMS, and Product Master would provide, following the fields defined in Data_Dictionary.md.

**Activities:**
- Generate Dim_Store records first (22 stores + 1 DC, Southwest region)
- Generate Dim_Product records (150 SKUs, Electronics/Home Goods, including the one deliberately-reclassified SKU for the SCD Type 2 exercise)
- Generate Dim_Date records (full calendar for the 12-month window)
- Generate Fact_Sales records referencing the above, following realistic patterns (weekday/weekend variance, seasonal spikes)
- Generate Fact_Inventory_Snapshot records that are **logically consistent with Fact_Sales** — inventory must decrement in a way that reflects recorded sales, and a deliberate subset of store/SKU/day combinations must be generated as true stockouts (Quantity_On_Hand = 0) with a documented mix of "distribution issue" and "true shortage" scenarios (per BR-008b), so the pilot's core hypothesis has real, known-answer data to validate against

**Output:** Raw CSV files — `dim_store.csv`, `dim_product.csv`, `dim_date.csv`, `fact_sales.csv`, `fact_inventory_snapshot.csv`

---

# Stage 2 — Staging (CSV Files as the Staging Layer)

**Purpose:** The generated CSVs serve the same role a staging area serves in a real ETL pipeline — an inspectable, unmodified checkpoint before anything is loaded into the database.

**Why this matters for a solo project:** If a downstream KPI looks wrong, the first diagnostic question is "is this a generation bug or a load/SQL bug?" Having raw CSVs to inspect independently answers that question quickly, rather than requiring you to re-run generation and re-load together every time you're debugging.

---

# Stage 3 — Validation (Applies Data_Quality_Assessment_Framework.md Directly)

Before loading CSVs into the database, run the profiling checklist already documented in Phase 2:

- [ ] Row counts match expected volume (per Fact_Table_Specification.md calculations: ~343K Fact_Sales rows, ~1.26M Fact_Inventory_Snapshot rows)
- [ ] No duplicate primary keys
- [ ] No orphaned foreign keys (every Store_ID/SKU referenced in facts exists in the corresponding dimension CSV)
- [ ] No negative Quantity_Sold, Sales_Amount, or Quantity_On_Hand
- [ ] Category values limited to "Electronics"/"Home Goods" only
- [ ] Date ranges fall within the 12-month pilot window with no gaps (per the Timeliness dimension defined in the Data Quality Assessment Framework)

**Failed records:** Rather than a formal "exception table" (appropriate for live ETL with ongoing data arriving), a validation failure here means **stopping and fixing the generation script** — since this is a one-time batch generation, not an ongoing feed, there's no ongoing stream of bad records to triage; there's just a bug to find and fix before proceeding.

---

# Stage 4 — Transformation

**Activities:**
- Assign surrogate keys (Date_Key, Store_Key, Product_Key) to replace natural keys (Full_Date, Store_ID, SKU) in fact table foreign key references
- Apply SCD Type 2 logic for Dim_Product: generate the two-row history for the one SKU undergoing category reclassification (per Dimension_Table_Specifications.md), and ensure Fact_Sales/Fact_Inventory_Snapshot rows reference the *effective* Product_Key for their date, not simply the current one
- Calculate derived fields where appropriate (e.g., Sales_Amount = Quantity_Sold × Unit_Price) — though for KPIs like In-Stock Rate and Estimated Lost Margin, these remain DAX measures in Power BI rather than pre-calculated columns, per the Power BI best practices already documented in Star_Schema.md

---

# Stage 5 — Load

**Destination:** A single local/free-tier relational database (SQLite or Postgres — see Fact_Table_Specification.md volume calculations; either handles ~1.6M total rows without issue).

**Loading Order:** Dimensions first (Dim_Date, Dim_Store, Dim_Product), then both fact tables (Fact_Sales, Fact_Inventory_Snapshot) — same principle as the enterprise version, same real reason: fact tables reference dimension surrogate keys, which must already exist before a fact row can be validly inserted.

---

# What's Explicitly Not Built (and Why That's the Right Call)

| Enterprise ETL Concept | Pilot Status | Why |
|---|---|---|
| Incremental daily loading | Not applicable | One-time batch generation for a fixed historical window, not an ongoing feed |
| Scheduled 2 AM execution | Not applicable | No production schedule exists for a portfolio analysis project |
| Disaster recovery / retry logic | Not applicable | No live system to fail or recover from |
| Encryption in transit | Not applicable | No real customer/sensitive data exists in this pilot (no CRM data at all) |
| Multi-source extraction (8 systems) | Reduced to 1 generation script | Only 3 source systems are in scope, and none are live — a single script produces all pilot data |

Naming these explicitly is itself part of doing this right — a portfolio piece that silently omits real-world complexity looks like an oversight; one that explains *why* each piece isn't needed here looks like judgment.

---

# Data Lineage (Pilot Version)

```
Power BI Dashboard
        ↓
Star Schema (SQLite/Postgres)
        ↓
Fact_Sales / Fact_Inventory_Snapshot
        ↓
Generated CSV staging files
        ↓
Python generation script (simulating POS / WMS / Product Master)
```

Every number in the final dashboard should be traceable down this chain to the specific line of generation logic that produced it — this is the pilot's equivalent of the enterprise version's "source system to executive dashboard" lineage requirement.

---

# Validation Checklist Before Considering This Pipeline "Done"

- [ ] Generation script runs deterministically (same output given same random seed — important for reproducibility, so results can be regenerated/verified later)
- [ ] All CSV staging files pass the Stage 3 validation checklist
- [ ] Dimensions load successfully before fact tables are loaded
- [ ] SCD Type 2 logic for Dim_Product verified with a direct query (per Dimension_Table_Specifications.md's Definition of Done)
- [ ] At least one deliberately-generated "distribution issue" stockout and one deliberately-generated "true shortage" stockout exist in the data, so KPI-P03 has known-answer test cases to validate against

---

# Definition of Done

This pipeline is complete when running the generation script end-to-end produces a fully loaded, referentially sound star schema that passes every validation check above — and the analyst can explain, for any given data point in the final dashboard, exactly which stage of this pipeline produced it.
