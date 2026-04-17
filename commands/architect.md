---
description: >
  Full software architect process: discover → shape → specify → test-plan → publish → report.
  Run this when starting a new project, feature, or platform capability from scratch.
argument-hint: "<problem description>"
---

# /architect — Full Architecture Process

Full multi-phase, multi-agent architect pipeline.

## Pre-flight

1. Check if `docs/architect-process/.architect-state.json` exists. If it does,
   ask the user: "There's an existing architect session for **{project_name}**.
   Resume it or start fresh?"

2. If starting fresh, scaffold:
   ```
   docs/architect-process/
   ├── pitches/
   ├── architecture/
   │   ├── c4/
   │   ├── adrs/
   │   └── modules/
   ├── issues/
   └── dx-reports/
   ```

3. Initialize `.architect-state.json`:
   ```json
   {
     "project_name": "",
     "appetite_level": null,
     "solution_type": "",
     "current_phase": "discover",
     "modules": [],
     "tracker": "",
     "active_profile": "",
     "created_at": "{ISO timestamp}",
     "updated_at": "{ISO timestamp}"
   }
   ```

4. Record active profile:
   ```bash
   cat ~/.claude/.active-profiles 2>/dev/null | head -1
   ```
   Write to `active_profile` in the state file.

## Pipeline Execution

Use `@agent-architect-lead` as the orchestrator. Pass `$ARGUMENTS` as the problem description.

The architect-lead will run:

### Phase 1: DISCOVER
Delegates to `@agent-problem-analyst`.

### Phase 2: SHAPE
Delegates to `@agent-system-designer`.
**CHECKPOINT**: Present the architecture summary. Get user approval before proceeding.

### Phase 3: SPECIFY
For each module, delegates to `@agent-module-specifier`. Parallel when independent, sequential when dependent.

### Phase 3.5: TEST PLAN
Delegates to `@agent-test-architect`.

### Phase 4: PUBLISH
Delegates to `@agent-issue-writer`. Asks user for tracker if not set.

### Phase 5: REPORT
Delegates to `@agent-dx-reporter` in **background**.

## Completion

Print a summary:
```
✓ Architecture complete for: {project_name}
  Appetite: {level} — {label}
  Solution Type: {type}
  Active Profile: {profile or "none"}
  Modules: {n}
  Features: {n} must-have, {n} nice-to-have
  Issues: {n} published to {tracker}
  Reports: docs/architect-process/dx-reports/

  Key files:
  - Pitch: docs/architect-process/pitches/{slug}-pitch.md
  - Architecture: docs/architect-process/architecture/ARCHITECTURE.md
  - Issues: {tracker link or docs/architect-process/issues/}
  - DX Report: docs/architect-process/dx-reports/{date}-architecture-brief.md
```
