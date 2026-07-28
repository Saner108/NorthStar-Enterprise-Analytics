-- Purpose: Create the store/location dimension (pilot stores + the regional DC).
-- Business Requirement: FR-P01 (store-level in-stock rate), FR-P07 (regional pooling)
-- Business Rule(s): BR-013 (store vs. DC scope)
-- Author: Claude Code, reviewed by Project Lead
-- Created Date: 2026-07-28
-- Dependencies: 001_Create_Database.sql
--
-- Design (Star_Schema.md): the single regional distribution center is stored as a row
-- here with Location_Type = 'Distribution_Center' (NOT a separate dimension). This lets
-- Fact_Inventory_Snapshot reference the DC through the same Store_Key foreign key as
-- stores, which is exactly what BR-008b pooled-inventory comparison needs. Store-level
-- in-stock rate (KPI-P01) filters Location_Type = 'Store' to exclude the DC.

CREATE TABLE Dim_Store (
    Store_Key      INTEGER PRIMARY KEY,               -- surrogate
    Store_ID       TEXT    NOT NULL UNIQUE,           -- natural/business key
    Store_Name     TEXT    NOT NULL,
    Location_Type  TEXT    NOT NULL CHECK (Location_Type IN ('Store', 'Distribution_Center')),
    Region         TEXT    NOT NULL,                  -- fixed 'Southwest' for this pilot
    State          TEXT    NOT NULL,
    Store_Size     TEXT                                -- Small/Medium/Large (nullable per Data Dictionary)
);
