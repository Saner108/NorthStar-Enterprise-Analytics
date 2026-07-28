# EXECUTIVE PROJECT CHARTER

Version: 1.0

Project Name

NorthStar Retail Group
Inventory Visibility Pilot — Electronics & Home Goods, Southwest Region

Prepared By

Business Intelligence Department (Junior Analyst, Pilot Lead)

Prepared For

Executive Sponsor Review

Status

Approved for Pilot Initiation

Classification

Internal Confidential

Engagement Duration

Approximately 4 months (one academic semester equivalent)

---

# Relationship to Enterprise Initiative

NorthStar Retail Group's Board and Executive Leadership have approved a multi-year Enterprise Business Intelligence Modernization Initiative covering all 250 stores, 8 distribution centers, and 12 product categories.

Rather than attempting enterprise-wide transformation immediately, leadership has authorized a **contained pilot** as Phase 1 of that initiative. This Charter governs the pilot only.

**Why a pilot instead of a full rollout:** Deploying a new data model, KPI set, and reporting pipeline across 250 stores and 12 categories simultaneously means any flaw in the approach — a wrong assumption, a data quality issue, a schema design mistake — is discovered at full scale, where it is expensive and slow to correct. A contained pilot allows the Business Intelligence team to validate the data model, KPI definitions, and reporting approach on a manageable slice of the business, catch problems cheaply, and scale with confidence once proven. This is a standard risk-containment pattern, not a limitation of ambition.

---

# Business Problem Statement

NorthStar's Southwest region, Electronics & Home Goods category, currently experiences inconsistent in-stock rates across stores despite adequate total company-wide inventory. This is a **distribution and visibility problem**, not a total-supply problem: a store can show a stockout on a SKU while another store in the same region — or the regional distribution center — holds ample stock of the same item.

Specific challenges:

- Store-level inventory data exists in the Warehouse Management System but is not consolidated into a single, fast, cross-store view.
- Leadership cannot currently answer, on demand, "which stores are out of stock on which high-value SKUs right now."
- Because visibility does not yet exist, stockout-driven lost sales cannot currently be measured or quantified — only anecdotally reported by store managers.

---

# Business Opportunity

A working inventory visibility layer for this pilot region/category creates the measurement foundation needed to later pursue in-stock optimization (rebalancing inventory between stores, adjusting replenishment timing, etc.). Establishing visibility first, then optimization, reflects a deliberate sequencing decision: **you cannot reliably optimize what you cannot yet measure.**

---

# Project Objectives

**Primary Objective**

Establish reliable, near-real-time inventory visibility across the pilot stores, sufficient to identify stockouts by store and SKU and to establish a credible baseline in-stock rate.

**Secondary Objective (enabled by, not parallel to, the primary objective)**

Use the visibility baseline to identify the pilot region's highest-impact stockout patterns (weighted by margin and likely substitutability, not stockout count alone) as candidates for future optimization work.

---

# Pilot Scope

**In Scope**

- Southwest region only
- Electronics & Home Goods product category only
- Approximately 20–25 stores + 1 supporting distribution center
- In-store retail channel only
- Trailing 12 months of historical data for trend analysis
- Data sources: Point of Sale (sales), Warehouse Management System (inventory), Product Master (category/cost/price)
- Deliverables: data model, SQL analysis, Python analysis, Power BI dashboard, executive findings summary

**Explicitly Out of Scope**

- All other regions (Southeast, Midwest, Mountain, West Coast)
- All other product categories (11 of 12 categories excluded)
- E-commerce, BOPIS, ship-from-store, marketplace channels
- CRM/customer-level analysis
- Financial statement-level reporting (ERP general ledger, AP/AR)
- HR/labor data
- Supplier/procurement performance
- Enterprise-wide rollout, training, or change management (reserved for a future phase if the pilot is approved to scale)

---

# Success Metrics

