# VISUALIZATION STANDARDS & DATA STORYTELLING GUIDE

Version: 1.0

Project:
NorthStar Retail Group
Inventory Visibility Pilot — Electronics & Home Goods, Southwest Region

Status: Approved
Scope Note: Visualization principles (chart selection, storytelling structure, data-ink ratio) apply regardless of project scale and are carried forward largely unchanged. The main adjustment is reconciling this document's generic layout template with the specific ordering decision already made in Dashboard_Wireframe.md — see note below. The example story has also been replaced with one matching this pilot's actual hypothesis rather than a generic Northeast/safety-stock scenario.

---

# Guiding Principles (Unchanged)

Every visual should answer a business question, support a decision, be understandable within ~10 seconds, and reduce unnecessary complexity. These apply identically to a one-page pilot dashboard and an eight-page enterprise suite.

---

# Data Storytelling Framework (Unchanged Structure)

Every finding in this pilot's eventual Executive Findings document (Phase 5) should answer:

1. **What happened?** (e.g., "In-stock rate across pilot stores averaged X% over the trailing 12 months")
2. **Why did it happen?** (e.g., "Y% of stockouts occurred while adequate inventory existed elsewhere in the region — a distribution problem, not a supply problem")
3. **What should we do?** (e.g., a specific, scoped recommendation — likely something like piloting a rebalancing/transfer process between specific stores, not a vague "improve inventory management")

---

# Reconciling This Guide's Layout Template with Dashboard_Wireframe.md

**This document's generic template says:** Top = Executive KPIs, Middle = primary trend analysis, Bottom = supporting detail.

**Dashboard_Wireframe.md deliberately deviates from this** by placing the Distribution vs. Shortage classification (the pilot's actual headline finding) immediately after the KPI cards, with the 12-month trend line placed *after* the store ranking table — not in the "middle" position this generic template implies.

**This is not a contradiction to silently ignore — it's a documented, deliberate exception.** The general principle ("most important information goes where users look first") is still being followed; what changed is *which visual counts as most important* for this specific audience and business question. A trend line is the generically "expected" second visual, but for a VP whose stated top question is "which stores need attention right now," the classification chart is more decision-relevant than a historical trend. This guide's principle (lead with what matters most) and the Wireframe's specific choice (that's the classification chart, not the trend line, for this audience) are consistent — the generic template's assumption about what always matters most is simply overridden here for a documented reason.

---

# Choosing the Right Visualization (Applied to This Pilot's Actual Visuals)

| Visual Need (This Pilot) | Chart Type | Reasoning |
|---|---|---|
| Current In-Stock Rate %, Lost Margin $, Total Revenue | KPI Card | Single important metrics, per guide's own "one important metric" rule |
| Distribution vs. Shortage split (KPI-P03) | Donut or 100% stacked bar | Composition of a whole (all stockouts), exactly the "showing composition" use case |
| Store ranking by lost margin | Table or sorted bar chart | Per guide: "sort bars in descending order when highlighting top performers" — directly applicable, this table should be sorted worst-first |
| 12-month in-stock rate trend | Line chart | Textbook "trend over time" use case |

**Excluded from this pilot:** Map visualization (no city/lat-long data, and "Southwest region" as a single fixed value has no meaningful geographic variation to map), Scatter Plot (no obvious two-continuous-variable relationship question in this pilot's scope), Stacked Bar by multiple categories (only one category dimension with two values — not enough categories to warrant this chart type).

---

# Color Standards (Unchanged, Applied Specifically)

- **Distribution Issue** vs. **True Shortage** in the KPI-P03 chart should use genuinely distinct colors (not just a light/dark shade of the same hue) with text labels — per the Accessibility principle of not relying on color alone.
- Stockout severity in the store ranking table can use the Green/Yellow/Red convention (Green = healthy in-stock rate, Yellow = monitor, Red = needs attention) — but exact thresholds should be defined once real baseline data exists (Phase 5), not guessed now.

---

# Titles — Insight-Driven, Not Descriptive

Per this guide's own standard ("Better: Monthly Revenue Increased 9%... not Poor: Monthly Revenue"), pilot dashboard titles should follow the same pattern once real findings exist:

- Poor: "In-Stock Rate by Store"
- Better (once real data exists): "Store 12 Has the Lowest In-Stock Rate at X%, Driving an Estimated $Y in Lost Margin"

**Note:** Exact insight-driven titles can only be finalized after Phase 5 analysis produces real numbers — for now, working titles remain descriptive as placeholders, to be sharpened once findings exist.

---

# Slicers (Reduced to What This Pilot Actually Has)

**Recommended for this pilot:** Date, Store, Category (Electronics/Home Goods).

**Excluded:** Region (fixed to Southwest only — filtering on a single-value field adds no functionality), Sales Channel (single channel — in-store only, per Charter scope).

---

# Data-Ink Ratio (Unchanged Principle)

Same standard applies regardless of scale: no decorative backgrounds, no 3D charts, no unnecessary gridlines/borders. A one-page pilot dashboard has just as much reason to be clean as an eight-page enterprise suite — arguably more, since there's no room to bury clutter across multiple pages.

---

# Executive Storytelling Template (Unchanged Structure, Pilot-Specific Example)

## Example Story (Pilot Version, Replacing the Enterprise Placeholder)

**Business Question:** Are NorthStar's Southwest Electronics/Home Goods stockouts a supply problem or a distribution problem?

**Insight (Placeholder — to be replaced with real Phase 5 findings):** Preliminary analysis suggests the majority of detected stockouts occur while adequate inventory exists elsewhere in the region, at other pilot stores or the regional DC.

**Business Impact:** This reframes the problem from "we need to buy more inventory" (a procurement/cost question) to "we need to move existing inventory better" (an operations/logistics question) — a materially different, and likely less expensive, fix.

**Recommendation (Placeholder):** Pilot a store-to-store or DC-to-store rapid transfer process for the highest-lost-margin SKUs identified in the store ranking, rather than increasing total inventory purchase volume.

**Expected Outcome (Placeholder):** Improved in-stock rate at affected stores without a proportional increase in total inventory carrying cost.

**Note:** This entire example is a placeholder illustrating the *shape* of the eventual finding — it must be replaced with actual results once Phase 5 analysis is run on real generated data. Presenting this placeholder as if it were an actual finding, before the analysis has been done, would be exactly the kind of fabricated-confidence mistake this project has deliberately avoided elsewhere (e.g., declining to invent a 70% improvement target in the Charter).

---

# Review Checklist Before Treating Any Finding as Final

- Does every visual answer one of this pilot's five KPIs, specifically?
- Is the Distribution vs. Shortage finding immediately visible, per the deliberate layout decision in Dashboard_Wireframe.md?
- Can the roleplay VP Ops persona understand the dashboard in under a minute, per Stakeholder_Register.md's stated success criteria?
- Are all numbers in any "finding" traceable to an actual calculation on generated data — not a placeholder like the example story above?

---

# Definition of Done

This guide is complete when every visual in the actual Power BI dashboard can be checked against a specific row in the "Choosing the Right Visualization" table above, and the Executive Storytelling Template has been filled in with real Phase 5 findings, replacing the placeholder example.
