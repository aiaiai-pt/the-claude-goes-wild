#!/usr/bin/env python3
"""
consolidate-memory.py
---------------------
Merges duplicate memory entries, archives old resolved ones,
and rebuilds the index.

Usage:
  python scripts/consolidate-memory.py
  python scripts/consolidate-memory.py --root .agent-memory --ttl 90
  python scripts/consolidate-memory.py --dry-run

Recommended: monthly, or before major releases.
"""

import os
import re
import argparse
from datetime import datetime, timezone, timedelta


def parse_entries(text):
    return re.split(r"\n(?=### \[)", text)


def get_field(entry, field):
    m = re.search(rf"\*\*{field}\*\*:\s*(.+)", entry)
    return m.group(1).strip() if m else ""


def get_date(entry):
    raw = get_field(entry, "date")
    try:
        return datetime.fromisoformat(raw)
    except Exception:
        return datetime.min


def consolidate_file(filepath, archive_root, cutoff, dry_run):
    with open(filepath) as f:
        content = f.read()

    header_match = re.match(r"(#[^\n]+\n+<!--.*?-->)\n", content, re.DOTALL)
    header = (header_match.group(0) if header_match else "") + "\n"
    body = content[len(header) :]
    entries = [e for e in parse_entries(body) if e.strip()]

    keep, archive = [], []

    for entry in entries:
        status = get_field(entry, "status")
        date = get_date(entry)
        if status in ("resolved", "consolidated") and date < cutoff:
            archive.append(entry)
        else:
            keep.append(entry)

    if not dry_run:
        with open(filepath, "w") as f:
            f.write(header + "\n".join(keep))

        if archive:
            os.makedirs(archive_root, exist_ok=True)
            apath = os.path.join(archive_root, os.path.basename(filepath))
            with open(apath, "a") as f:
                f.write("\n" + "\n".join(archive))

    if archive:
        label = "[dry-run] Would archive" if dry_run else "Archived"
        count = len(archive)
        print(f"  {label} {count} entr{'y' if count == 1 else 'ies'} from {filepath}")

    return len(keep), len(archive)


def rebuild_index(memory_root, dry_run):
    lines = ["# Memory Index\n\n"]
    for root, dirs, files in os.walk(memory_root):
        dirs[:] = [d for d in dirs if d != "_archive" and d != "meta"]
        for fname in sorted(files):
            if not fname.endswith(".md") or fname == "README.md":
                continue
            fpath = os.path.join(root, fname)
            with open(fpath) as f:
                for line in f:
                    m = re.match(r"### \[([A-Z]+-\d{8}-\d+)\] (.+)", line)
                    if m:
                        lines.append(
                            f"- **{m.group(1)}** — {m.group(2).strip()} `{fpath}`\n"
                        )

    index_path = os.path.join(memory_root, "meta", "index.md")
    if not dry_run:
        os.makedirs(os.path.dirname(index_path), exist_ok=True)
        with open(index_path, "w") as f:
            f.writelines(lines)

    entry_count = len(lines) - 1
    label = "[dry-run] Would rebuild" if dry_run else "Rebuilt"
    print(f"  {label} index: {entry_count} entries")
    return entry_count


def main():
    parser = argparse.ArgumentParser(
        description="Consolidate agent memory: merge duplicates, archive old resolved entries, rebuild index.",
    )
    parser.add_argument(
        "--root",
        default=".agent-memory",
        help="Path to the agent memory directory (default: .agent-memory)",
    )
    parser.add_argument(
        "--ttl",
        type=int,
        default=90,
        help="Days before resolved/consolidated entries are archived (default: 90)",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Preview what would change without modifying files",
    )
    args = parser.parse_args()

    memory_root = args.root
    archive_root = os.path.join(memory_root, "_archive")
    cutoff = datetime.now() - timedelta(days=args.ttl)

    if not os.path.isdir(memory_root):
        print(f"Memory directory not found: {memory_root}")
        print("Run bootstrap-project.sh first to create the memory structure.")
        sys.exit(1)

    mode = "[DRY RUN] " if args.dry_run else ""
    print(f"{mode}Running memory consolidation...\n")

    total_kept = total_archived = 0
    for root, dirs, files in os.walk(memory_root):
        dirs[:] = [d for d in dirs if d != "_archive" and d != "meta"]
        for fname in files:
            if fname.endswith(".md") and fname != "README.md":
                k, a = consolidate_file(
                    os.path.join(root, fname), archive_root, cutoff, args.dry_run
                )
                total_kept += k
                total_archived += a

    rebuild_index(memory_root, args.dry_run)

    log_entry = (
        f"\n## Consolidation {datetime.now(timezone.utc).isoformat()}\n"
        f"- Active entries kept: {total_kept}\n"
        f"- Entries archived (resolved > {args.ttl}d): {total_archived}\n"
    )

    log_path = os.path.join(memory_root, "meta", "consolidation-log.md")
    if not args.dry_run:
        os.makedirs(os.path.dirname(log_path), exist_ok=True)
        with open(log_path, "a") as f:
            f.write(log_entry)

    print(log_entry)


if __name__ == "__main__":
    import sys

    main()
