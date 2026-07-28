-- Purpose: Create Fact_Sales (grain: one row per SKU per completed transaction).
-- Business Requirement: FR-P04 (baseline sales for lost-margin), FR-P05 (revenue)
-- Business Rule(s): BR-001 (completed sale), BR-002 (Sales_Amount = Qty x Unit_Price)
-- Author: Claude Code, reviewed by Project Lead
-- Created Date: 2026-07-28
-- Dependencies: 002_Create_Dim_Date, 003_Create_Dim_Product, 004_Create_Dim_Store
--
-- Design (Star_Schema.md / Fact_Table_Specification.md): one of two fact tables, kept
-- separate from Fact_Inventory_Snapshot because they answer different questions at
-- different grains (Decision 1). Foreign keys carry surrogate dimension keys only —
-- no descriptive text lives in the fact table. Product_Key is resolved to the SCD
-- Type 2 version effective on the transaction date at load time (Source_to_Target_
-- Mapping.md), so query-time joins to Dim_Product use Product_Key directly.

CREATE TABLE Fact_Sales (
    Sales_Key      INTEGER PRIMARY KEY,               -- surrogate
    Date_Key       INTEGER NOT NULL REFERENCES Dim_Date(Date_Key),
    Store_Key      INTEGER NOT NULL REFERENCES Dim_Store(Store_Key),
    Product_Key    INTEGER NOT NULL REFERENCES Dim_Product(Product_Key),
    Quantity_Sold  INTEGER NOT NULL CHECK (Quantity_Sold > 0),
    Unit_Price     REAL    NOT NULL CHECK (Unit_Price > 0),
    Sales_Amount   REAL    NOT NULL CHECK (Sales_Amount >= 0)
);

-- Foreign-key indexes (good practice at any scale, cost nothing to include —
-- Fact_Table_Specification.md). No partitioning/custom indexing at this volume.
CREATE INDEX ix_Fact_Sales_Date    ON Fact_Sales (Date_Key);
CREATE INDEX ix_Fact_Sales_Store   ON Fact_Sales (Store_Key);
CREATE INDEX ix_Fact_Sales_Product ON Fact_Sales (Product_Key);
