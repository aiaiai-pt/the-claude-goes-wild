# ADR Template (MADR — Markdown Any Decision Record)

## File Naming
`ADR-{NNNN}-{kebab-case-title}.md`

Example: `ADR-0003-choose-authorization-engine.md`

## Template

```markdown
# ADR-{NNNN}: {Title — a short noun phrase}

**Status**: Proposed | Accepted | Deprecated | Superseded by ADR-{NNNN}
**Date**: {YYYY-MM-DD}
**Deciders**: {names or roles}
**Consulted**: {names or roles, optional}

## Context and Problem Statement

{Describe the context and problem. Why does this decision need to be made?
What forces are at play? 2-4 sentences.}

## Decision Drivers

- {driver 1}
- {driver 2}
- {driver 3}

## Considered Options

1. **{Option A}** — {one-line description}
2. **{Option B}** — {one-line description}
3. **{Option C}** — {one-line description}

## Decision Outcome

**Chosen option**: "{Option X}", because {brief justification linking back to decision drivers}.

### Consequences

**Good**:
- {positive consequence 1}
- {positive consequence 2}

**Bad**:
- {negative consequence or trade-off 1}

**Neutral**:
- {neutral observation}

## Pros and Cons of the Options

### {Option A}
- Good: {pro}
- Good: {pro}
- Bad: {con}
- Neutral: {observation}

### {Option B}
- Good: {pro}
- Bad: {con}

### {Option C}
- Good: {pro}
- Bad: {con}

## Links

- Related modules: M-{nn}, M-{nn}
- Related ADRs: ADR-{NNNN}
- External references: {links to docs, RFCs, blog posts}
```

## Rules
- One decision per ADR — don't bundle
- Write ADRs AFTER you've explored, not before
- Accepted ADRs are immutable — create a new one to supersede
- ADRs are NOT documentation — they record WHY, not HOW

## Profile Overrides

When a platform profile is active, it may provide a list of "default ADRs"
(decisions that almost every project will need to make for that stack). Load
the profile's `platform-stack` skill to see if it recommends specific ADRs —
for example, the Ubiwhere profile recommends ADRs on multi-tenancy, medallion
architecture, event backbone, authorization, and deployment.
