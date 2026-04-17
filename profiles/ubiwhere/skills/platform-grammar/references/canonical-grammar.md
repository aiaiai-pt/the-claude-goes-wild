# Canonical Grammar — Identifiers & Context Tuple

Source: `ubp-spec/ontology/CANONICAL-GRAMMAR.md`. Normative.

## Identifier Grammar (EBNF)

```ebnf
lower      = "a"…"z" ;
digit      = "0"…"9" ;
hexdig     = digit | "a"…"f" ;
slugchar   = lower | digit | "_" | "-" ;
slug       = slugchar , { slugchar } ;

instance_id = "inst_" , slug ;
tenant_id   = "tnt_" , slug ;
subject_id  = ("usr_" | "svc_" | "edge_") , slug ;
scope_id    = "scp_" , ( slug | hexdig , { hexdig } ) ;
object_type = upper , { upper | lower | digit | "_" } ;
object_id   = ( "obj_" | "occ_" | "ast_" | "alr_" ) , slug ;

request_id     = "req_" , ( slug | hexdig , { hexdig } ) ;
event_id       = "evt_" , ( slug | hexdig , { hexdig } ) ;
correlation_id = "cor_" , ( slug | hexdig , { hexdig } ) ;
causation_id   = event_id ;
```

## ID Prefix Reference

| Entity | Prefix | Example |
|---|---|---|
| Instance | `inst_` | `inst_cira` |
| Tenant | `tnt_` | `tnt_aveiro` |
| Scope | `scp_` | `scp_ops`, `scp_4a2f1b…` |
| Subject: user | `usr_` | `usr_alice` |
| Subject: service | `svc_` | `svc_fleet_manager` |
| Subject: edge | `edge_` | `edge_gw_12` |
| Object: generic | `obj_` | `obj_fleet_a1` |
| Object: occurrence | `occ_` | `occ_incident_1` |
| Object: asset | `ast_` | `ast_sensor_123` |
| Object: alert | `alr_` | `alr_fire_5` |
| Request (dedupe key) | `req_` | `req_abc123` |
| Event (audit identity) | `evt_` | `evt_4a2f…` |
| Correlation | `cor_` | `cor_xyz789` |
| Causation | `evt_` (reuses event_id) | `evt_9b8c…` |

## Context Tuple

Every operation carries a **context tuple** identifying who/where/when:

```ebnf
context_tuple = "(" ,
  "instance_id" , ":" , instance_id , "," ,
  "tenant_id"   , ":" , tenant_id   , "," ,
  "scope_id"    , ":" , scope_id    , "," ,
  "subject_id"  , ":" , subject_id  , "," ,
  "policy_version" , ":" , version ,
")" ;

version = digit , { digit | "." | "_" | "-" | lower } ;
```

Example:
```
(instance_id:inst_cira, tenant_id:tnt_aveiro, scope_id:scp_ops,
 subject_id:usr_alice, policy_version:2026.04.1)
```

Every authorization check receives a context tuple. Every log/trace correlates
by it. Every event envelope carries it.

## Normative Language

Keywords **MUST**, **MUST NOT**, **SHOULD**, **MAY** per RFC 2119.

## Validation Rules

A contract instance is valid only if:

1. `tenant_id` in token context equals `tenant_id` in payload (unless privileged cross-tenant scope).
2. `scope_id` is active and unexpired.
3. `schema_version` supported by receiver.
4. `policy_version` accepted by receiver.
5. `request_id` not previously processed for `(tenant_id, action_type)` dedupe domain.

## Term Constraints (repeat for emphasis)

1. `branch` MUST refer only to simulation/version context.
2. `branch_id` MUST NOT appear in operational entity/link tables.
3. Effective tenant MUST come from verified identity/scope services, never
   directly from client headers (the header supplies the claim; verification
   happens in UMS).
4. `request_id` is the dedupe key; `event_id` is the immutable audit identity.
5. `scope_id` MUST be opaque to clients.
