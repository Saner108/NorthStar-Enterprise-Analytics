-- Purpose: Create the calendar dimension shared by both fact tables.
-- Business Requirement: FR-P05 (12-month trend), FR-P01 (in-stock rate over time)
-- Business Rule(s): BR-003 (revenue attributed to Transaction_Date)
-- Author: Claude Code, reviewed by Project Lead
-- Created Date: 2026-07-28
-- Dependencies: 001_Create_Database.sql
--
-- Design: standard calendar dimension per Dimension_Table_Specifications.md.
-- Surrogate Date_Key is a YYYYMMDD integer (business key = Full_Date).
-- Fiscal-calendar and holiday attributes are intentionally omitted (not required
-- for this pilot's 12-month trend scope — see Star_Schema.md).

CREATE TABLE Dim_Date (
    Date_Key           INTEGER PRIMARY KEY,          -- YYYYMMDD surrogate
    Full_Date          TEXT    NOT NULL,             -- ISO business key
    Day_Name           TEXT    NOT NULL,
    Day_Number         INTEGER NOT NULL,
    Week_Number        INTEGER NOT NULL,
    Month              INTEGER NOT NULL,
    Month_Name         TEXT    NOT NULL,
    Quarter            INTEGER NOT NULL,
    Year               INTEGER NOT NULL,
    Weekend_Indicator  INTEGER NOT NULL CHECK (Weekend_Indicator IN (0, 1))
);
