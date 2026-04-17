---
name: platform-stack
description: >
  Canonical reference for the Ubiwhere Urban Platform stack. Medallion on
  Iceberg+Trino+Dagster+dlt. FastAPI+PostgreSQL+PostGIS+TimescaleDB for
  operational state. Keycloak+UMS v2+SpiceDB for auth. TanStack Start+Nitro+
  @ubiwhere/schema-renderer for frontend. GKE+ArgoCD+Crossplane+Terraform on GCP
  europe-west1 with Workload Identity. Load this on every architecture decision
  to anchor on canonical choices.
---

# Ubiwhere Platform Stack

This is the **active platform-stack** while the Ubiwhere profile is installed.

## When to Use
- Any architect agent making technology decisions
- Writing ADRs (to know what the "default" is)
- Specifying module implementations
- Reviewing architecture for stack alignment

## Process
1. For technology choices, always check the references below first
2. Default to the listed technology unless there's a compelling reason to deviate
3. Any deviation requires an ADR with "Accepted" status
4. For appetite-based scoping, load `references/appetite-stack-map.md`
5. For anti-patterns to avoid, load `references/anti-patterns.md`
6. For open gaps to reference, load `references/platform-gaps.md`

## Quick Reference — The Stack

### Data Layer (Medallion Architecture — THE CORE)

| Layer | Technology | Role |
|-------|-----------|------|
| **Bronze (raw)** | Kafka/Strimzi → Iceberg (via Kafka Connect) | Streaming raw events |
| **Bronze (batch)** | dlt (dltHub) + Dagster → Iceberg | External API/file/DB ingestion |
| **IoT bridge** | Redpanda Connect (Benthos) + EMQX | MQTT→Kafka with schema validation + DLQ |
| **Silver (clean)** | Dagster transforms via Trino SQL | Dedup, conform, type-safety, tenant populate |
| **Gold (business)** | Dagster asset materializations | KPIs, aggregations, domain views |
| **Storage** | Apache Iceberg on GCS + **Apache Polaris** REST catalog | Backbone |
| **Query** | **Trino** | Forefront query engine for ALL platform data |
| **BI** | Metabase | On gold-layer Trino queries |
| **Publication** | Orion-LD (NGSI-LD) | **BLOCKED — disabled in all prod instances (see ADR-001 in platform-gaps)** |

⚠ **Reality check**: per the platform assessment, the Bronze→Silver→Gold
transformation pipeline is **not productionized yet** — see G2 in
`platform-gaps.md`. New data modules should contribute to the shared
`data-library` rather than building per-client Dagster code.

### Compute & Orchestration (GCP)

| Concern | Technology | Notes |
|---------|-----------|-------|
| Cloud | **GCP** project `urban-platform-415114`, region `europe-west1` |
| Compute | **GKE Standard + NAP** | K8s 1.30+, Workload Identity, Calico |
| GitOps | **ArgoCD** ApplicationSets | per-instance overlays |
| IaC (managed services) | **Crossplane** (CloudSQL, GCS) |
| IaC (cluster/DNS/IAM) | **Terraform** + Cloudflare | tofu-state bucket: `ubp-tofu-state` |
| Durable workflows | **Temporal** | Canonical async runtime (consolidation target — see AP-2) |
| Data orchestration | **Dagster** | Asset-based, run launcher `K8sRunLauncher` |
| Data loading | **dlt (dltHub)** | Python-native ELT, schema inference |
| Event bus | **Kafka / Strimzi** (KRaft 4.1.1) | 3 brokers, 7-day retention |
| Stream bridge | **Redpanda Connect (Benthos)** | schema validation + DLQ |

### Backend (Services)

| Concern | Technology | Notes |
|---------|-----------|-------|
| **Framework** | **FastAPI** + Pydantic v2 | Canonical — Django backends are legacy |
| **Python** | 3.14 + full type hints + ruff + `uv` |
| **App DB** | **PostgreSQL + PostGIS** (CloudSQL) | **⚠ zonal today — R1 roadmap to Regional HA** |
| **Time-series DB** | **TimescaleDB** hypertables per time-series entity type | No FKs to hypertables (see ontology ADR-011) |
| **Cache** | Redis | app cache + Pub/Sub outbox |
| **Workflow** | Temporal | NOT Celery, NOT Zeebe (AP-2) |
| **Ontology** | `ontology-core-v2` (FastAPI) | Dynamic schema engine, Recursive CTEs for 1-4 hop graph traversal, native columns (ADR-004) |

### Frontend

| Concern | Technology | Notes |
|---------|-----------|-------|
| **Runtime** | **Node 25-alpine** + **pnpm 10** (frozen-lockfile) |
| **Framework** | **TanStack Start + Nitro** (SSR) | NOT Module Federation |
| Routing | TanStack Router file-based | typed search params, `_layout`, data loaders |
| Server state | `@tanstack/react-router-ssr-query` (hydration) |
| Client state | **Zustand** | single store with slices |
| **UI composition** | **`@ubiwhere/schema-renderer`** (YAML islands) + **`@ubiwhere/design-system-components`** (from Nexus) |
| Styling | Tailwind CSS v4 |
| Maps | OpenLayers (`ol`) |
| Auth client | `oidc-client-ts` |
| Lint/format | **Biome** (tabs, double quotes) |
| Tests | **Vitest** + Testing Library |
| Git hooks | **Lefthook** |
| Runtime config | `window._env_` injection (image reuse across envs) |

