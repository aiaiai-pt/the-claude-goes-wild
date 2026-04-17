---
description: >
  Bootstrap the architect-process directory structure. Run this once at the start
  of a new project to create all required directories and the initial state file.
  Safe to re-run — only creates missing directories, never overwrites existing files.
---

# /arch-init — Initialize Architect Process

Create the directory structure for a new architect process run:

```bash
mkdir -p docs/architect-process/{pitches,architecture/{c4,adrs,modules},issues,dx-reports}
```

If `docs/architect-process/.architect-state.json` doesn't exist, create it:

```json
{
  "project_name": "",
  "appetite_level": null,
  "solution_type": "",
  "current_phase": "not_started",
  "modules": [],
  "components": {},
  "milestone": {
    "name": "",
    "target_date": "",
    "tracker_id": ""
  },
  "tracker": "",
  "active_profile": "",
  "created_at": "{ISO timestamp}",
  "updated_at": "{ISO timestamp}"
}
```

Record active profile from `~/.claude/.active-profiles` (first line) into the
`active_profile` field.

Print confirmation:
```
✓ Architect process initialized at docs/architect-process/
  Active profile: {profile or "none"}
  Ready to run /architect, /shape, or /decompose
```

If the directory already exists with a state file, show its current status:
```
ℹ Existing architect session found:
  Project: {project_name}
  Phase: {current_phase}
  Modules: {count}
  Milestone: {milestone.name}
  Active Profile: {active_profile}

  Run /architect to resume, or delete .architect-state.json to start fresh.
```
