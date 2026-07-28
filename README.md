# NorthStar Enterprise Analytics

A deterministic synthetic data analytics pilot for **NorthStar Retail Group** focused on inventory visibility for **Electronics and Home Goods in the Southwest region**.

This repository contains the planning, data design, analytics design, and runnable implementation for a small star-schema + Power BI proof of concept that answers a core business question:

> Is the stockout problem driven by a **distribution issue** or by a **true shortage**?

## What’s in this repo

- **00_Foundation** — enterprise and company context
- **01_Project_Initiation** — charter and stakeholders
- **02_Business_Discovery** — business requirements
- **03_Data_Discovery** — source inventory, rules, dictionary, and mappings
- **04_Analytics_Design** — star schema, KPIs, Power BI model, and dashboard design
- **05_Development** — deterministic data generation, SQL scripts, and pipeline runner
- **IMPLEMENTATION_BRIEF.md** — the most important design decisions and execution order

## Project highlights

- Two fact tables with different grains:
  - `Fact_Sales` — one row per SKU per transaction
  - `Fact_Inventory_Snapshot` — one row per store/SKU/day
- `Dim_Product` uses **SCD Type 2** only for category changes
- Stockout detection, impact, and root-cause classification are separate rules
- The implementation is a **one-time synthetic data pipeline**, not a live ETL system
- The pipeline generates known-answer test cases so the most important logic can be verified

## Quick start

To run the implementation:

```bash
cd 05_Development
python3 run_pipeline.py
```

The pipeline:

1. Generates deterministic synthetic CSV data
2. Creates the SQLite schema
3. Loads dimensions and fact tables
4. Runs validation checks
5. Computes KPI queries
6. Creates reporting views

## Expected output

On success, the pipeline prints validation results where every check passes and exits with code `0`.

## Repository structure

```text
NorthStar-Enterprise-Analytics/
├── 00_Foundation/
├── 01_Project_Initiation/
├── 02_Business_Discovery/
├── 03_Data_Discovery/
├── 04_Analytics_Design/
├── 05_Development/
├── IMPLEMENTATION_BRIEF.md
├── README.md
└── .gitignore
```

## Notes

- No third-party Python packages are required.
- Generated data and SQLite files are ignored by git because they are reproducible.
- Phase 5 analysis and Phase 6 executive delivery are not yet written.

## Recommended reading order

1. `IMPLEMENTATION_BRIEF.md`
2. `01_Project_Initiation/Executive_Project_Charter.md`
3. `02_Business_Discovery/Business_Requirements_Document.md`
4. `03_Data_Discovery/Data_Dictionary.md`
5. `04_Analytics_Design/Star_Schema.md`
6. `05_Development/README.md`