### Identity, AuthN & AuthZ

| Concern | Technology | Notes |
|---------|-----------|-------|
| **AuthN** | **Keycloak** (OIDC) | Realm per **client**, roles per tenant (ontology ADR-0001) |
| **AuthZ** | **UMS v2** (FastAPI) + **SpiceDB** (v1.49.1) on gRPC :50052 | Compiles grant predicates to row-level SQL filters |
| Multi-tenancy | **Instance → Tenant** at **service layer** (NOT DB RLS) — `X-Tenant-Id` header/metadata |
| Secrets | GCP Secret Manager + ESO + HashiCorp Vault v0.29.1 |
| Workload Identity | KSA → GSA (no service account key files) |

### IoT

| Concern | Technology | Notes |
|---------|-----------|-------|
| LoRaWAN | ChirpStack v4 |
| MQTT Broker | EMQX v5.8.3 | (VerneMQ in parallel evaluation) |
| IoT bridge | Redpanda Connect (Benthos) → Kafka |

### Observability & Security

| Concern | Technology | Notes |
|---------|-----------|-------|
| Logs / Metrics / Traces | **LGTM stack** (Loki / Grafana / Tempo / Mimir) + **Grafana Alloy** (OTel Collector) |
| Observability buckets | `ubp-loki-{env}`, `ubp-mimir-{env}`, `ubp-tempo-{env}` |
| SAST | **Semgrep** |
| Container/FS scan | **Trivy** (`--severity HIGH,CRITICAL --ignore-unfixed`) |
| Code quality | SonarQube |
| SBOM | **CycloneDX** via Trivy → Dependency-Track |
| Image signing | **Cosign** |
| Secrets scan | gitleaks |

### Registries & CI

| Concern | Technology | Notes |
|---------|-----------|-------|
| Container registry | **Harbor** (`harbor.ubiwhere.com/{group}/{service}`) |
| NPM registry | **Nexus** for `@ubiwhere/*` (auth via CI secret) |
| CI | **GitLab CI** | `gitlab.ubiwhere.com` |
| Image build | **BuildKit rootless** (moby/buildkit) + `--secret` mounts |

### Domain Infrastructure

| Concern | Technology | Notes |
|---------|-----------|-------|
| DNS | `ubp.pt` + Cloudflare (multi-level wildcard) |
| Environments | `local`, `stg`, `prod`, `wec` |
| Platform CLI | `ubw` |
| Ontology | WN-TOLOGY / UCS + `ontology-core-v2` |
| Org registry | Pia Digital |
| Fleet mgmt | ubw-fleet |

## Conventions

### Kafka Topic Taxonomy
```
{env}.{instance}.{tenant}.{domain}.{entity_type}.{event_type}.v{N}
```

### Medallion Iceberg Namespaces
```
Namespace: {instance}.{layer}.{domain}
Example:   cira.bronze.mobility.vehicle_positions
           cira.silver.mobility.vehicle_positions_clean
           cira.gold.mobility.fleet_kpis_daily
```

### GCS Bucket Layout
See `references/bucket-layout.md` — canonical:
```
ubp-{instance}-{purpose}-{env}/{tenant}/{raw|bronze|silver|gold}/{entity_type}/{data,metadata}
```

### Multi-Tenancy
```
Instance (client org — e.g., CIRA, AMP)
└── Tenant (municipality within instance)
```
- Keycloak: realm per **client** (ontology ADR-0001), roles per tenant
- UMS v2 / SpiceDB: relation-based tenant scoping + grant compilation
- Iceberg: namespace per instance, tenant segment in GCS path
- PostgreSQL: `tenant_id` column (nullable for global) — `X-Tenant-Id` header
- Kafka: tenant segment in topic path
- **Never** use DB row-level security for tenancy — enforce at service layer

### API Patterns
- **Trino SQL** for analytical/reporting queries (gold layer)
- **FastAPI + OpenAPI 3.1** for application APIs (canonical — not Django)
- **NGSI-LD** ONLY for smart city publication compliance (blocked on ADR-001)
- **AsyncAPI** for Kafka topic contracts
- **dlt sources** for external API ingestion
- See `references/event-envelope.md` (profile-grammar) for canonical envelope

## Gotchas
- Trino targets gold layer for user features; silver for internal transforms only
- dlt schema evolution can cause Iceberg drift — pin schemas in prod
- Orion-LD is deployed but disabled everywhere — **do NOT propose new NGSI-LD publication**
- Workload Identity: KSA→GSA trust chain for GCP API access
- Strimzi KafkaTopics are CRDs — validate with `kubeconform`
- TimescaleDB hypertables can't be referenced by foreign keys (ontology ADR-011)
- `@ubiwhere/*` NPM packages require Nexus registry config in `.npmrc` at build time (via BuildKit `--secret`)

## Gap Awareness

See `references/platform-gaps.md` for the 15 known gaps (G1-G15). When your
module addresses a gap, reference it by ID in the module spec and issue body.
When your module depends on a still-open gap, flag it prominently.
