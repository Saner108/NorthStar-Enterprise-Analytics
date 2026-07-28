# PILOT DASHBOARD WIREFRAME

Version: 1.0

Project:
NorthStar Retail Group
Inventory Visibility Pilot — Electronics & Home Goods, Southwest Region

Status: Approved for Development
Scope Note: Collapsed from the enterprise version's 8-page, 8-audience dashboard suite into a single page. This pilot has one real audience (the VP Ops / Store Manager roleplay personas in Stakeholder_Register.md) and five KPIs (KPI_Catalog.md) — building 8 separate pages for departments with no supporting data (Marketing, Customer Insights, Data Quality monitoring of a live ETL that doesn't exist) would be scope theater, not a real deliverable.

---

# Design Principle: One Page, Ordered by What the Audience Actually Needs First

Per Stakeholder_Register.md, the VP of Operations' key questions are: *"Which of my stores are worst affected?"* and *"Is this costing us real money?"* — not a general historical trend. The layout below is ordered to answer the most urgent, actionable question first, with supporting context and trend detail further down. This was a deliberate reordering decision during design — an earlier draft considered leading with the 12-month trend line, but that would have buried the pilot's actual headline finding (the distribution-vs-shortage split) beneath a slower, less actionable visual.

---

# Page Layout (Top to Bottom)

## Section 1 — KPI Cards (Top Row)

Three cards, left to right:

1. **Current In-Stock Rate %** (KPI-P01) — store-average across the pilot region, most recent date in the dataset
2. **Estimated Lost Margin ($, trailing 30 days)** (KPI-P02) — gives an immediate sense of financial stakes
3. **Total Pilot Revenue ($, trailing 12 months)** (KPI-P04) — context/denominator, lets a viewer judge how big the lost-margin number is relative to overall revenue

**Purpose:** Fast orientation — a viewer should understand the current state in under five seconds, before digging into anything else.

---

## Section 2 — Distribution vs. Shortage Classification (Hero Visual)

**Visual type:** Simple donut or 100% stacked bar showing the % split of all detected stockout events classified as "Distribution Issue" vs. "True Shortage" (KPI-P03, per BR-008b).

**Why this is the hero visual, not the trend line:** This chart directly answers the pilot's founding hypothesis and is the single most decision-relevant finding in the entire project — it tells leadership whether the fix is "rebalance inventory between stores" (if mostly Distribution Issue) or "fix procurement/ordering" (if mostly True Shortage). Everything else on this dashboard is supporting detail for this one finding.

**Interaction:** Clicking either segment filters Section 3 (store ranking) to show only stockouts of that classification.

---

## Section 3 — Store Ranking Table

**Visual type:** Sortable table/bar chart ranking pilot stores by Estimated Lost Margin (KPI-P02), highest first.

**Columns:** Store Name, In-Stock Rate %, Estimated Lost Margin ($), Number of Distinct Stockout Events, Primary Classification (Distribution/Shortage — whichever is more common for that store)

**Purpose:** Directly answers "which of my stores are worst affected" — the VP's stated primary question.

---

## Section 4 — 12-Month In-Stock Rate Trend

**Visual type:** Line chart, In-Stock Rate % over the 12-month window, one line per store (or an aggregate regional line with the ability to drill into individual stores).

**Purpose:** Supporting context — is the problem getting better, worse, or stable over time; are there seasonal patterns. Important, but appropriately placed after the more immediately actionable sections above, not before them.

---

# Filters / Slicers (Apply Across All Sections)

- **Date range** — defaults to full 12-month window, adjustable
- **Store** — filter to a single store or view all
- **Category** — Electronics / Home Goods / both

*(Enterprise version's Promotion filter excluded — no promotions data in this pilot.)*

---

# Standard Page Components (Reduced from Enterprise List)

- Page title: "NorthStar Southwest Electronics & Home Goods — Inventory Visibility Pilot"
- Brief business description line (1 sentence): what this dashboard shows and why it exists
- Filters visible at top

**Excluded from enterprise standard component list:** "Last Refresh Timestamp" (no live refresh — static generated dataset, per Data_Generation_Pipeline_Design.md), "Export Options" and "Help Information" (not necessary for a portfolio piece with a single, known audience), Navigation Buttons (moot — there's only one page).

---

# Design Standards (Unchanged Principles, Right-Sized Application)

- Consistent color use — same color represents the same concept everywhere (e.g., if "Distribution Issue" is blue in Section 2, it should be the same blue anywhere else it appears)
- No 3D charts
- Highlight exceptions — e.g., a store with an unusually low in-stock rate should visually stand out (conditional formatting), not require the viewer to scan every row
- Consistent layout — since there's only one page, this mainly means consistent spacing/alignment within that page, not cross-page consistency

---

# Accessibility

- Sufficient color contrast for the Distribution/Shortage split (don't rely on a subtle color difference alone — use labels too)
- Meaningful chart titles (not "Chart 1," "Chart 2")
- Alt text on visuals if the dashboard is ever exported/shared as an image

---

# Performance Guidelines

Given this pilot's actual data volume (~1.6M total rows per Fact_Table_Specification.md), standard Power BI performance practices (measures over calculated columns, avoid unnecessary bi-directional filters) are sufficient — no special large-dataset optimization is needed, consistent with the right-sizing principle applied throughout this project.

---

# Testing Checklist (Reduced — No RLS, No Multi-Page Navigation)

- [ ] Verify all 5 KPI values against manually calculated known test cases (per Power_BI_Semantic_Model_Design.md)
- [ ] Confirm the Distribution/Shortage donut chart correctly reflects the deliberately-generated test scenarios (at least one of each classification, per Data_Generation_Pipeline_Design.md)
- [ ] Test that clicking a donut segment correctly filters the store ranking table
- [ ] Test date/store/category slicers filter all sections correctly
- [ ] Confirm dashboard is legible/usable on a standard laptop screen (no mobile layout needed — not a stated requirement for this pilot's roleplay audience)

**Excluded from enterprise testing checklist:** "Verify security roles" (no RLS implemented — deliberate decision, see Power_BI_Semantic_Model_Design.md), "Confirm mobile layout" (not a requirement here).

---

# Definition of Done

This dashboard is complete when a viewer unfamiliar with the underlying DAX or data model can look at it and correctly answer, within a minute: which stores need attention, whether the problem is distribution or shortage, and roughly how much money is at stake — without narration from the analyst.
