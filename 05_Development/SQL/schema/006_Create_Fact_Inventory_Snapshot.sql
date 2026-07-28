-- Purpose: Create Fact_Inventory_Snapshot (grain: one row per location per SKU per day).
-- Business Requirement: FR-P03 (out-of-stock flag), FR-P07 (distribution vs. shortage)
-- Business Rule(s): BR-007 (sellable on-hand), BR-008/8a/8b (stockout logic downstream)
-- Author: Claude Code, reviewed by Project Lead
-- Created Date: 2026-07-28
-- Dependencies: 002_Create_Dim_Date, 003_Create_Dim_Product, 004_Create_Dim_Store
--
-- Design (Star_Schema.md / Data_Dictionary.md): the pilot's core table. DAILY SNAPSHOT
-- grain, not event-based change logging (Decision 2) — a deliberate risk-reduction
-- trade-off so the core KPIs never depend on reconstructing point-in-time state via
-- window functions. Store_Key includes the regional DC so BR-008b can pool across
-- stores AND the DC through one consistent join. A surrogate Snapshot_Key is used with
-- a UNIQUE(Date_Key, Store_Key, Product_Key) constraint to enforce the one-row-per-
-- location-per-SKU-per-day grain (Fact_Table_Specification.md permits either form).

CREATE TABLE Fact_Inventory_Snapshot (
    Snapshot_Key       INTEGER PRIMARY KEY,           -- surrogate
    Date_Key           INTEGER NOT NULL REFERENCES Dim_Date(Date_Key),
    Store_Key          INTEGER NOT NULL REFERENCES Dim_Store(Store_Key),
    Product_Key        INTEGER NOT NULL REFERENCES Dim_Product(Product_Key),
    Quantity_On_Hand   INTEGER NOT NULL CHECK (Quantity_On_Hand >= 0),
    UNIQUE (Date_Key, Store_Key, Product_Key)         -- enforces the snapshot grain
);

-- Supports BR-008b pooled-inventory comparison (same Product_Key + Date_Key across
-- locations) and per-SKU trend reads. Standard FK/lookup indexes only.
CREATE INDEX ix_Fact_Inv_Product_Date ON Fact_Inventory_Snapshot (Product_Key, Date_Key);
CREATE INDEX ix_Fact_Inv_Store        ON Fact_Inventory_Snapshot (Store_Key);
CREATE INDEX ix_Fact_Inv_Date         ON Fact_Inventory_Snapshot (Date_Key);
