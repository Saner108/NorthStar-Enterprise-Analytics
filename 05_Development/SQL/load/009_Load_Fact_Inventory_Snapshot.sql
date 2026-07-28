-- Purpose: Load Fact_Inventory_Snapshot from the generated CSV staging file.
-- Business Requirement: FR-P03, FR-P07
-- Business Rule(s): BR-007 (sellable on-hand); BR-008/8a/8b applied at query time
-- Author: Claude Code, reviewed by Project Lead
-- Created Date: 2026-07-28
-- Dependencies: 006_Create_Fact_Inventory_Snapshot, 007_Load_Dimensions,
--   generated fact_inventory_snapshot.csv (~1.26M rows). Surrogate foreign keys
--   already resolved at generation time (Product_Key = SCD Type 2 effective version).

.mode csv
.import --skip 1 data/staging/fact_inventory_snapshot.csv Fact_Inventory_Snapshot
