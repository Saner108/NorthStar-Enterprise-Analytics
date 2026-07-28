-- Purpose: Load Fact_Sales from the generated CSV staging file.
-- Business Requirement: FR-P04, FR-P05
-- Business Rule(s): BR-002 (Sales_Amount = Quantity_Sold x Unit_Price, precomputed)
-- Author: Claude Code, reviewed by Project Lead
-- Created Date: 2026-07-28
-- Dependencies: 005_Create_Fact_Sales, 007_Load_Dimensions (dimensions loaded first),
--   generated fact_sales.csv. Foreign keys (Date_Key/Store_Key/Product_Key) already
--   resolved to surrogate values at generation time; Product_Key reflects the SCD
--   Type 2 version effective on each transaction date.

.mode csv
.import --skip 1 data/staging/fact_sales.csv Fact_Sales
