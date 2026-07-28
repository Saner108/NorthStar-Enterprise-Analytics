-- Purpose: Load the three dimension tables from the generated CSV staging files.
-- Business Requirement: FR-P01..FR-P07 (dimensions underpin every KPI)
-- Business Rule(s): BR-012 (category), BR-013 (store/DC), SCD Type 2 (Dim_Product)
-- Author: Claude Code, reviewed by Project Lead
-- Created Date: 2026-07-28
-- Dependencies: 002/003/004 (tables), generated CSVs in ../data/staging
--   Product_Key is resolved to the SCD Type 2 effective version at GENERATION time
--   (Source_to_Target_Mapping.md), so no effective-date logic runs at load time.
--
-- Load order (Data_Generation_Pipeline_Design.md Stage 5): DIMENSIONS FIRST, then the
-- fact tables (008, 009) — fact rows reference dimension surrogate keys, which must
-- already exist. Empty Effective_End_Date cells load as NULL (current version).
--
-- These `.import` dot-commands are the SQLite CLI's native CSV loader. run_pipeline.py
-- honors the same commands in environments without the sqlite3 CLI (see its shim),
-- so `sqlite3 northstar_pilot.db < 007_Load_Dimensions.sql` and the Python runner
-- produce identical loads. Paths are relative to 05_Development (run from there).

.mode csv
.import --skip 1 data/staging/dim_date.csv Dim_Date
.import --skip 1 data/staging/dim_store.csv Dim_Store
.import --skip 1 data/staging/dim_product.csv Dim_Product
