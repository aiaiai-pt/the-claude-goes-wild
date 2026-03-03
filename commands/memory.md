---
name: memory
description: Consolidate agent memory — merge duplicates, archive old entries, rebuild index
argument-hint: "[--dry-run] [--ttl N]"
---

Run memory consolidation on this project's `.agent-memory/` directory.

Execute: `python ~/.claude/scripts/consolidate-memory.py $ARGUMENTS`

If the script is not found at `~/.claude/scripts/`, try `scripts/consolidate-memory.py`
from the current directory.

After it completes, report:
- How many entries were kept
- How many were archived
- Any errors encountered

Then show the current active entry count per memory file.
