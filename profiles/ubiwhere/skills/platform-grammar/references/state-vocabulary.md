# State Vocabulary

Source: `ubp-spec/ontology/CANONICAL-GRAMMAR.md` §8. Normative.

## Allowed Status Values

State machines across the platform use **exactly these** status values:

| Status | Meaning |
|---|---|
| `accepted` | ActionIntent / EditEvent accepted for processing |
| `transformed` | Transformed from raw to canonical form |
| `rejected` | Rejected (validation failure, policy violation, etc.) |
| `duplicate` | Detected as a duplicate (same `request_id` seen before) |
| `conflict_pending` | Conflicts with another pending action — resolution pending |
| `reconciled` | Conflicts resolved, final state agreed |

## Rules

- State columns MUST use ONLY these values — no custom synonyms
- Transitions MUST be documented in the module spec's state machine section
- No implicit states (e.g., "pending" or "in_progress" are NOT allowed —
  `conflict_pending` is specific to conflict resolution)

## Example Transitions

```
ActionIntent submitted
  ↓
accepted ──────────────────────────┐
  ↓                                │
transformed ──────────────┐        │
  ↓                       │        ▼
[processing logic]        ▼     rejected
  ↓                   duplicate
reconciled ← conflict_pending
```

## Forbidden State Names

Do NOT use:
- `pending` (use `conflict_pending` if it's about conflict; otherwise specify the workflow state explicitly)
- `in_progress`, `processing` (these aren't persisted states — they're workflow runtime)
- `success`, `failure` (too vague — use `transformed`, `reconciled`, or `rejected`)
- `ok`, `error` (too vague)
- custom verbs in present tense

If you need a state that doesn't fit the vocabulary, write an ADR extending
it (and update this file + the validator).

## Validation

`validate-architect-output.py` scans specs for state-machine definitions and
flags any use of state names outside the canonical set.

## Relationship to Event Types

State values are persisted **columns**. Event types are PastTense verbs
emitted as events:

| Persisted state | Event emitted when entering state |
|---|---|
| `accepted` | `ActionAccepted` |
| `transformed` | `ActionTransformed` |
| `rejected` | `ActionRejected` |
| `duplicate` | `ActionDuplicateDetected` |
| `conflict_pending` | `ConflictDetected` |
| `reconciled` | `ConflictReconciled` |

The event envelope's `event_type` field uses the PastTense form; the
`payload.status` field uses the persisted value above.
