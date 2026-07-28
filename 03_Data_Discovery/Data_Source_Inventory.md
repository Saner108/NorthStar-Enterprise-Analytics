# DATA SOURCE INVENTORY

Version: 1.0

Project:
NorthStar Retail Group
Inventory Visibility Pilot — Electronics & Home Goods, Southwest Region

Status: Approved
Scope Note: This inventory lists all data sources referenced in NorthStar's full enterprise data landscape, but only three are in scope for this pilot. The remaining five are documented for completeness and future-roadmap context, and are explicitly marked out of scope below.

---

# Purpose

Before building any data model, the analyst must understand where pilot data originates, how reliable it is, and which business processes generate it — even though, for this portfolio project, the underlying data will be synthesized rather than pulled from live systems. Treating the synthesis process with the same rigor as a real data discovery exercise is what makes the resulting analysis defensible.

---

# Pilot Data Source Summary

| Source ID | System | In Scope? | Business Function | Owner (Roleplay) | Refresh Frequency (Simulated) | Criticality to Pilot |
|---|---|---|---|---|---|---|
| DS-001 | Point of Sale (POS) | **Yes** | Store Sales | VP Store Operations | Daily | Critical |
| DS-003 | Warehouse Management System (WMS) | **Yes** | Inventory Levels & Transfers | VP Supply Chain | Daily | Critical |
| DS-007 | Product Master | **Yes** | Product/Category/Cost/Price | VP Merchandising | Daily | Critical |
| DS-002 | ERP (Finance & Purchasing) | No | General Ledger, AP/AR | CFO | — | Out of scope: pilot does not require financial statement integration |
| DS-004 | CRM | No | Customer Profiles, Loyalty | CMO | — | Out of scope: no customer-level analysis in pilot |
| DS-005 | E-Commerce Platform | No | Online Orders | VP Digital Commerce | — | Out of scope: in-store channel only |
| DS-006 | HRIS | No | Employee Data | VP HR | — | Out of scope: no labor analysis in pilot |
| DS-008 | Supplier Management | No | Vendor Contracts, Lead Times | Director of Procurement | — | Out of scope: no procurement-performance analysis in this phase |

---

# In-Scope Source Detail

## DS-001 — Point of Sale (POS)

**Why the pilot needs it:** Sales transaction data is what lets us detect the *effect* of a stockout — if a SKU's daily sales drop to zero while comparable stores/SKUs continue selling, that's evidence of lost sales, not just lack of demand.

**Data needed for pilot:**
- Transaction date, store ID, SKU, quantity sold, unit price

**Data NOT needed for pilot (present in real POS but excluded here):**
- Customer ID/loyalty linkage, payment method, cashier ID, discounts/promotions detail

---

## DS-003 — Warehouse Management System (WMS)

**Why the pilot needs it:** This is the core source — it's what actually measures inventory levels by store and by the regional DC, and what proves whether a stockout is a true shortage or a distribution problem (per FR-P07: comparing a store's stockout against pooled regional + DC inventory).

**Data needed for pilot:**
- Daily inventory snapshot: store ID (or DC ID), SKU, quantity on hand
- Transfer records between DC and stores (to understand replenishment timing/lead time)

**Data NOT needed for pilot:**
- Full 8-warehouse national network — only the 1 DC serving the Southwest pilot region
- Non-Electronics/Home Goods SKUs

---

## DS-007 — Product Master

**Why the pilot needs it:** Provides the category filter (Electronics/Home Goods only) and the cost/price data required to calculate margin-weighted stockout severity — the key insight from FR-P04 that not all stockouts are equally costly.

**Data needed for pilot:**
- SKU, product name, category, unit cost, retail price

**Data NOT needed for pilot:**
- Full 12-category product catalog — only Electronics/Home Goods SKUs

---

# Data Risks (Pilot-Relevant)

| Risk | Mitigation |
|---|---|
| Synthesized data doesn't reflect realistic seasonality/demand patterns | Build generation logic around known retail patterns (weekday/weekend variance, seasonal spikes) rather than uniform randomness |
| Store and DC identifiers inconsistent across simulated POS/WMS tables | Define a single, consistent store/DC ID scheme before generating any data |
| Product Master category field doesn't cleanly isolate Electronics/Home Goods | Explicitly filter/tag SKUs at generation time, not after the fact |

---

# Integration Overview (Pilot Version)

```
POS (sales) ─┐
             ├─→ Data Model (star schema) → Power BI Dashboard → Findings
WMS (inventory) ┘
Product Master (category/cost) ──┘
```

No live ETL pipeline is required for this pilot — data will be generated and loaded directly into the analytical data model, since there is no production source system to extract from.

---

# Success Criteria

This Data Source Inventory is complete when:

- All three in-scope sources have clearly defined fields needed for the pilot.
- Out-of-scope sources are explicitly justified, not simply omitted.
- The analyst can explain why each in-scope field is necessary — no field is included "just in case."
