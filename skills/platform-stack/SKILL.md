---
name: platform-stack
description: >
  Canonical stack reference for architecture decisions. When a profile is active,
  this is OVERRIDDEN by the profile's platform-stack skill. Without a profile,
  falls back to stack-agnostic principles.
---

# Platform Stack

This skill provides the canonical technology stack that architecture decisions
should default to. It is a **shell** — real content comes from a platform profile.

## Active Profile Detection

Check `~/.claude/.active-profiles` (if exists). If a profile like `ubiwhere` is
listed, that profile's `platform-stack` skill (at `~/.claude/skills/platform-stack/`)
overrides this one — the profile installer swaps the symlink.

To see the active profile:
```bash
cat ~/.claude/.active-profiles 2>/dev/null || echo "(none — using generic shell)"
```

## Without a Profile

If no profile is active, use `references/generic-stack-reference.md` for
stack-agnostic principles (cloud-native, GitOps, 12-factor, observable,
multi-tenant-ready) without specific technology choices.

Use `references/appetite-stack-map-template.md` as a template structure.
Each profile fills in specific technologies for the 4 appetite tiers.

## How to Customize

See `CUSTOMIZING.md` for:
- Creating a new profile for your team's stack
- Overriding individual references
- Project-scoped overrides via a project's `.claude/skills/platform-stack/`

## References

- `references/generic-stack-reference.md` — stack-agnostic principles
- `references/appetite-stack-map-template.md` — 4-tier appetite template

## Agents That Load This Skill

Architect agents load `platform-stack` on every run:
- `architect-lead` (orchestration context)
- `system-designer` (C4 + ADR defaults)
- `module-specifier` (per-module technology choices)
- `test-architect` (test tool selection)
- `issue-writer` (technical approach in issue bodies)
- `dx-reporter` (stack alignment table)
