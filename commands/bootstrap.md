---
name: bootstrap
description: Scaffold a project for multi-agent orchestration (memory, handoffs, spec, architect). Optionally autoruns /architect if given a problem description.
argument-hint: "[optional problem description — triggers /architect]"
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

After that, scaffold the architect process directories:

```bash
mkdir -p docs/architect-process/{pitches,architecture/{c4,adrs,modules},issues,dx-reports}
```

If `docs/architect-process/.architect-state.json` doesn't exist, initialize it
with the skeleton from `/arch-init` (copy the logic there).

The script is idempotent — safe to re-run.

## Autonomous Mode

If `$ARGUMENTS` is **non-empty**, treat it as a problem description and
automatically invoke `/architect $ARGUMENTS` after scaffolding completes.

This gives you a single-command autonomous flow:

```
/bootstrap "We need a fire surveillance monitoring system for rural municipalities"
```

The bootstrap scaffolds the directories, then `/architect` runs the full pipeline.

## Post-bootstrap reminder

If the user invoked `/bootstrap` without arguments, remind them to:
1. Copy `.env.example` to `.env` and fill in tokens (if using SonarQube)
2. Write acceptance criteria in `spec/requirements.md`
3. Run `/architect "<problem>"` to start the architect pipeline, or run individual
   commands (`/shape`, `/decompose`, `/spec-module`, etc.) for granular control
