# API Paths

Source: `ubp-spec/ontology/CANONICAL-GRAMMAR.md` §7. Normative.

## Enumerated Canonical Paths

The platform defines a **canonical API surface** for sync, identity, scope
resolution, actions, and events:

```ebnf
api_path =
    "/v1/identity/exchange"
  | "/v1/scope/resolve"
  | "/v1/sync/snapshots/" , version
  | "/v1/sync/deltas"
  | "/v1/sync/checkpoints"
  | "/v1/actions/submit"
  | "/v1/events" ;
```

## Path Reference

| Path | Purpose |
|---|---|
| `/v1/identity/exchange` | Exchange a bearer token for a capability token with scope/context |
| `/v1/scope/resolve` | Resolve effective scope for a subject + context |
| `/v1/sync/snapshots/{version}` | Fetch a versioned snapshot of ontology or data |
| `/v1/sync/deltas` | Fetch changes since a checkpoint |
| `/v1/sync/checkpoints` | Commit a client-side checkpoint |
| `/v1/actions/submit` | Submit an ActionIntent for server-side processing |
| `/v1/events` | Emit or consume events in canonical envelope format |

## Outside the Canonical Set

Services typically expose additional domain-specific `/api/v1/...` endpoints
(e.g., `/api/v1/fire/thresholds`). These are allowed but:

- Domain endpoints MUST be under `/api/v1/{service}/...`, not `/v1/{service}/...`
  — the bare `/v1/` prefix is reserved for the canonical set above
- Domain endpoints should still conform to the canonical envelope shapes where
  they emit events or submit actions

## Examples

Canonical (reserved prefix):
```
POST /v1/identity/exchange
GET  /v1/scope/resolve
GET  /v1/sync/snapshots/2026.04.1
POST /v1/sync/deltas
POST /v1/sync/checkpoints
POST /v1/actions/submit
POST /v1/events
```

Domain (per-service):
```
GET  /api/v1/fire/thresholds
POST /api/v1/fire/thresholds
GET  /api/v1/fire/risk/{tenant}/{date}
```

## Validation

`validate-architect-output.py` scans specs for `/v1/...` paths and flags any
that are not in the canonical set as warnings. Service-specific endpoints
under `/api/v1/` are ignored.

## Rationale

The canonical set enables:

- Generic client SDKs that know how to exchange tokens, sync, and emit events
  without service-specific knowledge
- A predictable audit trail — all actions pass through `/v1/actions/submit`
  and all events through `/v1/events`
- Version negotiation — `/v1/sync/snapshots/{version}` explicitly carries
  ontology/policy versions
- Platform-level rate limiting and observability on a known path set

Services that reinvent these endpoints (e.g., `/actions`, `/mutate`, `/events/emit`)
break the generic SDK contract.
