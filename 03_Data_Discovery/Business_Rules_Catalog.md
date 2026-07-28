# BUSINESS RULES CATALOG

Version: 1.0

Project:
NorthStar Retail Group
Inventory Visibility Pilot — Electronics & Home Goods, Southwest Region

Status: Approved
Scope Note: Trimmed to rules relevant to inventory visibility and stockout analysis. Customer/loyalty rules (no CRM in scope) and order/return processing rules (not part of this pilot's functional requirements) are excluded. One rule (Stockout) has been corrected from the enterprise version — see note below.

---

# Purpose

Defines the exact business logic that every SQL query, Python calculation, and Power BI measure in this pilot must follow. No KPI or visual may use logic that isn't documented here first.

---

# Sales Rules

## BR-001 — Completed Sale

**Rule:** A sale is considered complete once the transaction is finalized in Sales_Transactions. (Payment processing detail is out of pilot scope — all synthesized transactions are treated as completed by construction.)

**Business Impact:** Establishes what counts as a "sale" for baseline demand comparisons.

---

## BR-002 — Sales Amount

**Rule:** `Sales_Amount = Quantity × Unit_Price`. No discounts or taxes are modeled in this pilot (per BRD scope — discount fields excluded from Data Dictionary).

**Business Impact:** Keeps revenue calculation simple and traceable for a pilot with no discount/promotion data.

---

## BR-003 — Sales Date

**Rule:** Revenue is attributed to `Transaction_Date`.

**Business Impact:** Ensures consistent day-level aggregation for trend analysis.

---

# Inventory Rules

## BR-007 — Inventory On Hand

**Rule:** `Quantity_On_Hand` represents sellable inventory physically present at a store or the DC on a given day. This pilot does not model damaged/reserved/quarantined inventory as a separate state — all recorded inventory is assumed sellable.

**Business Impact:** Keeps the inventory model simple and defensible for a pilot scope; a documented simplification, not an oversight.

---

## BR-008 — Stockout (Corrected from Enterprise Version)

**Rule:** A stockout occurs when `Quantity_On_Hand = 0` for a given store/SKU/day. **This is a structural, inventory-state fact — it does not require evidence of customer demand to qualify as a stockout.**

**Why this differs from the enterprise catalog:** The original enterprise definition ("inventory reaches zero *while customer demand exists*") conflates two separate concepts: (1) detecting that a stockout occurred, and (2) estimating whether/how much it cost in lost sales. Requiring "demand exists" as part of the detection rule would cause real stockouts to be missed (if that day happened to have naturally low foot traffic) and would make the detection query dependent on a separate, harder analysis it doesn't need. This pilot treats stockout **detection** (BR-008) and stockout **impact/cost estimation** (BR-008a, below) as two distinct, sequential business rules.

**Business Owner (Roleplay):** VP Supply Chain

**Business Impact:** Directly implements FR-P03 (flagging out-of-stock SKUs).

---

## BR-008a — Stockout Impact Estimation

**Rule:** For any store/SKU/day flagged as a stockout under BR-008, estimated lost units = that store/SKU's average daily sales rate on days when `Quantity_On_Hand > 0` (a historical in-stock baseline), applied to the stockout period. Estimated lost margin = estimated lost units × (Retail_Price − Cost) from Product_Master.

**Business Impact:** Directly implements FR-P04 (margin-weighted stockout severity) — this is what lets the pilot say some stockouts matter more than others, rather than treating every stockout as equally costly.

---

## BR-008b — Distribution vs. Shortage Determination

**Rule:** For any store/SKU stockout (BR-008), sum `Quantity_On_Hand` for that same SKU across all other pilot stores plus the regional DC on the same date. If the pooled total is meaningfully greater than zero, classify as a **distribution/visibility problem**. If the pooled total is also at or near zero, classify as a **true shortage**.

**Business Impact:** Directly implements FR-P07 — this is the rule that proves (or disproves) the pilot's core hypothesis that NorthStar's stockout problem is about distribution, not total supply.

---

# Product Rules

## BR-011 — Active Product (Pilot Scope)

**Rule:** A product is in scope for this pilot if its `Category` is "Electronics" or "Home Goods." No discontinued-product logic is modeled — all pilot SKUs are treated as currently active/sellable.

**Business Impact:** Keeps the product scope aligned with the Charter's category boundary.

---

## BR-012 — Product Category

**Rule:** Each SKU belongs to exactly one of two categories in this pilot: "Electronics" or "Home Goods." (Enterprise version has 12 categories; pilot uses only these two per Charter scope.)

**Business Impact:** Enforces the category boundary at the data level, not just in documentation.

---

# Store Rules

## BR-013 — Active Store (Pilot Scope)

**Rule:** A store is in scope if it is one of the ~20–25 designated pilot stores in the Southwest region, `Location_Type = "Store"`. The regional DC is `Location_Type = "Distribution_Center"` and is included in inventory pooling logic (BR-008b) but excluded from store-level in-stock rate KPIs (it doesn't sell directly to customers).

**Business Impact:** Prevents the DC from being miscounted as a "store" in store-level reporting.

---

# Finance Rules (Limited to What the Pilot Needs)

## BR-014 — Gross Profit (Per-Transaction, Not Enterprise Financials)

**Rule:** For pilot purposes, Gross Profit per unit sold = `Retail_Price − Cost` (from Product_Master). This pilot does not model enterprise-level financial statements (COGS accounting, ERP integration) — only unit-level margin, sufficient to weight stockout severity.

**Business Impact:** Supports BR-008a without requiring full financial system integration, which is explicitly out of scope (per Charter).

---

## BR-015 — Gross Margin %

**Rule:** `Gross Margin % = (Gross Profit ÷ Retail_Price) × 100`, calculated at the SKU level.

**Business Impact:** Allows comparison of which stockouts matter most, proportionally, not just in absolute dollars.

---

# Reporting Rules

## BR-016 — Single Source of Truth (Pilot Scope)

**Rule:** All pilot dashboard visuals and analysis must source from the pilot's single data model (Sales_Transactions, Inventory_Snapshot, Product_Master, Store_Dimension) — no ad hoc recalculation outside the documented schema.

**Business Impact:** Ensures every number in the final dashboard is traceable back to this data model, not a one-off spreadsheet calculation.

---

## BR-018 — KPI Ownership

**Rule:** Every KPI used in this pilot must trace to a documented business rule in this catalog and a functional requirement in the BRD.

**Business Impact:** Prevents "orphan" KPIs that exist in the dashboard but can't be justified or explained.

---

# Rules Explicitly Excluded from Pilot Scope

The following enterprise rule categories are not applicable and intentionally omitted: Customer/CRM rules (BR-004, BR-005, BR-006 — no customer data in pilot), Order cancellation/return rules (BR-009, BR-010 — no returns processing modeled), enterprise refresh schedule (BR-017 — no live production refresh; pilot is a static/generated dataset).

---

# Traceability Matrix (Pilot Rules Only)

| Rule ID | Related KPI/Requirement | Source Table | Business Owner (Roleplay) |
|---|---|---|---|
| BR-002 | Sales_Amount | Sales_Transactions | Finance (roleplay) |
| BR-007 | Quantity_On_Hand | Inventory_Snapshot | VP Supply Chain |
| BR-008 | Stockout Flag (FR-P03) | Inventory_Snapshot | VP Supply Chain |
| BR-008a | Stockout Impact (FR-P04) | Sales_Transactions + Product_Master | VP Supply Chain |
| BR-008b | Distribution vs. Shortage (FR-P07) | Inventory_Snapshot | VP Supply Chain |
| BR-014/015 | Margin-weighting | Product_Master | Finance (roleplay) |

---

# Definition of Done

This catalog is complete when every KPI and dashboard visual built in Phase 3–4 can be traced to a specific rule listed here — and every rule here has already been explicitly justified against a functional requirement in the BRD.
