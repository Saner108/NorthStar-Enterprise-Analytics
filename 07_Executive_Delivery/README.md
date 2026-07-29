# 07_Executive_Delivery — Phase 6

The one-page executive dashboard for the Inventory Visibility Pilot, built from the
approved wireframe (`04_Analytics_Design/Dashboard_Wireframe.md`) and the chart/storytelling
rules in `04_Analytics_Design/Visualization_Standards.md`.

## Files

| File | What it is |
|---|---|
| `Inventory Visibility Dashboard.dc.html` | The dashboard. Open it directly in a browser. |
| `support.js` | Generated runtime the HTML loads via a relative `./support.js` — keep it beside the HTML. |
| `github.md` | Design-tool sync metadata (source screen ↔ repo file map). |
| `.thumbnail` | WebP preview emitted by the design tool. |

## Section order (locked — matches the wireframe)

KPI cards → **Distribution vs. Shortage hero visual** → store ranking table → 12-month
in-stock trend. Per Decision 7 in `IMPLEMENTATION_BRIEF.md`, the classification chart is
deliberately the hero and the trend line is deliberately last: the VP's question is "which
stores need attention, and is this distribution or shortage," not "what did the year look
like." Do not reorder this back to a trend-second default.

Interactions and framing that carry over from the wireframe: selecting a donut segment
filters the store ranking to margin attributed to that cause; the availability gauge runs
green→red with a review threshold; the footnotes keep the synthetic-data, estimate, and
threshold caveats visible rather than buried.

## Every figure is traceable to the database

The dashboard's numbers are a snapshot of the seed-42 build, not hand-typed estimates.
Each one was verified against `05_Development/data/northstar_pilot.db` after a clean
`python3 run_pipeline.py --seed 42`:

- **All 22 store-ranking rows** — name, in-stock %, estimated lost margin, stockout events
  and distribution % — match `vw_InStockRate` / `vw_EstimatedLostMargin` /
  `vw_StockoutClassification` exactly, in the same rank order. Zero mismatches.
- **Headline cards** — in-stock 92.5% (range 87.9–96.9%), lost margin $2.75M (3.4% of
  revenue), distribution share 79.7%, revenue $81.1M.
- **Monthly revenue bars** — match `vw_PilotRevenueSummary` to the cent-rounded $M.
- **In-stock trend** — matches monthly `vw_InStockRate`.
- **Category split** — Electronics $1.68M (61.1%) / Home Goods $1.07M (38.9%).

If the generator or seed changes, these embedded snapshots must be refreshed — they are a
point-in-time copy, which is the trade-off of a static HTML deliverable rather than a live
Power BI connection.

## Two corrections applied to the delivered export

1. **Gross Margin card: 38.4% → 38.5%.** The original averaged all **151** `Dim_Product`
   rows, which counts the SCD Type 2 reclassified SKU (SKU-1099) **twice** — once per
   category version. KPI-P05 and `05_Development/SQL/analysis/015_KPI_P05_GrossMargin.sql`
   define this at the SKU level and scope to `Is_Current = 1`, giving 38.55% → 38.5%. This
   is precisely the double-count the SCD2 reporting rollup exists to prevent (same reason
   `vw_EstimatedLostMargin_BySKU` rolls versions back to one VP-facing line). The donut
   arc's `stroke-dasharray` was adjusted to match.
2. **In-stock trend, October: 92.9 → 92.8.** Actual value is 92.8456.

## Known inconsistency to resolve (not silently changed)

The dashboard states the holiday revenue lift as **"roughly 45%"**; the Phase 5 memo
(`06_Analysis/Phase5_Findings_Memo.md`) states **"~35%"**. Both are arithmetically correct
on different bases:

- **44.7%** — Nov/Dec average vs. the **non-holiday** monthly average (the dashboard's basis)
- **34.6%** — Nov/Dec average vs. the **all-year** monthly average, which includes the peak
  itself in the denominator (the memo's basis)

These are two published deliverables quoting different numbers for the same claim, so one
basis should be picked and applied to both. The non-holiday basis is the more natural
reading of "revenue jumps in November and December," but this is the analyst's call and has
been left as-is pending that decision.
