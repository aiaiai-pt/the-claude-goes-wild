---
name: module-specification
description: >
  Deep-dive module specification including feature decomposition, API contracts,
  data models, and NFRs. Use when specifying individual architecture modules
  for development handoff.
---

# Module Specification Skill

## When to Use
- Specifying a module after architecture decomposition
- Writing feature specs within a module
- Defining API contracts between modules
- Creating data models for a module

## Process

1. Read the module stub from `docs/architect-process/architecture/modules/{nn}-{slug}/`
2. Read dependent module stubs to understand interfaces
3. Load the active `platform-stack` skill for canonical technology defaults
4. If a `platform-grammar` skill is present (profile-provided), load it — identifier
   prefixes, event envelope keys, API path constraints, forbidden synonyms, and
   naming conventions become normative for this spec
5. Load `references/module-template.md` for the full template
6. Load `references/feature-template.md` for per-feature structure
7. Calibrate depth to solution type (check `.architect-state.json`)
8. Decompose into features — vertical slices, not horizontal layers
9. Define API contracts for each exposed interface
10. Define data model proportional to solution type
11. Define NFRs proportional to solution type
12. Write SPEC.md to the module directory

## Feature Decomposition Rules

A good feature:
- Delivers a testable slice of user value
- Can be built by one developer in 1–3 days
- Has clear acceptance criteria (Given/When/Then)
- Has a single responsible service/container
- Can be demoed to a stakeholder

A bad feature:
- "Set up the database" (infrastructure, not user value)
- "Implement the backend" (horizontal layer, not vertical slice)
- "Handle edge cases" (vague, unbounded)

### How to slice vertically
```
BAD (horizontal):                    GOOD (vertical):
├── Set up DB schema                 ├── Create resource (API + DB + event)
├── Build API endpoints              ├── View resource state (API + UI)
├── Create frontend components       ├── Alert on threshold (event + notification)
├── Add event emissions              └── ~Dashboard view (UI + API)
└── Write tests
```

## Gotchas
- Don't over-specify for Spike/Prototype appetite — keep it light
- API contracts should use OpenAPI 3.1 format for REST, AsyncAPI for events
- Always include the auth flow (identity + authorization)
- Data models must account for the active multi-tenancy model
- Mark nice-to-haves with ~ prefix — these get cut first during scope hammering
