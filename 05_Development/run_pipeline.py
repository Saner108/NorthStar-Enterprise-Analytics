#!/usr/bin/env python3
"""
NorthStar Retail Group — Inventory Visibility Pilot
End-to-end pipeline runner (generation -> create -> load -> validate -> analyze -> views)

This single entry point executes the numbered SQL scripts (001-016) in order against a
fresh SQLite database, driving the whole pipeline described in
05_Development/SQL_Implementation_Plan.md and Data_Generation_Pipeline_Design.md.

Why a Python runner instead of piping to the sqlite3 CLI:
    The load scripts (007-009) use SQLite's native `.import` dot-command — the idiomatic
    way a sqlite3-CLI user loads a CSV. Some environments (including this one) ship the
    Python sqlite3 *module* but not the sqlite3 *CLI*. This runner therefore includes a
    tiny shim that honors the same `.import` / `.mode` dot-commands the .sql files use,
    so the exact same scripts run unmodified either via:
        sqlite3 northstar_pilot.db < <each script in order>     (CLI)
    or:
        python3 run_pipeline.py                                  (this runner)

Standard library only.

Usage:
    python3 run_pipeline.py [--seed 42] [--db data/northstar_pilot.db] [--skip-generation]
"""

import argparse
import csv
import os
import sqlite3
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))          # 05_Development
SQL_DIR = os.path.join(HERE, "SQL")
DEFAULT_DB = os.path.join(HERE, "data", "northstar_pilot.db")
STAGING_DIR = os.path.join(HERE, "data", "staging")

# Scripts whose single SELECT result should be printed as a table.
CAPTURE_SCRIPTS = {"010", "011", "012", "013", "014", "015"}
# How many rows to print for large KPI result sets (010 & summaries print in full).
PRINT_ROW_LIMIT = 12


# ---------------------------------------------------------------------------
# Dot-command shim (subset of the sqlite3 CLI, enough for this pilot's scripts)
# ---------------------------------------------------------------------------
def handle_dot_command(conn, line, base_dir):
    """Interpret a `.mode` / `.import` / `.print` dot-command line."""
    parts = line.strip().split()
    cmd = parts[0].lower()

    if cmd == ".mode" or cmd == ".headers" or cmd == ".separator":
        return  # CSV mode is implicit in this loader; nothing to configure

    if cmd == ".print":
        print(" ".join(parts[1:]).strip('"'))
        return

    if cmd == ".import":
        args = parts[1:]
        skip = 0
        positional = []
        i = 0
        while i < len(args):
            a = args[i]
            if a == "--skip":
                skip = int(args[i + 1]); i += 2; continue
            if a in ("--csv", "-csv"):
                i += 1; continue
            positional.append(a); i += 1
        if len(positional) != 2:
            raise ValueError(f"Unsupported .import syntax: {line}")
        csv_path, table = positional
        full_path = csv_path if os.path.isabs(csv_path) else os.path.join(base_dir, csv_path)
        _bulk_import_csv(conn, full_path, table, skip)
        return

    raise ValueError(f"Unsupported dot-command: {line}")


def _bulk_import_csv(conn, path, table, skip, batch_size=50000):
    """Load a CSV into an existing table, converting '' to NULL. Chunked for memory."""
    if not os.path.exists(path):
        raise FileNotFoundError(
            f"Staging file not found: {path}\n"
            f"Run the generator first (python3 generation/generate_pilot_data.py) "
            f"or invoke run_pipeline.py without --skip-generation.")
    inserted = 0
    with open(path, newline="") as f:
        reader = csv.reader(f)
        for _ in range(skip):
            next(reader, None)
        batch = []
        ncols = None
        insert_sql = None
        for row in reader:
            if ncols is None:
                ncols = len(row)
                insert_sql = f"INSERT INTO {table} VALUES ({','.join('?' * ncols)})"
            batch.append([(v if v != "" else None) for v in row])
            if len(batch) >= batch_size:
                conn.executemany(insert_sql, batch)
                inserted += len(batch)
                batch = []
        if batch:
            conn.executemany(insert_sql, batch)
            inserted += len(batch)
    conn.commit()
    print(f"    loaded {inserted:,} rows into {table}")


# ---------------------------------------------------------------------------
# Script execution
# ---------------------------------------------------------------------------
def script_number(path):
    return os.path.basename(path)[:3]


def collect_scripts(sql_dir):
    scripts = []
    for root, _dirs, files in os.walk(sql_dir):
        for name in files:
            if name.endswith(".sql"):
                scripts.append(os.path.join(root, name))
    scripts.sort(key=lambda p: os.path.basename(p))   # numeric prefix ordering
    return scripts


