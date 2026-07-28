# DATA DICTIONARY

Version: 1.0

Project:
NorthStar Retail Group
Inventory Visibility Pilot — Electronics & Home Goods, Southwest Region

Status: Draft
Scope Note: Trimmed from the full enterprise data model to the three in-scope source systems (POS, WMS, Product Master) identified in the Data Source Inventory. Customer/CRM data, e-commerce channels, and non-pilot categories are intentionally excluded.

---

# Purpose

Authoritative reference for every table and field used in the pilot's data model. Ensures every SQL query, Python script, and dashboard visual traces back to a clearly defined field — no ambiguity about what a column means or where it came from.

---

# Table: Sales_Transactions

**Business Purpose:** Records completed in-store sales for pilot region/category.
**Primary Key:** Transaction_ID
**Grain:** One row per line item per transaction (one SKU sold in one transaction = one row)
**Source:** DS-001 (POS), pilot-filtered

| Field | Data Type | Description | Business Rules | Null Allowed |
|---|---|---|---|---|
| Transaction_ID | Integer | Unique transaction identifier | Must be unique, never reused | No |
| Transaction_Date | Date | Date the sale occurred | Cannot be in the future | No |
| Store_ID | String | Store where sale occurred | Must exist in Store_Dimension; must be a pilot Southwest store | No |
| SKU | String | Product sold | Must exist in Product_Master; must be Electronics/Home Goods category | No |
| Quantity | Integer | Units sold | Must be > 0 | No |
| Unit_Price | Decimal | Price per unit at time of sale | Must be > $0.00 | No |
| Sales_Amount | Decimal | Quantity × Unit_Price | Derived field; cannot be negative | No |
| Sales_Channel | String | Fixed to "Retail Store" for this pilot | Only one allowed value in pilot scope | No |

**Fields intentionally excluded from enterprise version:** Customer_ID (no CRM in scope), Discount_Amount (not needed for stockout analysis), Payment_Method (not relevant to inventory visibility), all non-"Retail Store" channel values.

---

# Table: Inventory_Snapshot

**Business Purpose:** The core table for this pilot — daily inventory level by store (or DC) and SKU. This is what makes stockout detection and the FR-P07 distribution-vs-shortage comparison possible.
**Primary Key:** Composite (Snapshot_Date + Location_ID + SKU)
**Grain:** One row per location (store or DC) per SKU per day
**Source:** DS-003 (WMS), pilot-filtered

*Note: This table does not exist in the original enterprise Data Dictionary — the enterprise version prioritized sales/customer data and did not document inventory at daily grain. It was added here because it is essential to the pilot's core business question.*

| Field | Data Type | Description | Business Rules | Null Allowed |
|---|---|---|---|---|
| Snapshot_Date | Date | The date this inventory level reflects | One record per location/SKU/day | No |
| Location_ID | String | Store_ID or DC_ID | Must exist in Store_Dimension or represent the single pilot DC | No |
| Location_Type | String | "Store" or "Distribution_Center" | Only these two values | No |
| SKU | String | Product identifier | Must exist in Product_Master, Electronics/Home Goods only | No |
| Quantity_On_Hand | Integer | Units physically present at this location on this date | Must be ≥ 0 | No |

**Design decision documented:** Grain is a full daily snapshot (one row per location/SKU/day) rather than event-based/change-only logging. This was a deliberate trade-off: event-based logging is more storage-efficient and closer to how production WMS systems often work, but requires reconstructing point-in-time state via window functions (e.g., `LAG`), which adds complexity and risk for a solo, time-boxed pilot. Daily snapshot trades some storage efficiency for query simplicity and lower risk of a foundational bug in the core KPI. This trade-off should be stated explicitly if asked in review.

---

# Table: Product_Master

**Business Purpose:** Standardized product reference data, filtered to pilot category.
**Primary Key:** SKU
**Source:** DS-007, pilot-filtered

| Field | Data Type | Description | Business Rules | Null Allowed |
|---|---|---|---|---|
| SKU | String | Unique product identifier | Must be unique | No |
| Product_Name | String | Product description | — | No |
| Category | String | Fixed to "Electronics" or "Home Goods" for this pilot | Only these two values in pilot scope | No |
| Cost | Decimal | Unit acquisition cost | Must be > $0.00; used for margin-weighted stockout analysis (FR-P04) | No |
| Retail_Price | Decimal | Current selling price | Must be ≥ Cost | No |

**Fields excluded from enterprise version:** Brand, Department (not needed at pilot scale — single category, no cross-department reporting).

---

# Table: Store_Dimension

**Business Purpose:** Reference data for pilot stores and the supporting DC.
**Primary Key:** Store_ID (or DC_ID)
**Source:** Derived/synthesized for pilot

| Field | Data Type | Description | Business Rules | Null Allowed |
|---|---|---|---|---|
| Store_ID | String | Unique store or DC identifier | Must be unique | No |
| Store_Name | String | Display name | — | No |
| Location_Type | String | "Store" or "Distribution_Center" | Only these two values | No |
| Region | String | Fixed to "Southwest" for this pilot | Only one value in pilot scope | No |
| State | String | State abbreviation | Must be within Southwest region states | No |
| Store_Size | String | Small/Medium/Large (affects assumed SKU capacity) | — | Yes |

**Fields excluded from enterprise version:** Opening_Date, Store_Manager (name-level detail not needed for this analysis).

---

# Naming Standards

- Tables: PascalCase with underscores (e.g., `Sales_Transactions`)
- Columns: Clear, descriptive, singular (e.g., `Quantity_On_Hand`, not `QtyOH`)
- No undocumented fields permitted — every field in the schema must appear in this dictionary before use in SQL/Power BI

---

# Data Quality Expectations

Since data is synthesized rather than pulled from a live system, "data quality" here means the generation logic must satisfy:

- **Referential integrity:** every Store_ID/SKU referenced in Sales_Transactions and Inventory_Snapshot must exist in Store_Dimension/Product_Master
- **Realistic patterns:** sales and inventory figures should reflect plausible retail seasonality, not pure randomness
- **Internal consistency:** a store cannot show inventory increasing without a corresponding transfer/receipt logic, and cannot show sales exceeding available inventory without that being a deliberately modeled stockout scenario

---

# Change Log

| Version | Date | Author | Description |
|---|---|---|---|
| 1.0 | 2026-07-28 | Project Lead | Initial pilot-scoped Data Dictionary; added Inventory_Snapshot table not present in enterprise version |

---

# Definition of Done

This Data Dictionary is complete when every table/field used anywhere in the pilot's SQL, Python, or Power BI work is documented here first — no field should appear in code before it appears in this dictionary.
