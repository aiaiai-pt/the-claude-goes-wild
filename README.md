# Claude Team Config

Shared Claude Code configuration for team best-practice alignment. Contains
agents, commands, skills, and hooks that implement the **Steering Model** —
a product development methodology optimized for the AI agent age — plus a
full **architect pipeline** (discover → shape → specify → test-plan → publish → report).

## What's Included

| Directory | Contents | Count |
|-----------|----------|-------|
| `CLAUDE.md` | Global instructions (communication style, TDD rules, design conventions) | 1 |
| `agents/` | Specialized agent personas (security, fullstack, data, cloud, SRE, design, architect) | 25 |
| `commands/` | Orchestration + architect commands (scan, orchestrate, status, memory, bootstrap, architect, shape, …) | 26 |
| `skills/` | Generic workflows + sub-workflows (LFG, DFG, QFG, XFG, problem-discovery, system-architecture, test-strategy, …) | 52 |
| `hooks/` | Enforcement hooks — quality gates, secret scanning, safety guards, nudges | 7 |
| `hooks-config.json` | Settings fragment to merge into your `~/.claude/settings.json` | 1 |
| `scripts/` | Automation scripts — local scans, memory consolidation, project bootstrap, architect validation | 4 |
| `templates/` | Agent memory templates — copied to projects via bootstrap | 12 |
| `profiles/` | **Team-specific stack profiles** (overlay on top of the generic config) | ubiwhere |

## What's NOT Included (stays personal)

- `settings.json` / `settings.local.json` — your MCP servers, permissions, plugins
- `history.jsonl` — conversation history
- `projects/` — per-project overrides
- `session-env/`, `cache/`, `telemetry/` — ephemeral state

## Quick Start

```bash
# 1. Clone
git clone <repo-url> ~/claude-team-config

# 2. Install the generic team config (creates symlinks into ~/.claude/)
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

# 6. (Optional) Install a profile for stack-specific conventions
./profiles/ubiwhere/install.sh     # for UBP work
```

## How It Works

The install script creates **symlinks** from this repo into `~/.claude/`. This means:

- **Updates are instant**: `git pull` updates all team members' Claude configs
- **Personal additions are fine**: You can add your own agents/commands/skills
  alongside the shared ones (just don't name them the same)
- **Nothing is deleted**: Existing files are backed up before being replaced
- **Reversible**: Remove symlinks to disconnect; your backups are in `~/.claude/.backup/`

### Skill directories (preserving references/ and scripts/)

The install script symlinks each `skills/<name>/` directory **as-is**, so any
`references/` or `scripts/` subdirectories inside the skill are preserved. This
matters for skills like `issue-publishing` (ships with tracker publish scripts)
and `platform-stack` (ships with `references/generic-stack-reference.md` plus
any profile overrides).

## Updating

```bash
cd ~/claude-team-config
git pull
# Symlinks already point here — changes take effect immediately.
# Only re-run install.sh if NEW files were added to the repo.
./install.sh
```

## Profiles — Team-specific stack conventions

The generic config ships stack-agnostic skills plus a `platform-stack` **shell**
that profiles override. Install one profile at a time.

```bash
# Install the Ubiwhere profile on top of the generic config
./profiles/ubiwhere/install.sh

# Check what's active
cat ~/.claude/.active-profiles

# Revert to generic
./profiles/ubiwhere/uninstall.sh
```

See `profiles/README.md` for details and `profiles/ubiwhere/README.md` for what
the Ubiwhere profile provides (medallion stack, Keycloak+UMS+SpiceDB, TanStack
Start + schema-renderer, canonical grammar, anti-patterns, gap IDs, bucket
layout).

### Create a new profile

See `skills/platform-stack/CUSTOMIZING.md` — the short version:

1. Create `profiles/my-team/` with `install.sh`, `uninstall.sh`, and
   `skills/platform-stack/` containing your team's canonical stack references
2. Install.sh swaps the symlink for `platform-stack` and writes
   `~/.claude/.active-profiles`

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

## The Architect Pipeline

A multi-phase, multi-agent workflow for going from problem to published
actionable issues: **discover → shape → specify → test-plan → publish → report**.

### Commands

| Command | What It Does | When to Use |
|---------|-------------|-------------|
| `/architect` | Full pipeline (all phases) | Starting a new project from scratch |
| `/shape` | Discovery + Architecture only | Shaping before a betting table |
| `/decompose` | Architecture from existing pitch | Pitch already exists |
| `/spec-module M-03` | Deep-dive one module | Iterating on a specific module |
| `/test-plan` | Design test strategy and CI/CD pipeline | After specs, or standalone for existing systems |
| `/publish-issues` | Publish to Linear/GitLab/GitHub with milestones + versions | After specs + test plan complete |
| `/dx-report` | Generate leadership/CTO report | After any phase, for visibility |
| `/arch-init` | Bootstrap architect directory structure | Once at project start |
| `/arch-validate` | Check output consistency (profile-aware) | Anytime |

### Agents

| Agent | Model | Role |
|-------|-------|------|
| `architect-lead` | Opus | Orchestrator — drives the pipeline |
| `problem-analyst` | Sonnet | Interviews users, writes Shape Up pitches |
| `system-designer` | Opus | C4 diagrams, ADRs, module decomposition |
| `module-specifier` | Sonnet | Feature specs, API contracts, data models |
| `test-architect` | Sonnet | Test strategy, data quality gates, CI/CD test pipeline |
| `issue-writer` | Sonnet | Publishes issues to Linear/GitLab/GitHub |
| `dx-reporter` | Sonnet | Leadership reports and DX briefs |

### Skills (Progressive Disclosure)

| Skill | Purpose |
|-------|-----------------|
| `problem-discovery` | Interview framework, appetite calibration, pitch template |
| `system-architecture` | C4 Mermaid templates, MADR ADR template |
| `module-specification` | Module template, feature template, sizing guide |
| `test-strategy` | Test pyramid, data quality gates, tool recommendations |
| `issue-publishing` | Linear/GitLab/GitHub publish scripts, label taxonomy, versioning |
| `dx-reporting` | Leadership report templates (brief, readiness, summary) |
| `architecture-governance` | Universal governance rules |
| `platform-stack` | **Shell** — canonical stack reference. Profiles override this. |

### Autonomous flow

```
/bootstrap "<problem>"    # Scaffolds everything, then autoruns /architect
```

### Output structure

```
docs/architect-process/
├── .architect-state.json           # Process state (resumable)
├── pitches/                         # Shape Up pitches
├── architecture/
│   ├── ARCHITECTURE.md             # Overview
│   ├── TEST-PLAN.md
│   ├── c4/                          # C1 + C2 Mermaid diagrams
│   ├── adrs/                        # MADR ADRs
│   └── modules/                     # Per-module SPEC.md
├── issues/                          # manifest.json, index.md, dependency-graph.mermaid
└── dx-reports/                      # Leadership briefs
```

## Multi-Agent Orchestration (pre-architect pipeline)

A gated pipeline for security scanning, code review, and spec review with
persistent agent memory across runs.

### Setup

```bash
# In your project directory:
/bootstrap    # Creates .agent-memory/, .agent-handoffs/, spec/, docs/architect-process/
```

### Pipeline Commands

| Command | Description |
|---------|-------------|
| `/bootstrap [prompt]` | One-time project scaffolding. With a prompt, autoruns `/architect`. |
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

## Hook Architecture

Two enforcement layers:

1. **Mandatory** (always runs): `secret-scan.sh`, `quality-gate.sh`, `bash-guard.sh`, `commit-guard.sh`, `sensitive-file-guard.sh`
2. **Nudges** (probabilistic): `explorational-nudge.sh` (12%), `process-nudge.sh` (8%)

Mandatory hooks block on failure. Nudges fire occasionally to suggest
alternative approaches or Steering Model processes you might invoke.