Because no baseline data yet exists, this Charter intentionally avoids inventing precise improvement percentages before analysis has occurred. Fabricated targets (e.g., "reduce reporting time 70%") cannot be defended without evidence and would not survive scrutiny in an interview or executive review.

| Metric | Target at Charter Stage | How It Will Be Finalized |
|---|---|---|
| Inventory visibility latency | Reduce time to detect a stockout from "unknown/manual" to same-day | Confirmed once baseline manual process time is documented |
| In-stock rate baseline | Establish accurate baseline (currently unmeasured) | Calculated directly from pilot data once modeled |
| Stockout cost visibility | Quantify estimated lost-sale exposure, weighted by margin | Calculated from POS + Product Master once data model is built |
| Data accuracy | Inventory figures reconcile against source WMS data | Validated during Data Discovery phase |

**Definition of Done for this metric approach:** once baseline figures exist (Phase 5), this table will be updated with specific, evidence-backed improvement targets — not before.

---

# Stakeholders

See `Stakeholder_Register.xlsx` (pilot-scoped) for full detail. Summary:

- **Executive Sponsor (roleplay):** Chief Operating Officer — approves pilot, reviews outcomes
- **Business Sponsor (roleplay):** VP of Operations, Southwest Region
- **Project Lead:** Junior Data Analyst (you) — requirements gathering, data modeling, SQL/Python development, dashboard build, documentation
- **Primary Users (roleplay):** Southwest Regional Store Managers, Southwest Distribution Center Manager

---

# Assumptions

- WMS and POS data can be reasonably simulated/synthesized to reflect realistic retail patterns for this pilot (since this is a portfolio project, not a live production engagement).
- Electronics & Home Goods is a representative category for demonstrating inventory imbalance dynamics (high ticket price, moderate substitutability, lower purchase frequency than grocery/consumables).
- Pilot findings, if the model holds up, are intended to generalize as a proof-of-concept for future regions/categories — not to be enterprise-complete on their own.

---

# Constraints

- Solo analyst (no dedicated data engineering, QA, or design support)
- ~4 month timeframe
- ~$5,000 notional budget (tooling only — Power BI Desktop free tier, low-cost/free database hosting; no paid labor)
- No access to a real enterprise data source — data is synthesized to be realistic

---

# Risks

| Risk | Mitigation |
|---|---|
| Synthesized data may not reflect real-world edge cases | Design data generation deliberately around known retail patterns (seasonality, weekday/weekend variance, category-specific demand) rather than pure randomness |
| Optimization targets cannot be validated until visibility layer exists | Sequence work so visibility/data model is built and validated before any optimization claims are made |
| Scope creep back toward "full enterprise" framing | Charter explicitly names out-of-scope items; any expansion requires an explicit scope decision, documented in the Decision Log |
| Solo timeline slippage | Prioritize Phase 2–4 (data model, SQL, dashboard) as the core portfolio deliverable; Phase 0/1 documentation stays lean once sufficient to justify downstream decisions |

---

# Budget Summary (Notional)

| Item | Estimated Cost |
|---|---|
| Power BI Desktop | $0 (free) |
| Database hosting (local/free-tier cloud) | $0–$50 |
| Analyst time | Not monetized (portfolio project) |
| Contingency | ~$50 |
| **Total** | **~$5,000 notional cap (unused capacity reserved for tooling upgrades if needed, e.g., Power BI Pro for publishing)** |

---

# Definition of Success

This pilot is considered successful when:

- A working, validated data model exists covering the in-scope stores/category.
- Store-level in-stock rate can be calculated and trusted.
- At least one clear, evidence-based finding about stockout patterns (e.g., which stores/SKUs are worst offenders, weighted by margin) can be presented and defended.
- The analyst can explain every modeling decision, KPI, and recommendation without notes.
- A documented, honest case exists for whether/how this approach should scale to additional regions/categories.

---

# Approval

Executive Sponsor (roleplay): ______________________________

Project Lead: ______________________________

Date: ______________________________
