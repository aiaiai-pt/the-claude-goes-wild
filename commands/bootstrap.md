---
name: bootstrap
description: Scaffold a project for multi-agent orchestration (memory, handoffs, spec)
---

Run the project bootstrap script to set up the multi-agent orchestration structure.

Execute: `bash ~/.claude/scripts/bootstrap-project.sh`

If the script is not found at `~/.claude/scripts/`, try `scripts/bootstrap-project.sh`
from the current directory.

This creates:
- `.agent-memory/` — persistent agent knowledge (from templates)
- `.agent-handoffs/` — ephemeral inter-agent communication
- `spec/requirements.md` — spec placeholder
- `.env.example` — environment variable template

The script is idempotent — safe to re-run.

After completion, remind the user to:
1. Copy `.env.example` to `.env` and fill in tokens (if using SonarQube)
2. Write acceptance criteria in `spec/requirements.md`
