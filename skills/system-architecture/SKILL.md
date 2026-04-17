---
name: system-architecture
description: >
  C4 model diagramming, ADR writing, and module decomposition. Use when creating
  architecture diagrams, writing Architecture Decision Records, or decomposing a
  system into modules. Stack-specific container defaults come from the active
  platform-stack skill.
---

# System Architecture Skill

## When to Use
- Creating C4 diagrams (Context, Container, Component)
- Writing Architecture Decision Records
- Decomposing a system into modules
- Reviewing or refining existing architecture

## Process

1. Start with C4 Level 1 (Context) — always
2. Proceed to C4 Level 2 (Container) — for appetite ≥ 1
3. C4 Level 3 (Component) only for appetite 3 or when a module is complex enough to warrant it
4. Write ADRs for every significant technology or pattern choice
5. Decompose containers into modules (work units, not deployment units)

## C4 Diagramming with Mermaid

Load `references/c4-templates.md` for Mermaid templates.

### Level 1 — Context
Key rule: Show the **system boundary** clearly. Everything inside is "us",
everything outside is an actor or external system.

### Level 2 — Container
Each container is a **deployable unit**:
- A Kubernetes Deployment/StatefulSet
- A managed service (managed database, object storage)
- A frontend application (SPA, MFE)

The **default set of containers** for your stack comes from the active
`platform-stack` skill. Load it before drawing to anchor on canonical choices.

### ADR Writing
Load `references/adr-template.md` for the MADR template.

Key rules:
- One decision per ADR
- Always document considered alternatives
- Be explicit about trade-offs
- Link to affected modules and other ADRs
- Number sequentially: ADR-0001, ADR-0002, etc.

### Module Decomposition Principles
1. **Vertical slices** > horizontal layers (prefer "auth module" over "backend layer")
2. **Team-sized** — each module should be buildable by 1-3 devs
3. **Clear interfaces** — define API contracts between modules early
4. **Independent deployment** — prefer modules that can ship independently
5. **Appetite-aligned** — each module should fit within the overall appetite budget

## Gotchas
- Don't diagram what you can generate (OpenAPI specs, DB schemas)
- Keep C4 diagrams hand-drawn feel — they're for communication, not precision
- ADRs are for DECISIONS, not for documenting how something works
- Module decomposition is about WORK organization, not code organization
