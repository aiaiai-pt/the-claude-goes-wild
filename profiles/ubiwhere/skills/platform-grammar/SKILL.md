---
name: platform-grammar
description: >
  Normative canonical grammar for the UBP platform. Source: ubp-spec/ontology/CANONICAL-GRAMMAR.md.
  MUST be followed by every spec, API, database schema, Kafka topic, and GCS bucket
  the architect produces when the Ubiwhere profile is active. Covers identifier
  prefixes, context tuple, event envelope, API paths, forbidden synonyms, state
  vocabulary, and naming conventions.
---

# Platform Grammar (Normative)

**This skill is NORMATIVE** — keywords MUST, MUST NOT, SHOULD, MAY follow RFC 2119.

Every artifact the architect produces in Ubiwhere context **MUST** conform.

`scripts/validate-architect-output.py` lints produced artifacts against this
grammar when this skill is installed.

## Canonical Terms

- **Instance**: primary infrastructure isolation boundary (deployed per client).
- **Tenant**: data ownership boundary inside an instance.
- **Scope**: computed visibility boundary for a subject.
- **Core Ontology**: canonical semantic + policy authority.
- **Embedded Ontology**: scoped edge runtime subset of ontology + objects.
- **Object Set**: named, policy-compiled object selection expression.
- **Capability Token**: signed, time-bounded token carrying scope authority.
- **ActionIntent**: edge/local representation of desired mutation.
- **EditEvent**: immutable committed mutation record.
- **Checkpoint**: last applied sequence marker for a stream.
- **Simulation Overlay**: non-operational shadow layer for what-if states.

## Term Constraints

1. `branch` MUST refer only to simulation/version context.
2. `branch_id` MUST NOT appear in operational entity/link tables.
3. Effective tenant MUST come from verified identity/scope services, never from client headers directly.
4. `request_id` is the dedupe key; `event_id` is the immutable audit identity.
5. `scope_id` MUST be opaque to clients.

## Canonical Naming Convention

| Element | Case |
|---|---|
| Tables | `snake_case` |
| Entity types | `PascalCase` |
| API fields | `snake_case` |
| Events | `PastTense` (e.g., `ObjectUpserted`, `ActionExecuted`) |
| IDs | prefixed lowercase (e.g., `evt_`, `req_`, `scp_`) |
| Tenant slugs in URL/path | `kebab-case` (e.g., `oliveira-do-bairro`) |
| Domain names in paths | `snake_case` (e.g., `air_quality`) |

## References

- `references/canonical-grammar.md` — EBNF for identifiers and context tuple
- `references/event-envelope.md` — required keys on `/v1/events`
- `references/api-paths.md` — enumerated `/v1/...` paths
- `references/forbidden-synonyms.md` — never-use terms with canonical replacements
- `references/state-vocabulary.md` — allowed status values

## Enforcement

When this skill is installed at `~/.claude/skills/platform-grammar/`, the validator
runs additional grammar checks:

1. **Forbidden synonym scan** — flags `municipality_id`, `workspace` (as tenant),
   `visibility_zone`, `branch` (as tenant partition), generic "message"
2. **ID prefix conformance** — any ID value in a spec uses an approved prefix
3. **Naming conventions** — tables `snake_case`, entity types `PascalCase`,
   events `PastTense`
4. **Event envelope keys** — when a spec references `/v1/events`, all required
   envelope keys are present
5. **API path restriction** — `/v1/...` paths are in the approved enumeration
6. **Bucket naming** — GCS bucket refs follow `ubp-{instance}-{purpose}-{env}`

Each violation appears in the validator output with file + line number.

## Agents That Load This Skill

- `architect-lead` (orchestration context)
- `system-designer` (C4 + ADRs — refuses designs that violate)
- `module-specifier` (specs — enforces identifiers and naming)
- `test-architect` (test IDs, event envelope assertions)
- `issue-writer` (issue body content, commit scopes)

## How to Use in a Spec

When you reference an ID, use the prefix:
```markdown
The fleet manager receives an ActionIntent (e.g., `evt_4a2f…`) with
correlation_id `cor_abc123…`, validates the tenant context
`(inst_cira, tnt_aveiro, scp_ops, usr_alice)`, and writes an EditEvent
(`evt_9b8c…`) with causation_id pointing to the originating event.
```

When you reference a table, use snake_case:
```markdown
`CREATE TABLE fire_risk_assessments (...)` — NOT `fire-risk-assessments` or `FireRiskAssessments`
```

When you reference an entity type, use PascalCase:
```markdown
Entity type `FireRiskAssessment` is published as NGSI-LD type
`urn:ngsi-ld:FireRiskAssessment:{instance}:{tenant}:{uuid}`
```

When you reference an event, use past tense:
```markdown
Producers emit `ObjectUpserted`, `ActionExecuted`, `AlertRaised` — NOT `upsert-object` or `raise-alert`
```
