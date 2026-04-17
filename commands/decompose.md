---
description: >
  Create system architecture from an existing pitch. Skips discovery.
  Pass the pitch file path or name as argument. Use when the problem is already shaped
  and you just need the technical decomposition.
argument-hint: "[pitch name or path]"
---

# /decompose — Architecture Decomposition

Skips Phase 1 (Discover). Starts directly at Phase 2 (Shape).

1. Look for the pitch in `docs/architect-process/pitches/`. If `$ARGUMENTS` names a specific pitch, use it. Otherwise list available pitches and ask.
2. Use `@agent-system-designer` with the selected pitch
3. Present architecture + module map for review
4. Optionally continue to Phase 3 (Specify) if user confirms

This is useful when:
- The pitch already exists from a previous `/shape` run
- Someone wrote a pitch manually following the template
- You're re-decomposing after appetite changed
