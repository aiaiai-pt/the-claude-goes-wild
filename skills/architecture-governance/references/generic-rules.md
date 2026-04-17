# Generic Governance Rules

These rules apply to every architect output, regardless of the active platform profile.

## Artifact Completeness

| Artifact | Required When | Must Include |
|----------|---------------|--------------|
| Pitch | Phase 1 (Discover) complete | problem, appetite, solution direction, rabbit holes, no-gos, stakeholders |
| C4 Context | Phase 2 (Shape) complete | actors, system boundary, external systems, key interactions |
| C4 Container | Phase 2 complete | containers with technology choices + internal/external boundaries |
| ADR | Every significant technology or pattern choice | status, date, deciders, context, drivers, considered options, decision outcome, consequences |
| Module Spec | Phase 3 (Specify) complete | purpose, features with Given/When/Then AC, data model, API contract, NFRs scaled to solution type |
| Test Plan | Phase 3.5 (for MVP+) | test pyramid per module, data quality gates (if data module), CI/CD stages |
| Issue Manifest | Phase 4 (Publish) | epics with features, labels, milestone, component versions, dependencies |
| DX Brief | Phase 5 (Report) | executive summary, decisions, risks, stack alignment, open questions |

## Naming

- ADR files: `ADR-{NNNN}-{kebab-case-title}.md` (sequential, starts at 0001)
- Module directories: `{nn}-{kebab-case-slug}/` under `architecture/modules/`
- Module IDs: `M-{nn}` (zero-padded, matches directory)
- Feature IDs: `F-{nn}.{m}` where `{nn}` is the module ID
- Test IDs: `{type}-{nn}.{m}` (e.g., `UT-03.2` tests `F-03.2`)
- Issue slug: matches module slug for epics; feature title slug for features

## Acceptance Criteria

Every feature acceptance criterion uses Given/When/Then structure:

```
- [ ] Given {precondition}, when {action}, then {expected result}
```

Avoid:
- Vague outcomes ("system should be fast")
- Implementation details ("database row is inserted")
- Multiple behaviors in one criterion ("given X and Y, when A and B, then C and D")

## Dependency Tracking

- Modules declare dependencies on other modules (blocked-by / blocks)
- Features declare dependencies within and across modules
- Circular dependencies are errors — break them with an ADR documenting the refactor

## Scope Discipline

- Every spec has explicit "Out of Scope" section
- No-Gos in the pitch propagate to module specs and issues
- Nice-to-haves marked with `~` prefix — cut first during scope hammering
