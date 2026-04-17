---
description: >
  Validate architect process output for consistency. Checks that all required
  files exist, references are valid, and the process state is coherent. Profile-aware
  — when a platform profile is active, also lints canonical grammar, anti-patterns,
  and forbidden synonyms.
---

# /arch-validate — Validate Architect Output

Run the validation script:

```bash
python3 ~/.claude/scripts/validate-architect-output.py
```

(Falls back to `scripts/validate-architect-output.py` in the current repo if
the user-scoped version isn't found.)

## What it checks (always)

- State file exists and is valid JSON
- Pitch has required sections (Problem, Appetite, Solution Direction, No-Gos)
- ARCHITECTURE.md exists with Module Map and diagrams
- ADRs follow naming convention (`ADR-NNNN-kebab-title.md`) and have Status
- Module specs exist for all declared modules
- TEST-PLAN.md exists when solution type requires it (MVP+)
- Issues directory has manifest and component-versions
- DX reports exist after pipeline completion
- Milestone and component versions are registered

## What it checks (profile-aware — when `platform-grammar` skill is present)

- Forbidden synonym scan (e.g., `municipality_id`, `workspace` as tenant)
- ID prefix conformance (`inst_`, `tnt_`, `scp_`, `evt_`, `req_`, etc.)
- Naming conventions (tables `snake_case`, entity types `PascalCase`, events `PastTense`)
- Event envelope required keys on any `/v1/events` references
- API paths restricted to the enumerated set (if profile restricts)
- Bucket naming conformance (if profile defines a bucket layout)
- Anti-pattern detection (new module must not reinforce an AP)

The same validation can be wired as a Stop hook to run automatically after
every agent completes.