def run_exec_script(conn, path, base_dir):
    """Execute a non-capturing script (DDL / load / views), honoring dot-commands."""
    with open(path) as f:
        lines = f.readlines()
    buffer = []

    def flush():
        sql = "".join(buffer).strip()
        if sql:
            conn.executescript(sql)
        buffer.clear()

    for line in lines:
        if line.lstrip().startswith("."):
            flush()
            handle_dot_command(conn, line, base_dir)
        else:
            buffer.append(line)
    flush()
    conn.commit()


def run_capture_script(conn, path):
    """Execute a single-statement query script and return (columns, rows)."""
    with open(path) as f:
        sql = f.read()
    cur = conn.execute(sql)
    cols = [d[0] for d in cur.description]
    rows = cur.fetchall()
    return cols, rows


def print_table(cols, rows, limit=None):
    shown = rows if limit is None else rows[:limit]
    widths = [len(c) for c in cols]
    for r in shown:
        for i, v in enumerate(r):
            widths[i] = max(widths[i], len(_fmt(v)))
    line = "  " + " | ".join(c.ljust(widths[i]) for i, c in enumerate(cols))
    print(line)
    print("  " + "-+-".join("-" * widths[i] for i in range(len(cols))))
    for r in shown:
        print("  " + " | ".join(_fmt(v).ljust(widths[i]) for i, v in enumerate(r)))
    if limit is not None and len(rows) > limit:
        print(f"  ... ({len(rows):,} rows total, showing first {limit})")


def _fmt(v):
    if v is None:
        return "NULL"
    if isinstance(v, float):
        return f"{v:.4f}".rstrip("0").rstrip(".") if v != int(v) else str(int(v))
    return str(v)


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
def main():
    parser = argparse.ArgumentParser(description="Run the NorthStar pilot pipeline.")
    parser.add_argument("--db", default=DEFAULT_DB, help="SQLite database file path.")
    parser.add_argument("--seed", type=int, default=42, help="Generation random seed.")
    parser.add_argument("--skip-generation", action="store_true",
                        help="Reuse existing CSV staging files instead of regenerating.")
    args = parser.parse_args()

    t0 = time.time()

    # Stage 1 — generation ------------------------------------------------
    if not args.skip_generation:
        print("== Stage 1: Generate synthetic data ==")
        sys.path.insert(0, os.path.join(HERE, "generation"))
        import generate_pilot_data
        generate_pilot_data.generate(STAGING_DIR, args.seed)
    else:
        print("== Stage 1: Skipped (reusing existing staging CSVs) ==")
    print()

    # Fresh database ------------------------------------------------------
    os.makedirs(os.path.dirname(args.db), exist_ok=True)
    if os.path.exists(args.db):
        os.remove(args.db)
    conn = sqlite3.connect(args.db)
    conn.execute("PRAGMA foreign_keys = ON;")       # enforce referential integrity
    conn.execute("PRAGMA journal_mode = MEMORY;")   # load-time speed (not a schema change)
    conn.execute("PRAGMA synchronous = OFF;")

    # Stages 2-5 — run numbered scripts in order --------------------------
    scripts = collect_scripts(SQL_DIR)
    validation_failed = False

    for path in scripts:
        num = script_number(path)
        rel = os.path.relpath(path, HERE)
        print(f"== {num}: {os.path.basename(path)} ==")
        if num in CAPTURE_SCRIPTS:
            cols, rows = run_capture_script(conn, path)
            if num == "010":
                print_table(cols, rows)                       # full validation table
                fails = [r for r in rows if r[-1] == "FAIL"]
                if fails:
                    validation_failed = True
                    print(f"  >>> {len(fails)} validation check(s) FAILED")
                else:
                    print(f"  >>> all {len(rows)} validation checks PASSED")
            else:
                print_table(cols, rows, limit=PRINT_ROW_LIMIT)
        else:
            run_exec_script(conn, path, HERE)
            print("  done")
        print()

    conn.close()

    elapsed = time.time() - t0
    print(f"Pipeline finished in {elapsed:.1f}s. Database: {os.path.relpath(args.db, HERE)}")
    if validation_failed:
        print("RESULT: FAIL — one or more Phase 2 validation checks did not pass.")
        sys.exit(1)
    print("RESULT: PASS — all Phase 2 validation checks passed.")


if __name__ == "__main__":
    main()
