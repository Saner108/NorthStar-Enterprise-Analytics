-- Purpose: Initialize the pilot database and set connection-level pragmas.
-- Business Requirement: FR-P01..FR-P07 (foundation for the entire pilot data model)
-- Business Rule(s): N/A (infrastructure)
-- Author: Claude Code, reviewed by Project Lead
-- Created Date: 2026-07-28
-- Dependencies: none (first script in the 001-016 sequence)
--
-- Engine note: This pilot targets SQLite (per SQL_Implementation_Plan.md Phase 1 —
-- "SQLite or Postgres ... either is appropriate at ~1.6M total rows"). SQLite has no
-- CREATE DATABASE statement; the database *is* the file the sqlite3 client opens, so
-- this script's job is to enable referential-integrity enforcement, which SQLite
-- leaves OFF by default. Foreign keys are enabled per-connection, so run_pipeline.py
-- also sets this pragma on its connection; it is stated here for a sqlite3-CLI user.

PRAGMA foreign_keys = ON;
