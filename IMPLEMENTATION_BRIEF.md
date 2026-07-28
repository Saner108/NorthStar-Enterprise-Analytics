# IMPLEMENTATION BRIEF — READ THIS FIRST

Version: 1.0

Project: NorthStar Retail Group — Inventory Visibility Pilot (Electronics & Home Goods, Southwest Region)

**Purpose of this document:** This repo contains ~20 planning documents built through careful, deliberate design reasoning. Several decisions in here are *not obvious* and depart from what a generic/default implementation would produce. This brief exists so an implementation agent (Claude Code) does not have to re-derive — or accidentally re-derive incorrectly — decisions that were already made deliberately, for documented reasons. **Read this file first. When in doubt about any design choice, the documents referenced below are authoritative — do not deviate from them without flagging the deviation explicitly to the project lead.**

---

# The One-Sentence Version of This Project

Build a small, referentially-sound star schema and Power BI dashboard proving whether NorthStar's Southwest Electronics/Home Goods stockout problem is a **distribution issue** (inventory exists elsewhere in the region) or a **true shortage** (it doesn't) — using synthetically generated data, since no live enterprise system exists to pull from.

---

# The 8 Decisions That Matter Most (Do Not Silently Change These)

## 1. Two fact tables, not one — different grains

`Fact_Sales` (one row per SKU per transaction) and `Fact_Inventory_Snapshot` (one row per store/SKU/day) are **separate tables**, both joining to the same three shared dimensions (Dim_Date, Dim_Store, Dim_Product). Do not attempt to merge them — they answer different questions at different grains, and merging would either lose daily inventory granularity or bloat the sales table with redundant rows.

**Full detail:** `04_Analytics_Design/Star_Schema.md`, `04_Analytics_Design/Fact_Table_Specification.md`

## 2. Fact_Inventory_Snapshot uses daily-snapshot grain, not event-based logging

This was a deliberate trade-off: event-based (log only when inventory changes) is more storage-efficient and closer to real production WMS systems, but requires reconstructing point-in-time state via window functions (`LAG`), which is riskier for a solo, time-boxed project. Daily snapshot was chosen explicitly to reduce risk to the core KPI, at the cost of some storage efficiency. **Do not "optimize" this into event-based logging** without flagging it — that would silently reintroduce the exact risk this decision was designed to avoid.

**Full detail:** `03_Data_Discovery/Data_Dictionary.md` (Inventory_Snapshot table design note)

## 3. Stockout detection and stockout impact are two separate rules — do not conflate them

- **BR-008 (detection):** A stockout is simply `Quantity_On_Hand = 0`. Full stop. No sales/demand condition attached.
- **BR-008a (impact):** A *separate* calculation estimating lost margin, using historical baseline sales rate.
- **BR-008b (root cause):** A *separate* calculation comparing pooled regional inventory to classify Distribution Issue vs. True Shortage.

**This distinction was corrected during planning after an initial, incorrect proposal to require "zero sales" as part of stockout detection** — that would have caused real stockouts to be missed and non-stockouts to be falsely flagged. If any implementation combines these three rules into one query/condition, that is very likely a reintroduction of that exact error — check it against Business_Rules_Catalog.md before proceeding.

**Full detail:** `03_Data_Discovery/Business_Rules_Catalog.md` (BR-008, BR-008a, BR-008b)

## 4. Dim_Product implements SCD Type 2 on Category only — nothing else is SCD-tracked

One deliberately-reclassified SKU (simulating a mid-year Electronics → Home Goods recategorization) should produce **two rows in Dim_Product**, same SKU, different Product_Key, non-overlapping `Effective_Start_Date`/`Effective_End_Date` ranges. Fact table joins to Dim_Product must resolve to the **version effective on the fact row's date** — not simply the current version. This is the single most technically important join in the entire schema; get it wrong and historical category-level rollups (e.g., "Electronics in-stock rate in Q1") will be silently incorrect for that one SKU.

**Every other dimension attribute in every other table is intentionally treated as static** for this pilot's 12-month window — do not add SCD logic elsewhere without a documented reason.

**Full detail:** `04_Analytics_Design/Dimension_Table_Specifications.md`, `03_Data_Discovery/Source_to_Target_Mapping.md`

## 5. No live ETL — this is a one-time synthetic data generation pipeline

There is no source system to extract from. Do not build scheduling, incremental loads, retry/disaster-recovery logic, or encryption-in-transit — none of it applies. The pipeline is: **generate → CSV staging → validate → transform (including SCD Type 2 logic) → load (dimensions first, then both fact tables)**. Calling this "ETL" without qualification would overstate the work; the honest and correct description is a data generation and load pipeline that mirrors real ETL staging discipline.

**Full detail:** `05_Development/Data_Generation_Pipeline_Design.md`

## 6. Expected data volume is small (~1.6M total rows) — do not over-engineer infrastructure

~343,200 Fact_Sales rows, ~1,259,750 Fact_Inventory_Snapshot rows (22 stores + 1 DC × ~150 SKUs × 365 days for inventory; similar calculation for sales at ~2 transactions/SKU/week). This is trivial for SQLite or Postgres. **Do not add partitioning, custom indexing strategy beyond standard primary/foreign keys, or Row-Level Security** — none of these are justified at this scale or in this solo-analyst context. If asked why these weren't built, the answer is: they weren't needed, and building them anyway would be added complexity without a real problem to solve.

