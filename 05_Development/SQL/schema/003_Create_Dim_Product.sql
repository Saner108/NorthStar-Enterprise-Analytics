-- Purpose: Create the product dimension WITH SCD Type 2 structure on Category.
-- Business Requirement: FR-P06 (category-level rollups), FR-P04 (margin weighting)
-- Business Rule(s): BR-011, BR-012 (category boundary), BR-014/BR-015 (margin)
-- Author: Claude Code, reviewed by Project Lead
-- Created Date: 2026-07-28
-- Dependencies: 001_Create_Database.sql
--
-- CRITICAL DESIGN (IMPLEMENTATION_BRIEF.md Decision 4):
--   Dim_Product implements SCD Type 2 on the Category attribute ONLY, and only for
--   the single deliberately-reclassified SKU (Electronics -> Home Goods mid-year).
--   That SKU therefore has TWO rows: same SKU, two Product_Keys, non-overlapping
--   Effective_Start_Date / Effective_End_Date ranges. Product_Key is the surrogate
--   (unique per VERSION); SKU is the natural/business key (shared across versions).
--   Every other attribute on every SKU is treated as static for the 12-month window.
--
--   Effective_End_Date is NULL only for the current/active version — this is the one
--   intentional NULL in the schema (SQL_Development_Standards.md, NULL Handling).

CREATE TABLE Dim_Product (
    Product_Key           INTEGER PRIMARY KEY,        -- surrogate, per VERSION
    SKU                   TEXT    NOT NULL,           -- natural key, shared across versions
    Product_Name          TEXT    NOT NULL,
    Category              TEXT    NOT NULL CHECK (Category IN ('Electronics', 'Home Goods')),
    Unit_Cost             REAL    NOT NULL CHECK (Unit_Cost > 0),
    Retail_Price          REAL    NOT NULL CHECK (Retail_Price >= Unit_Cost),
    Effective_Start_Date  TEXT    NOT NULL,
    Effective_End_Date    TEXT,                        -- NULL = current/active version
    Is_Current            INTEGER NOT NULL CHECK (Is_Current IN (0, 1))
);

-- Supports SCD Type 2 lookups by natural key + effective date.
CREATE INDEX ix_Dim_Product_SKU_Effective
    ON Dim_Product (SKU, Effective_Start_Date);
