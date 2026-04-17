---
description: >
  Deep-dive specification on a single module. Pass module ID or name as argument.
  Use after /decompose to flesh out one module at a time.
argument-hint: "<module ID or name>"
---

# /spec-module — Specify a Single Module

1. Read `docs/architect-process/architecture/ARCHITECTURE.md` to get the module map
2. If `$ARGUMENTS` specifies a module (e.g., `M-03` or `auth-gateway`), select it. Otherwise list modules and ask.
3. Use `@agent-module-specifier` for the selected module
4. Present the spec summary and ask if the user wants to revise

This is useful when:
- You want to iterate on one module's spec without re-running the full pipeline
- A module's requirements changed after initial specification
- You're doing progressive specification (most important modules first)
