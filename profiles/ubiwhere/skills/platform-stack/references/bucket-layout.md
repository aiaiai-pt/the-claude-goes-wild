# GCS Bucket Layout (Canonical)

## Bucket Naming Rule

```
ubp-{instance}-{purpose}-{env}
│    │          │          │
│    │          │          └── dev | stg | prod
│    │          └── lakehouse | media | dropzone
│    └── cira | ts | vdl | pbs | amp | wec | ode
└── platform prefix
```

New instances extend the `instance` set; new purposes extend the `purpose` set
(with an ADR). Environments are fixed at `{dev, stg, prod}`.

## Cross-Cutting Buckets (no instance prefix)

| Bucket | Purpose |
|---|---|
| `ubp-lakehouse-{env}-global` | Shared cross-instance lakehouse |
| `ubp-backoffice-modules` | MFE module static assets |
| `ubp-ontology-testing` | Ontology QA |
| `ubp-tofu-state` | Terraform / OpenTofu state |
| `ubp-loki-{env}` / `ubp-mimir-{env}` / `ubp-tempo-{env}` | LGTM |

## Canonical Path Layout (Lakehouse)

```
gs://ubp-{instance}-lakehouse-{env}/
└── {tenant}/                              ← municipality (kebab-case: aveiro, oliveira-do-bairro, sever-do-vouga)
    ├── raw/                               ← pre-bronze landing
    │   └── {source}/...
    ├── bronze/
    │   └── {entity_type}/                 ← snake_case: air_quality, vehicle_positions
    │       ├── data/                      ← Iceberg data files
    │       └── metadata/                  ← Iceberg metadata JSON
    ├── silver/
    │   └── {entity_type}/{data,metadata}
    └── gold/
        └── {entity_type}/{data,metadata}
```

Plus at the tenant level, a `common/` namespace for cross-tenant data within an instance:

```
gs://ubp-{instance}-lakehouse-{env}/
├── aveiro/ {raw,bronze,silver,gold}/...
├── agueda/ {raw,bronze,silver,gold}/...
└── common/ {raw,bronze,silver,gold}/...   ← cross-tenant at instance level
```

## Naming Conventions Inside the Bucket

| Segment | Case | Example |
|---|---|---|
| Tenant | kebab-case | `aveiro`, `oliveira-do-bairro`, `sever-do-vouga` |
| Layer | lower, fixed | `raw`, `bronze`, `silver`, `gold`, `common` |
| Entity type | **snake_case** | `air_quality`, `vehicle_positions`, `fire_weather_index` |
| Leaf | lower, fixed | `data/`, `metadata/` |

⚠ Entity type **must** be snake_case per canonical grammar §10 (tables
`snake_case`). Do not use kebab-case for entity type.

## Polaris Namespace Mapping

Each GCS path maps to an Iceberg namespace in the Polaris catalog:

```
GCS path:    gs://ubp-cira-lakehouse-prod/aveiro/gold/fleet_kpis_daily/
Polaris:     cira.gold.mobility.fleet_kpis_daily
                │     │     │     │
                │     │     │     └── table
                │     │     └── domain
                │     └── layer
                └── instance
```

Note the Polaris namespace also carries a `domain` segment (e.g., `mobility`,
`environment`). The domain can be encoded either:
- As a directory layer between tenant and entity (`aveiro/bronze/mobility/vehicle_positions/`)
- Or flattened with domain prefix in the entity name (`aveiro/bronze/mobility_vehicle_positions/`)

The production buckets today use entity-type directly under layer (no explicit
domain directory). The domain-as-layer variant is acceptable for new instances
but must be agreed in an ADR.

## Media Buckets

```
gs://ubp-{instance}-media-{env}/
└── backoffice/                            ← backoffice uploads
    └── {year}/{month}/{day}/{uuid}.{ext}
```

## ODE Dropzone

```
gs://ubp-ode-dropzone/
└── warehouse/
    ├── exports/
    └── staging/
```

## Deprecated Layout (DO NOT USE)

The `ubp-bronze-poc` bucket has a layer-first structure:

```
# DEPRECATED
gs://ubp-bronze-poc/{layer}/{instance_group}/{tenant}/{domain}/
gs://ubp-bronze-poc/reference/{common,domains,execution,quality,tenants}/
```

This was an abandoned POC from months ago. **Do not** propose or reference this
layout for new data modules. The canonical pattern is the per-instance,
tenant-first layout above.

## Access Pattern

- Workload Identity binds KSA → GSA; GSA has Storage Object Viewer/Admin on specific buckets
- Services access via `gs://` URIs (no key files)
- Signed URLs for browser access use `impersonated_credentials`
- Iceberg via Polaris REST catalog — services query Trino, not GCS directly

## When a new module needs a bucket

1. Propose bucket name following `ubp-{instance}-{purpose}-{env}`
2. If `{purpose}` is new (not in `{lakehouse, media, dropzone}`), write an ADR
3. Add Crossplane / Terraform manifest under the appropriate IaC module
4. Grant KSA via Workload Identity binding — no JSON key files ever
5. Default retention: follow platform defaults; document any deviation
