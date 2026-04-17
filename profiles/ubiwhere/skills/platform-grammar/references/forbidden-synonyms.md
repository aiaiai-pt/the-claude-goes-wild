# Forbidden Synonyms

Source: `ubp-spec/ontology/CANONICAL-GRAMMAR.md` §9. Normative.

These terms are **reserved** or **deprecated** and MUST NOT be used in new
specs, APIs, database schemas, or Kafka topics. Use the canonical term instead.

## Forbidden → Canonical

| Forbidden | Canonical | Why |
|---|---|---|
| `municipality_id` | `tenant_id` | Not all tenants are municipalities; tenant is the domain-generic term |
| `visibility_zone` | `scope_id` | "Scope" is the canonical visibility boundary |
| `workspace` (meaning tenant) | `tenant` or `instance` | `workspace` is reserved — do not overload |
| `branch` (meaning tenant partition) | `tenant` | `branch` is reserved for simulation/version context ONLY |
| `branch_id` (in operational tables) | — | `branch_id` MUST NOT appear in operational entity/link tables |
| generic "message" | `ActionIntent` / `EditEvent` | "Message" is ambiguous — use the specific role |

## Detection

`validate-architect-output.py` scans all markdown under `docs/architect-process/`
for forbidden synonyms. Each match produces a warning with file + line +
suggested canonical replacement.

Example output:
```
⚠ docs/architect-process/architecture/modules/03-fleet/SPEC.md:42: 'municipality_id' — use tenant_id
⚠ docs/architect-process/pitches/fire-surveillance-pitch.md:18: 'workspace' — use tenant or instance
```

## False Positives

Some uses of forbidden terms are legitimate:

- `workspace` when referring to a dev-machine working directory (not tenant)
- `branch` when referring to a git branch or simulation branch (not tenant partition)
- `municipality_id` when explaining why NOT to use it ("instead of `municipality_id`, use `tenant_id`")

These are rare; when they occur, the author can mark the line with a comment
explaining the legitimate usage, and reviewers can acknowledge the exception.

## Exhaustive List (keep in sync with validator)

The validator uses these regex patterns (adjust in
`scripts/validate-architect-output.py`):

```python
FORBIDDEN_SYNONYMS = [
    (r"\bmunicipality_id\b", "tenant_id", "error"),
    (r"\bvisibility_zone\b", "scope_id", "error"),
    (r"\bworkspace\b(?!\s+file)", "tenant or instance (workspace is reserved)", "warn"),
    (r"\bbranch_id\b", "simulation_branch_id (operational tables should NOT use branch_id)", "error"),
    (r"\brequest\s+message\b", "ActionIntent (generic 'message' is forbidden)", "warn"),
]
```

`error` severity violations cause the validator to exit non-zero (CI fail).
`warn` severity violations print but don't fail.

## Adding New Forbidden Terms

If a new reserved synonym emerges (from an ADR or policy decision):

1. Add to this document with rationale and canonical replacement
2. Add the regex to `FORBIDDEN_SYNONYMS` in `scripts/validate-architect-output.py`
3. Update `ubp-spec/ontology/CANONICAL-GRAMMAR.md` §9 (if upstream)
