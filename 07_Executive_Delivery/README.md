# 07_Executive_Delivery — Phase 6

The one-page executive dashboard for the Inventory Visibility Pilot, built from the
approved wireframe (`04_Analytics_Design/Dashboard_Wireframe.md`) and the chart/storytelling
rules in `04_Analytics_Design/Visualization_Standards.md`.

## Files

| File | What it is |
|---|---|
| `dashboard_standalone.html` | **Start here.** Self-contained single file — opens by double-click, works offline, and is what gets published as a shareable link. |
| `Inventory Visibility Dashboard.dc.html` | The design-tool export. Needs `support.js` beside it *and* network access (see below). |
| `support.js` | Generated runtime the export loads via a relative `./support.js` — keep it beside the export. |
| `build_standalone.py` | Rebuilds `dashboard_standalone.html` from the export. Re-run after any new export. |
| `github.md` | Design-tool sync metadata (source screen ↔ repo file map). |
| `.thumbnail` | WebP preview emitted by the design tool. |

## Why there is a standalone build

The design-tool export is not self-sufficient. It loads React, ReactDOM and Babel from
`unpkg.com` and its typefaces from Google Fonts, so anywhere those requests are blocked —
a hosted page with a strict content-security policy, an air-gapped laptop, an email
attachment — it renders as a blank page. `build_standalone.py` folds the dependencies in:

- **React + ReactDOM inlined** ahead of `support.js`. Its `loadReactUmd()` short-circuits on
  a pre-existing `window.React`, so the CDN is never contacted.
- **Babel deliberately not inlined.** `support.js` only pulls it in for `jsx` scripts, and
  this dashboard's script block is plain JS. Bundling the ~3MB compiler would have
  quadrupled the file for no benefit.
- **Fonts embedded** as base64 `@font-face` (Newsreader, IBM Plex Sans, IBM Plex Mono), so
  the page keeps its typography instead of silently falling back to Georgia/system-ui.

Verified in a headless browser with all network blocked: **0 external requests, 0 page
errors, 22/22 store rows rendered, 8/8 fonts loaded.** Interactivity survives the bundling —
clicking a donut segment still filters the store ranking, and the column headers still sort.

```bash
cd 07_Executive_Delivery && python3 build_standalone.py
```

The script needs the React UMD builds and the `@fontsource` webfont packages available
locally (see the paths at the top of the file). It fails loudly rather than silently
emitting a page that reaches for the network.

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
  revenue), distribution share 79.7%, revenue $81.1M, gross margin 38.5%.
- **Monthly revenue bars** — match `vw_PilotRevenueSummary` to the cent-rounded $M.
- **In-stock trend** — matches monthly `vw_InStockRate`.
- **Category split** — Electronics $1.68M (61.1%) / Home Goods $1.07M (38.9%).
- **Holiday lift 44.7%** — Nov/Dec average ($9,097,920) vs. the Jan–Oct average
  ($6,288,675) = 44.67%.
- **$2.19M distribution-attributed ceiling** — 79.66% of the $2.75M estimate, the same
  event-weighted basis the Phase 5 memo uses.
- **Top five stores ≈ a third** — 32.2% of regional lost margin.

If the generator or seed changes, these embedded snapshots must be refreshed — they are a
point-in-time copy, which is the trade-off of a static HTML deliverable rather than a live
Power BI connection.

## Corrections applied to earlier exports

1. **Gross Margin card: 38.4% → 38.5%.** The original averaged all **151** `Dim_Product`
   rows, which counts the SCD Type 2 reclassified SKU (SKU-1099) **twice** — once per
   category version. KPI-P05 and `05_Development/SQL/analysis/015_KPI_P05_GrossMargin.sql`
   define this at the SKU level and scope to `Is_Current = 1`, giving 38.55% → 38.5%. This
   is precisely the double-count the SCD2 reporting rollup exists to prevent (same reason
   `vw_EstimatedLostMargin_BySKU` rolls versions back to one VP-facing line). The current
   export also relabels the card "SKU-level avg · current versions" so the basis is on the
   face of it.
2. **In-stock trend, October: 92.9 → 92.8.** Actual value is 92.8456.

Both are carried in the current export.

## Holiday-lift basis — resolved

An earlier export said the holiday lift was "roughly 45%" while the Phase 5 memo said
"~35%", which read as a contradiction. Both were arithmetically correct on different
denominators; the current export resolves it by **naming the basis** rather than quietly
picking a number: "November and December average 44.7% above the Jan–Oct monthly average."

The memo's "~35%" is the same lift measured against the all-year average (34.65%), which
includes the Nov/Dec peak in its own denominator. It is not wrong, but it should state its
basis the way the dashboard now does, or the two documents will keep looking like they
disagree.

## One open judgment call

The **$2.19M** figure is the *event-weighted* distribution share — 79.66% of stockout
events × $2.75M — which is the basis the Phase 5 memo established. Weighting instead by
each store/SKU's own estimated margin gives **$2.16M**. The difference is immaterial to the
recommendation and the dashboard is self-consistent with the memo, so it was left alone;
but anyone recomputing it from the margin side will land on the smaller number, and the
memo is the place to pin the basis down if that ambiguity matters.
