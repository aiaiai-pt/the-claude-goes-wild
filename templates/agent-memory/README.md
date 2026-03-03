# Agent Memory

Institutional knowledge accumulated by agents across runs.
Append-only — never delete entries, only update their `status` field.

## Entry Format

```markdown
### [ENTRY-ID] Short title
- **date**: YYYY-MM-DD
- **agent**: <agent-name>
- **run-ref**: <git-ref>@<short-sha>
- **confidence**: high | medium | low
- **status**: active | resolved | suppressed | consolidated
- **tags**: [tag1, tag2]

**What was learned:** <factual description>
**Context:** <what triggered this>
**Action taken:** <what was done>
**Watch for:** <what future agents should look out for>
```

## Entry ID Prefixes

| Prefix | Owner |
|--------|-------|
| `SEC-` | Security analyst agent |
| `ENG-` | Fullstack dev and code reviewer agents |
| `PRD-` | Technical product manager agent |

## ID Format

`PREFIX-YYYYMMDD-NNN` where NNN is a zero-padded sequence number for that day.

Example: `SEC-20260303-001`

## Status Lifecycle

```
active → resolved → consolidated (archived after TTL)
active → suppressed (false positive / won't fix)
```

- **active**: Current, relevant knowledge
- **resolved**: Issue was fixed or pattern no longer applies
- **suppressed**: Confirmed false positive or accepted risk
- **consolidated**: Merged with another entry during consolidation

## Rules

- Never delete entries — only update `status`
- One finding per entry — don't combine unrelated items
- Include `run-ref` so findings can be traced to specific commits
- `confidence: low` entries get extra scrutiny during consolidation
