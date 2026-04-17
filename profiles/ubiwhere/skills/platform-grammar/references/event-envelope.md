# Event Envelope

Source: `ubp-spec/ontology/CANONICAL-GRAMMAR.md`. Normative.

## Grammar (EBNF)

```ebnf
event_envelope = "{" ,
  event_id_field , "," ,
  request_id_field , "," ,
  correlation_field , "," ,
  causation_field , "," ,
  instance_field , "," ,
  tenant_field , "," ,
  scope_field , "," ,
  actor_field , "," ,
  type_field , "," ,
  occurred_at_field , "," ,
  schema_version_field , "," ,
  policy_version_field , "," ,
  payload_field ,
"}" ;
```

## Minimum Required Keys

Every event published to `/v1/events` or onto Kafka **MUST** include:

| Key | Type | Example |
|---|---|---|
| `event_id` | event ID (prefix `evt_`) | `"evt_4a2f1b3c"` |
| `request_id` | request ID (prefix `req_`) | `"req_abc123"` |
| `event_type` | PascalCase past-tense | `"ObjectUpserted"` |
| `instance_id` | instance ID | `"inst_cira"` |
| `tenant_id` | tenant ID | `"tnt_aveiro"` |
| `scope_id` | opaque scope ID | `"scp_ops"` |
| `occurred_at` | ISO8601 UTC timestamp | `"2026-06-01T14:32:01.123Z"` |
| `schema_version` | version of the event schema | `"1.2.0"` |
| `policy_version` | policy version at emit time | `"2026.04.1"` |
| `payload` | object — the event-specific body | `{...}` |

Optional but recommended:

| Key | Type | Purpose |
|---|---|---|
| `correlation_id` | (prefix `cor_`) | Cross-system correlation |
| `causation_id` | (reuses `evt_`) | Points to the causing event |
| `actor` | subject ID | Who triggered the event |

## Example

```json
{
  "event_id": "evt_9b8c7d6e",
  "request_id": "req_abc123",
  "correlation_id": "cor_xyz789",
  "causation_id": "evt_4a2f1b3c",
  "instance_id": "inst_cira",
  "tenant_id": "tnt_aveiro",
  "scope_id": "scp_ops",
  "actor": "svc_fleet_manager",
  "event_type": "ObjectUpserted",
  "occurred_at": "2026-06-01T14:32:01.123Z",
  "schema_version": "1.2.0",
  "policy_version": "2026.04.1",
  "payload": {
    "object_type": "FireRiskAssessment",
    "object_id": "obj_fra_a1b2",
    "attributes": { "fwi_index": 42.5, "risk_level": "high" }
  }
}
```

## Rules

- `event_type` MUST be PascalCase and past-tense (`ObjectUpserted`, `ActionExecuted`,
  `AlertRaised`) — NOT imperative (`upsertObject`, `raiseAlert`)
- `event_id` is **immutable** — never reused, never modified after emission
- `request_id` is the **dedupe key** — same `(tenant_id, action_type, request_id)`
  must not be processed twice
- Timestamps MUST be ISO8601 UTC with millisecond precision
- `schema_version` and `policy_version` are MANDATORY — consumers use them to
  determine compatibility

## Kafka Topic Naming

Events published to Kafka carry the envelope as the message body. The topic
name follows:

```
{env}.{instance}.{tenant}.{domain}.{entity_type}.{event_type}.v{N}
```

Where:
- `env` ∈ `{local, stg, prod, wec}`
- `instance` ∈ `{cira, ts, vdl, pbs, amp, wec, ode}` (but strip `inst_` prefix)
- `tenant` is the tenant slug (strip `tnt_` prefix — kebab-case OK in topic name)
- `domain` is the vertical domain (snake_case)
- `entity_type` snake_case
- `event_type` snake_case (convert from PascalCase payload `event_type` field)
- `v{N}` is the schema major version

Example:
```
prod.cira.aveiro.environment.fire_risk_assessment.object_upserted.v1
```

## Validation

`validate-architect-output.py` scans specs referencing `/v1/events` or
`event_envelope` for missing keys. The check is a warning — authors can have
sketches that don't include every key, but final specs should be complete.
