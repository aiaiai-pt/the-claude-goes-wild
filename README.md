# Claude Team Config

Shared Claude Code configuration for team best-practice alignment. Contains
agents, commands, skills, and hooks that implement the **Steering Model** —
a product development methodology optimized for the AI agent age.

## What's Included

| Directory | Contents | Count |
|-----------|----------|-------|
| `CLAUDE.md` | Global instructions (communication style, TDD rules, design conventions) | 1 |
| `agents/` | Specialized agent personas (security, fullstack, data, cloud, SRE, design, etc.) | 18 |
| `commands/` | Legacy commands + orchestration commands (scan, orchestrate, status, memory, bootstrap) | 17 |
| `skills/` | Workflows and sub-workflows (LFG, DFG, QFG, XFG, scan, orchestrate, etc.) | 44 |
| `hooks/` | Enforcement hooks — quality gates, secret scanning, safety guards, nudges | 7 |
| `hooks-config.json` | Settings fragment to merge into your `~/.claude/settings.json` | 1 |
| `scripts/` | Automation scripts — local security scans, memory consolidation, project bootstrap | 3 |
| `templates/` | Agent memory templates — copied to projects via bootstrap | 12 |

## What's NOT Included (stays personal)

- `settings.json` / `settings.local.json` — your MCP servers, permissions, plugins
- `history.jsonl` — conversation history
- `projects/` — per-project overrides
- `session-env/`, `cache/`, `telemetry/` — ephemeral state

## Quick Start

```bash
# 1. Clone
git clone <repo-url> ~/claude-team-config

# 2. Install (creates symlinks into ~/.claude/)
cd ~/claude-team-config
./install.sh

# 3. Merge hooks config into your settings
#    Open hooks-config.json, copy the "hooks" section,
#    merge it into ~/.claude/settings.json

# 4. Install tool dependencies
brew install gitleaks jq
pip install ruff
npm install -g prettier

# 5. (Optional) Install scan tools for /scan and /orchestrate
pip install semgrep
brew install trivy
```

## How It Works

The install script creates **symlinks** from this repo into `~/.claude/`. This means:

- **Updates are instant**: `git pull` updates all team members' Claude configs
- **Personal additions are fine**: You can add your own agents/commands/skills
  alongside the shared ones (just don't name them the same)
- **Nothing is deleted**: Existing files are backed up before being replaced
- **Reversible**: Remove symlinks to disconnect; your backups are in `~/.claude/.backup/`

## Updating

```bash
cd ~/claude-team-config
git pull
# Symlinks already point here — changes take effect immediately.
# Only re-run install.sh if NEW files were added to the repo.
./install.sh
```

## Adding Your Own Content

Team members can add personal agents/commands/skills directly in `~/.claude/`.
Only content tracked in THIS repo gets shared. To share something new:

1. Add the file to this repo (follow the existing patterns)
2. Commit and push
3. Team members `git pull && ./install.sh`

## The Steering Model

This config implements 8 specialized processes across 6 phases:

```
SENSE → SHAPE → BET → BUILD → SHIP → LEARN
  │       │      │      │       │       │
  MFG    SFG    XFG   LFG/DFG  OFG    XFG
  OFG    SFG          QFG      SFG    MFG
  SFG                 SFG
  PFG                 MFG
```

**On-demand** (per bet): LFG, DFG, QFG, XFG
**Always-on** (daemons): OFG, SFG, PFG, MFG

See `the-steering-model.md` in the project repo for the full methodology.

## Hook Architecture

Two enforcement layers:

1. **Mandatory** (always runs): `secret-scan.sh`, `quality-gate.sh`, `bash-guard.sh`, `commit-guard.sh`, `sensitive-file-guard.sh`
2. **Nudges** (probabilistic): `explorational-nudge.sh` (12%), `process-nudge.sh` (8%)

Mandatory hooks block on failure. Nudges fire occasionally to suggest
alternative approaches or Steering Model processes you might invoke.

## Multi-Agent Orchestration

A gated pipeline for security scanning, code review, and spec review with
persistent agent memory across runs.

### Setup

```bash
# In your project directory:
/bootstrap    # Creates .agent-memory/, .agent-handoffs/, spec/
```

### Pipeline Commands

| Command | Description |
|---------|-------------|
| `/bootstrap` | One-time project scaffolding (memory dirs, handoffs, spec placeholder) |
| `/scan` | Scan-only cycle — runs Semgrep + Trivy, triages with AI, no code changes |
| `/orchestrate` | Full gated pipeline: scan, implement, Ralph-loop review, spec review |
| `/status` | Read-only check of all `.agent-handoffs/` files |
| `/memory` | Consolidate agent memory — merge duplicates, archive old entries |

### How It Works

1. **`/scan`** runs `fetch-local-scans.py` (Semgrep + Trivy + optional SonarQube),
   then the `security-analyst` agent triages findings against known CVEs and
   suppressions from `.agent-memory/security/`.

2. **`/orchestrate`** chains four phases with gates:
   - Analysis (scan + plan) → GATE 1 (plan approved?)
   - Implementation → Code Review (Ralph-loop) → GATE 2 (review approved?)
   - Spec Review (Ralph-loop) → Cleanup

3. **Agent memory** (`.agent-memory/`) persists across runs. Each agent reads
   relevant memory on startup and writes new learnings on completion. Memory
   entries use prefixes: `SEC-` (security), `ENG-` (engineering), `PRD-` (product).

4. **`/memory`** runs `consolidate-memory.py` to archive resolved entries older
   than 90 days and rebuild the memory index.