**Full detail:** `04_Analytics_Design/Fact_Table_Specification.md`, `04_Analytics_Design/Power_BI_Semantic_Model_Design.md`

## 7. Dashboard is one page, and the visual hierarchy is deliberately non-default

Order (top to bottom): **KPI cards → Distribution vs. Shortage split (hero visual) → store ranking table → 12-month trend line.** This was a deliberate deviation from a generic "KPIs, then trend, then detail" template — the classification chart is more decision-relevant to this pilot's actual audience (VP Ops asking "which stores need attention, and is this a distribution or shortage problem") than a historical trend line would be. Do not reorder this back to a "trend line second" default without understanding why it was deliberately placed last.

**Full detail:** `04_Analytics_Design/Dashboard_Wireframe.md`, `04_Analytics_Design/Visualization_Standards.md`

## 8. No fabricated success percentages anywhere in this repo

The Charter and BRD intentionally do not state things like "reduce stockouts by 70%" — there was no baseline data at planning time to justify any specific number. Real targets get set only after Phase 5 analysis produces actual baseline figures from the generated data. **Do not retroactively insert specific percentage targets into planning documents** — if asked to summarize expected outcomes, state that targets are pending baseline measurement, consistent with the rest of this repo.

**Full detail:** `01_Project_Initiation/Executive_Project_Charter.md` (Success Metrics section)

---

# Execution Order

Follow `05_Development/SQL_Implementation_Plan.md`'s numbered script sequence exactly:

```
001_Create_Database.sql
002_Create_Dim_Date.sql
003_Create_Dim_Product.sql          -- includes SCD Type 2 structure (see Decision 4)
004_Create_Dim_Store.sql
005_Create_Fact_Sales.sql
006_Create_Fact_Inventory_Snapshot.sql
007_Load_Dimensions.sql
008_Load_Fact_Sales.sql
009_Load_Fact_Inventory_Snapshot.sql
010_Data_Validation.sql
011_KPI_P01_InStockRate.sql
012_KPI_P02_EstimatedLostMargin.sql
013_KPI_P03_DistributionVsShortage.sql
014_KPI_P04_Revenue.sql
015_KPI_P05_GrossMargin.sql
016_Create_Reporting_Views.sql
```

Before writing `007`/`008`/`009` (data generation), the generation script must deliberately create:
- At least one stockout classified as "Distribution Issue" (pooled regional inventory > 0)
- At least one stockout classified as "True Shortage" (pooled regional inventory = 0)
- The one SCD Type 2 category-reclassification SKU

These are **known-answer test cases** — without them, there's no way to verify KPI-P03 and the SCD Type 2 join logic actually work correctly, only that they run without error.

---

# Full Document Index (Read in This Order If Doing a Full Review)

| Order | Document | What It Covers |
|---|---|---|
| 1 | `00_Foundation/*` | Company/enterprise context (broader than this pilot — read for background only) |
| 2 | `01_Project_Initiation/Executive_Project_Charter.md` | Pilot scope, objectives, why a pilot instead of enterprise rollout |
| 3 | `01_Project_Initiation/Stakeholder_Register.md` | Who this is "for" (roleplay personas) |
| 4 | `02_Business_Discovery/Business_Requirements_Document.md` | Functional requirements (FR-P01–FR-P07) |
| 5 | `03_Data_Discovery/Data_Source_Inventory.md` | Which 3 of 8 enterprise sources are in scope |
| 6 | `03_Data_Discovery/Data_Dictionary.md` | Every field, every table, including the grain decision |
| 7 | `03_Data_Discovery/Data_Quality_Assessment_Framework.md` | Validation dimensions and pilot-specific reinterpretation |
| 8 | `03_Data_Discovery/Business_Rules_Catalog.md` | BR-008/8a/8b — the most important logic in the project |
| 9 | `03_Data_Discovery/Source_to_Target_Mapping.md` | Field-level generation-to-schema mapping |
| 10 | `04_Analytics_Design/KPI_Catalog.md` | The 5 KPIs, formulas, known limitations |
| 11 | `04_Analytics_Design/Star_Schema.md` | Two-fact-table design |
| 12 | `04_Analytics_Design/Fact_Table_Specification.md` | Grain, volume calculations |
| 13 | `04_Analytics_Design/Dimension_Table_Specifications.md` | SCD Type 2 worked example |
| 14 | `04_Analytics_Design/SQL_Development_Standards.md` | Coding conventions, reference query patterns |
| 15 | `04_Analytics_Design/Power_BI_Semantic_Model_Design.md` | DAX measures, no-RLS decision |
| 16 | `04_Analytics_Design/Dashboard_Wireframe.md` | Layout and visual hierarchy |
| 17 | `04_Analytics_Design/Visualization_Standards.md` | Chart selection, storytelling template |
| 18 | `05_Development/Data_Generation_Pipeline_Design.md` | Generation → staging → validate → load |
| 19 | `05_Development/SQL_Implementation_Plan.md` | The numbered script execution sequence |

---

# What Comes After Implementation (Not Yet Started)

Per `04_Analytics_Design`'s planning, Phase 5 (Analysis) and Phase 6 (Executive Delivery) are not yet built — those require real output from the implementation phase (actual in-stock rates, actual lost-margin figures, actual distribution-vs-shortage split) before they can be written honestly. Do not pre-write executive findings or recommendations with placeholder numbers presented as if real — the Visualization_Standards.md document explicitly flags this as a mistake to avoid.
