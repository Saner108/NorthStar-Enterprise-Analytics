# NorthStar Retail Group — Inventory Visibility Pilot

A deterministic, synthetic-data analytics pilot that answers one operational question for a
fictional $5.2B omnichannel retailer:

> When stores run out of stock, is it a **distribution/visibility problem** (the inventory
> exists elsewhere in the region) or a **true shortage** (the region is genuinely out)?

Scope is deliberately narrow — **Southwest region, ~22 stores + 1 DC, Electronics & Home Goods,
in-store channel, 12 months**. The full $5.2B/250-store enterprise context lives in
`00_Foundation/` for realism; everything else is scoped honestly to the pilot.

**[▶ Live dashboard](https://YOUR-VERCEL-URL.vercel.app)** · **[Findings memo](06_Analysis/Phase5_Findings_Memo.md)** · **[Techniques & methods](techniques/TECHNIQUES.md)**
<!-- replace the Vercel URL above once the project is deployed -->

<!-- Add a dashboard screenshot here, e.g. ![Dashboard](assets/dashboard.png) — take it from the live Vercel page -->

## Headline finding

- **92.5% regional in-stock rate** — but uneven: worst store **87.9%**, best **96.9%** (a 9-point spread).
- **79.7% of stockouts are Distribution Issues** (stock existed elsewhere in the region) vs **20.3% True Shortages** — the founding hypothesis, confirmed by the data, not assumed.
- **~$2.75M estimated lost margin (3.4% of revenue)**, and roughly a **third of it sits in just five stores**.
- The fix the data points to: **redistribute to the worst stores**, not buy more inventory. No improvement target is claimed — *baseline pending*.

Full analysis: **[06_Analysis/Phase5_Findings_Memo.md](06_Analysis/Phase5_Findings_Memo.md)**.

## What's in this repo

| Folder | Contents |
|---|---|
| `00_Foundation` | Enterprise/company context (kept full-scale as reference) |
| `01_Project_Initiation` | Charter, stakeholder register |
| `02_Business_Discovery` | Business requirements |
| `03_Data_Discovery` | Source inventory, business rules, data dictionary, mappings |
| `04_Analytics_Design` | Star schema, KPIs, Power BI model, dashboard wireframe |
| `05_Development` | Deterministic data generation, SQL (schema→load→validate→analyze→views), pipeline runner |
| `06_Analysis` | **Phase 5 findings memo**, plus `NorthStar_Data_Explorer.xlsx` — the seed-42 data as a spreadsheet (dimensions in full, facts sampled, a sheet per KPI) |
| `07_Executive_Delivery` | **Phase 6 executive dashboard** (source) |
| `techniques/` | Write-ups of the 10 techniques used — with SQL, sample rows, and diagrams |
| `index.html` | The dashboard, served at the site root (Vercel) |
| `IMPLEMENTATION_BRIEF.md` | The design decisions that matter most, and execution order |

## Techniques & methods

What each method is, **why** it was chosen over the alternative, and what it looks like in the
build (real SQL, sample rows, Mermaid diagrams). Full write-ups in **[`techniques/`](techniques/TECHNIQUES.md)**.

| # | Technique | Why it's here |
|---|-----------|---------------|
| 1 | [Dimensional (star-schema) modeling](techniques/docs/01-dimensional-modeling.md) | Query-simple, BI-ready, explicit grain |
| 2 | [Two fact tables at different grains](techniques/docs/02-two-fact-grains.md) | Merging sales + inventory double-counts |
| 3 | [Daily snapshot grain](techniques/docs/03-snapshot-grain.md) | Storage-for-simplicity trade-off |
| 4 | [SCD Type 2](techniques/docs/04-scd-type-2.md) | Keep history correct through a mid-year reclassification |
| 5 | [Business-rule separation](techniques/docs/05-business-rule-separation.md) | Detect ≠ cost ≠ diagnose a stockout |
| 6 | [Pooled-inventory classification](techniques/docs/06-pooled-classification.md) | The query that tests the hypothesis |
| 7 | [Deterministic synthetic data](techniques/docs/07-synthetic-data-generation.md) | Reproducible data with a known injected problem |
| 8 | [Known-answer testing & validation](techniques/docs/08-validation-testing.md) | Prove correctness, not just execution |
| 9 | [Reporting / semantic views](techniques/docs/09-reporting-views.md) | Separate presentation from storage |
| 10 | [Audience-driven dashboard hierarchy](techniques/docs/10-dashboard-hierarchy.md) | Lead with the decision-maker's first question |

## Quick start

No third-party packages required.

```bash
cd 05_Development
python3 run_pipeline.py --seed 42
```

The pipeline: generates deterministic synthetic CSVs → creates the SQLite schema → loads
dimensions then facts → runs 17 validation checks → computes the 5 KPI queries → builds
reporting views. On success every check passes and it exits `0`.

## Reproducibility & verification

- **Seeded (`--seed 42`)**: the entire ~1.6M-row dataset is byte-for-byte reproducible.
- Verified end-to-end at seed 42: in-stock **92.49%**, split **79.7 / 20.3**, lost margin **$2,750,523** — matching the findings memo to the dollar.
- **17/17** automated integrity checks pass; SCD Type 2 shows **0** misrouted fact rows.
- Generated data and the SQLite DB are git-ignored because they are fully reproducible from the generator + seed.

## The 5 KPIs

`In-Stock Rate %` · `Estimated Lost Margin $` · `Distribution vs. Shortage Classification` ·
`Total Revenue` · `Gross Margin %` — each traces to a stated business question (see
`04_Analytics_Design/KPI_Catalog.md`).

## Recommended reading order

1. `IMPLEMENTATION_BRIEF.md`
2. `01_Project_Initiation/Executive_Project_Charter.md`
3. `03_Data_Discovery/Business_Rules_Catalog.md` (the three-part stockout logic)
4. `04_Analytics_Design/Star_Schema.md`
5. `techniques/TECHNIQUES.md`
6. `06_Analysis/Phase5_Findings_Memo.md`

## Notes

- Data is **synthetic**; a one-time deterministic generation pipeline, **not** a production ETL feed. Figures demonstrate the method, not real company performance.
- The repo is named "Enterprise" for the full company context; the delivered work is the deliberately scoped-down **pilot** described above.
