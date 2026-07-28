# BUSINESS REQUIREMENTS DOCUMENT (BRD)

Version: 1.0

Project:
NorthStar Retail Group
Inventory Visibility Pilot — Electronics & Home Goods, Southwest Region

Document Owner: Junior Data Analyst (Project Lead)
Business Sponsor (Roleplay): VP of Operations, Southwest Region
Status: Approved for Business Discovery

---

# Executive Summary

This BRD defines the business needs, functional requirements, and success criteria for the Inventory Visibility Pilot — a contained, single-region, single-category proof of concept for NorthStar's broader Enterprise BI Modernization Initiative.

Unlike the enterprise-wide BRD referenced in the Company Profile, this document intentionally covers **inventory/stockout visibility only.** Profitability reporting, store labor performance, customer analytics, and financial statement reporting are out of scope for this pilot — not because they lack value, but because a focused pilot proves the approach before expanding scope.

---

# Business Problem

Southwest region stores selling Electronics & Home Goods experience inconsistent in-stock rates. Leadership currently has no reliable, timely way to see which stores are out of stock on which SKUs, or to estimate how much revenue this costs. Store managers report stockouts anecdotally; there is no consolidated, trustworthy view.

---

# Business Need

The pilot requires a solution that provides:

- A consolidated, store-level view of current inventory for the in-scope category
- The ability to identify which stores/SKUs are out of stock, or at risk of stockout, at a glance
- A defensible way to estimate the cost of a stockout (weighted by margin and price, since not all stockouts are equally costly — a stockout on a high-margin item costs more than one on a low-margin substitutable item)
- A historical view (trailing 12 months) sufficient to detect patterns (which stores, which SKUs, which times of year)

---

# Project Goals

The pilot's data model and dashboard must enable a regional operations leader to answer, without waiting on a manual report:

- Which stores are currently out of stock on which SKUs?
- How long has each stockout persisted?
- Which stockouts are likely costing the most in lost margin?
- Is the total company-wide inventory adequate, but poorly distributed? (i.e., confirm this is a visibility/distribution problem, not a supply problem)

---

# Business Objectives

**Objective 1 — Establish Inventory Visibility**
Business Value: Leadership can see current in-stock status by store/SKU without manual reporting.

**Objective 2 — Establish a Trustworthy Baseline In-Stock Rate**
Business Value: Creates the measurement foundation required before any optimization initiative can be evaluated.

**Objective 3 — Identify High-Impact Stockout Patterns**
Business Value: Surfaces which stores/SKUs matter most (by margin exposure), so any future optimization work is prioritized rather than applied uniformly.

*(Note: objectives such as "standardize enterprise KPIs" or "self-service analytics for all departments" from the enterprise BRD are intentionally not repeated here — they belong to the full initiative, not this pilot.)*

---

# Functional Requirements (Pilot Scope Only)

| ID | Requirement | Priority |
|---|---|---|
| FR-P01 | The solution shall display current inventory level by store and SKU, for in-scope stores/category only. | Critical |
| FR-P02 | The solution shall calculate and display an in-stock rate (% of SKUs in stock) at the store level. | Critical |
| FR-P03 | The solution shall flag SKUs currently out of stock at a given store. | Critical |
| FR-P04 | The solution shall estimate potential lost margin from a stockout, using product cost/price data. | High |
| FR-P05 | The solution shall support historical trend view (trailing 12 months) of in-stock rate by store. | High |
| FR-P06 | The solution shall allow filtering by store and by SKU/product. | Medium |
| FR-P07 | The solution shall distinguish "store stockout while company-wide supply is adequate" from "true company-wide shortage." | High |

Explicitly excluded from this pilot's functional requirements (deferred to full enterprise scope): role-based security across departments, automated scheduled refresh to a live production environment, export to enterprise reporting portals, customer-level analysis, financial statement integration.

---

# Non-Functional Requirements (Right-Sized for a Portfolio Pilot)

- **Performance:** Dashboard should load in a reasonable time on Power BI Desktop (no enterprise-scale performance SLA needed for a 20-store dataset).
- **Reproducibility:** Data model and transformations must be documented well enough that another analyst (or an interviewer) could follow the logic without live explanation.
- **Usability:** A non-technical store/regional manager should be able to interpret the dashboard without training.

---

# Business Questions This Pilot Must Answer

- Which Southwest Electronics/Home Goods stores have the lowest in-stock rates?
- Which specific SKUs are the most frequent or costly stockout offenders?
- Is inventory imbalance (not total shortage) confirmed as the actual root cause?
- What would a scaled version of this approach look like for the full enterprise?

---

# Assumptions

- Data is synthesized to realistically reflect retail sales/inventory patterns (seasonality, weekday variance, category-specific demand curves) since this is a portfolio project without access to live enterprise systems.
- Electronics & Home Goods is assumed representative enough of "mid-frequency, high-ticket" retail categories to generalize conceptually to other categories later.

---

# Constraints

- Solo analyst, ~4 month timeframe, ~$5,000 notional budget (see Charter)
- No live production data access — synthetic data only

---

# Success Metrics

Consistent with the Charter: no invented percentage targets at this stage. Success is measured by whether the pilot produces a **trustworthy, explainable baseline** and **at least one actionable, evidence-backed finding** — see Charter's Success Metrics table for the finalization plan.

---

# Requirement Traceability Matrix

| Requirement | Business Goal | Deliverable |
|---|---|---|
| FR-P01 | Inventory Visibility | Star schema + Power BI inventory view |
| FR-P02 | Baseline Measurement | In-stock rate KPI (KPI Catalog) |
| FR-P03 | Stockout Identification | Dashboard stockout flag/filter |
| FR-P04 | Prioritization by Impact | Margin-weighted stockout analysis (Python) |
| FR-P05 | Trend Detection | Historical trend visual |
| FR-P06 | Usability | Dashboard filter controls |
| FR-P07 | Root Cause Confirmation | Store-vs-DC inventory comparison analysis |

---

# Acceptance Criteria

This BRD is complete when:

- Every functional requirement traces to a real business question from this pilot's scope.
- No requirement exceeds what the Charter's pilot scope allows.
- The analyst can explain why each requirement matters to a non-technical stakeholder.

---

# Approval

Business Sponsor (Roleplay): ______________________________

Project Lead: ______________________________

Date: ______________________________
