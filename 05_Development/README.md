# 05_Development — SQL Implementation & Data Pipeline

This folder contains the runnable implementation of the pilot: the deterministic
synthetic-data generator, the numbered SQL scripts (001–016), and a single runner that
executes the whole pipeline end-to-end. It implements the design documented across
`00_Foundation`–`04_Analytics_Design` and follows `IMPLEMENTATION_BRIEF.md` — in
particular the **8 decisions that must not be silently changed**.

## Quick start

```bash
cd 05_Development
python3 run_pipeline.py
```

That command runs the full pipeline against a fresh SQLite database:

```
generate → CSV staging → create schema → load (dims first) → validate → KPIs → views
```

No third-party packages are required (Python standard library + the built-in `sqlite3`
module only). Expected runtime is well under a minute. On success it prints a Phase-2
validation table where every check reads `PASS` and exits `0`; any `FAIL` exits `1`.

Useful flags:

- `--seed N` — change the generation seed (default `42`; same seed ⇒ identical data).
- `--skip-generation` — reuse the existing `data/staging/*.csv` instead of regenerating.
- `--db PATH` — write the SQLite file somewhere other than `data/northstar_pilot.db`.

## Layout

```
05_Development/
├── generation/
│   └── generate_pilot_data.py       # Stage 1: deterministic synthetic data → CSVs
├── SQL/
│   ├── schema/      001–006          # CREATE DATABASE + tables (Dim_*, Fact_*)
│   ├── load/        007–009          # CSV → table loads (dimensions first)
│   ├── validation/  010              # Phase 2 profiling checks (PASS/FAIL rows)
│   ├── analysis/    011–015          # KPI-P01..P05 queries
│   └── views/       016              # 4 Power BI-ready reporting views
├── run_pipeline.py                   # end-to-end orchestrator (this is the entry point)
├── data/                             # generated CSVs + .db (git-ignored, reproducible)
├── Data_Generation_Pipeline_Design.md
└── SQL_Implementation_Plan.md
```

## The numbered sequence (001–016)

| # | Script | Stage |
|---|---|---|
| 001 | `schema/001_Create_Database.sql` | enable foreign keys |
| 002–004 | `schema/002..004` | `Dim_Date`, `Dim_Product` (SCD Type 2), `Dim_Store` |
| 005–006 | `schema/005..006` | `Fact_Sales`, `Fact_Inventory_Snapshot` |
| 007–009 | `load/007..009` | load dimensions, then both fact tables |
| 010 | `validation/010` | 17 data-quality / business-rule checks |
| 011–015 | `analysis/011..015` | KPI-P01 In-Stock Rate → KPI-P05 Gross Margin % |
| 016 | `views/016` | `vw_InStockRate`, `vw_StockoutClassification`, `vw_EstimatedLostMargin`, `vw_PilotRevenueSummary` |

## How the SQL scripts stay runnable both ways

The load scripts (007–009) use SQLite's native `.import` dot-command — the idiomatic way
a `sqlite3`-CLI user loads a CSV. `run_pipeline.py` includes a small shim that honors the
same `.import` / `.mode` commands, so the identical scripts run whether you have the
`sqlite3` CLI (`sqlite3 db < script`) or only the Python `sqlite3` module. All `.import`
paths are written relative to `05_Development/`, so run from this directory.

## Known-answer test cases (deliberately generated)

Per `IMPLEMENTATION_BRIEF.md` (Execution Order) the generator injects three cases so the
riskiest logic is validated against a known truth, not merely run without error. They are
recorded in `data/staging/_known_test_cases.json` after generation:

- **Distribution Issue** stockout — `STR-005` / `SKU-1010` on `2025-06-10`: that store is
  out, but pooled regional inventory (other stores + DC) clears the BR-008b
  redistributable-surplus floor of ≥ 3 units ⇒ KPI-P03 classifies it `Distribution Issue`.
- **True Shortage** stockout — `SKU-1020` on `2025-09-05`: every location is out, so the
  pooled total is 0 ⇒ KPI-P03 classifies it `True Shortage`.
- **SCD Type 2 reclassification** — `SKU-1099` moves Electronics → Home Goods on
  `2025-07-15`, producing two `Dim_Product` rows (two `Product_Key`s, one `SKU`) with
  non-overlapping effective-date ranges. Fact rows resolve to the version effective on
  their own date (validation check #15 confirms none are misrouted).

## Scope guardrails honored (from the brief)

Two fact tables at two grains (not merged); daily-snapshot inventory grain (not
event-based); BR-008 / BR-008a / BR-008b kept as three separate rules; SCD Type 2 on
Category only; a one-time generation-and-load pipeline (no live ETL / scheduling / DR);
and no partitioning, custom indexing, or RLS at this ~1.6M-row scale. See the brief for
why each of these is deliberate.

## What this pipeline feeds

Phase 5 (Analysis) is written against this pipeline's output:
`06_Analysis/Phase5_Findings_Memo.md`. Every figure in that memo is reproducible from a
clean run of `python3 run_pipeline.py --seed 42` — regional in-stock 92.5%, the ~9-point
store spread, the 79.7% / 20.3% distribution-vs-shortage split over ~90.4K store stockout
events, and ~$2.75M estimated lost margin on ~$81.1M revenue.

Phase 6 (Executive Delivery) is `07_Executive_Delivery/` — the one-page executive
dashboard. Its embedded figures are a point-in-time snapshot of the seed-42 build (all 22
store-ranking rows verified against the reporting views), so **if you change the generator
or the seed, refresh that dashboard's numbers too**.
