# Appetite Stack Map (Ubiwhere)

Recommended stack per Shape Up appetite. Load this when specifying modules to
pick technologies matching the appetite — don't pull in the full production
stack for a 2-day spike.

## Universal axes — all modules

| Axis | **Spike** ≤2d | **Small Batch** 1–2w | **Big Batch** 6w | **Multi-cycle** 2×6w |
|---|---|---|---|---|
| Canonical grammar | suggested | required on new APIs | required everywhere + enforced | + CI lint |
| Instance/tenant model | single (local) | single (stg) | instance-scoped | Instance → Tenant at service layer (header-based, NOT DB RLS) |
| ID prefixes | free | required on new entities | required everywhere | + auto-generation in SDK |
| Container build | local | `docker build` | BuildKit + multi-stage Dockerfile | BuildKit rootless + registry cache + `--secret` mounts + Cosign |
| Registry | — | public / local | **Harbor** (`harbor.ubiwhere.com/{group}/{svc}`) | Harbor + Cosign signing + SBOM upload |
| IaC | none | docker-compose | **Terraform** (GKE) | Terraform + **Crossplane** (CloudSQL, GCS) + Workload Identity |
| CI | none | **GitLab CI** basic | GitLab CI (quality→build→scan→deploy) | + environments (local/stg/prod/wec), canary |
| GitOps | — | — | **ArgoCD** staging | ArgoCD **ApplicationSets** + prod + DR + per-instance overlays |
| Observability | `print()` | JSON logs | OTel via Grafana Alloy | Full **LGTM** + dashboards + SLOs |
| Secrets | env vars | `.env.example` | GCP Secret Manager + ESO | + **Vault** for app-level |
| Scan | — | gitleaks + Trivy fs | + Trivy image (CRITICAL blocks) | + Semgrep + SonarQube + Dependency-Track + CycloneDX SBOM + Cosign |
| Remote IaC state | — | — | local or GCS | **`ubp-tofu-state`** bucket |

## Backend module axes

| Axis | Spike | Small Batch | Big Batch | Multi-cycle |
|---|---|---|---|---|
| Runtime | Python 3.14 local | Docker Compose | GKE staging ns | Full GKE + HPA + PDB |
| Framework | **FastAPI** minimal | FastAPI + OpenAPI 3.1 + pydantic v2 | + versioned routes | + AsyncAPI + canonical event envelope (`/v1/events`) |
| App store | SQLite | **PostgreSQL + PostGIS** | **CloudSQL Postgres + PostGIS** (zonal — R1) | CloudSQL **Regional HA** + PostGIS (closes R1) |
| Time-series | — | — | **TimescaleDB** hypertable per time-series entity type | + compression policies + continuous aggregates (no FKs to hypertables) |
| Graph traversal | — | — | Recursive CTEs on `entity_relationships` | + schema registry + auto-CREATE TABLE per entity type (ontology ADR-007) |
| Async runtime | — | in-proc tasks | **Temporal** (NOT Celery, NOT Zeebe — AP-2) | Temporal + K8s jobs |
| Analytical store | — | — | Iceberg bronze (Polaris) | Full medallion + shared `data-library` (closes G2) |
| Query engine | ORM | PostgreSQL | **Trino** on gold only | Trino federated across all layers |
| Pipelines | — | cron + python | **Dagster** (custom) | **Dagster + shared data-library** (template, not custom) |
| Events | — | HTTP poll | Kafka single-broker | **Kafka/Strimzi** + Benthos schema validation + DLQ |
| AuthN | hardcoded | **Keycloak** dev realm | Keycloak staging (per-client realm) | Keycloak prod + realm sync per client + Workload Identity Federation |
| AuthZ | — | role check in-app | **UMS v2** + basic SpiceDB | UMS v2 + SpiceDB full Zanzibar + grant predicate compilation + `X-Tenant-Id` |
| NGSI-LD | — | — | **— (do not wire)** | **BLOCKED on ADR-001** — do not add new Orion-LD publication (AP-5) |
| Tests | smoke | pytest | + testcontainers (Postgres+PostGIS, Kafka, Trino) | + schemathesis contract + Locust + chaos |
| Tenancy | single | single | `tenant_id` column (nullable=global) | + UNION ALL resolve + tenant immutability + cross-tenant mutation guard (404) |

## Frontend module axes

| Axis | Spike | Small Batch | Big Batch | Multi-cycle |
|---|---|---|---|---|
| Runtime | Node 25 local | **Node 25-alpine** + **pnpm 10** | + frozen-lockfile | + distroless base + BuildKit |
| Framework | React + Vite | **TanStack Start** (SPA) | **TanStack Start + Nitro** (SSR) | + route-level data loaders + error boundaries |
| Routing | single page | TanStack Router file-based | + `_layout` + typed search params | + prefetch + suspense |
| Server state | `fetch()` | **TanStack Query** | **`@tanstack/react-router-ssr-query`** | + cache-warming + optimistic updates |
| Client state | `useState` | **Zustand** single store | Zustand + slices | + React 19 `use()` where fit |
| UI composition | hand-coded JSX | + **`@ubiwhere/design-system-components`** (Nexus) | + **`@ubiwhere/schema-renderer`** YAML islands | **schema-renderer driven** (YAML-first); hand-code only where schema can't express |
| Styling | plain CSS | **Tailwind v4** | + theme tokens | + design-token pipeline synced with DS |
| Maps | — | — | **OpenLayers** (`ol`) | ol + vector tiles from Trino + (NGSI-LD overlay gated on ADR-001) |
| Auth client | none / fake | **`oidc-client-ts`** + dev Keycloak | + refresh flow | + silent-renew + session timeout UX + role-aware routes |
| Runtime config | `import.meta.env` | `import.meta.env` | **`window._env_`** injection (see `src/configs.ts`) | `window._env_` + validation on boot |
| Lint/format | — | **Biome** (`pnpm check`) | Biome + CI blocks merge | + custom rule set |
| Tests | — | **Vitest** smoke | Vitest + Testing Library unit+integration | + **Playwright** E2E + visual regression + coverage gate |
| Git hooks | — | **Lefthook** (format) | Lefthook (format + test) | Lefthook + commitlint + gitleaks |

## Data module axes

| Axis | Spike | Small Batch | Big Batch | Multi-cycle |
|---|---|---|---|---|
| Bucket | local fs | `ubp-{slug}-lakehouse-dev` | `ubp-{instance}-lakehouse-stg` | `ubp-{instance}-lakehouse-{dev,stg,prod}` + `ubp-lakehouse-{env}-global` |
| Path layout | flat | `{tenant}/bronze/{entity}/{data,metadata}` | + silver + `common/` | + gold + full 4-layer medallion per tenant |
| Ingestion | hardcoded | dlt CSV/REST | **Benthos** (EMQX→Kafka schema validation) + dlt batch | + Kafka Connect Iceberg sink + DLQ + fill missing schemas (closes AP-3) |
| Storage | SQLite | PostgreSQL | Iceberg bronze on GCS + **Polaris** REST catalog | Full medallion + per-instance GCS buckets |
| Transforms | — | cron | Dagster custom | **Dagster + shared `data-library`** (config-driven, not per-client — closes G2/R3) |
| Query | ORM | PostgreSQL | Trino (gold only) | Trino federated across layers |
| Topic naming | — | — | `{env}.{instance}.{tenant}.{domain}.{entity}.{event}.v{N}` | + 4+ schemas beyond current EMQX bridge limit |
| Data quality | — | — | Dagster asset checks on bronze | + silver/gold quality gates + anomaly detection service (closes G4) |
| Lakehouse→Ontology | — | — | — | Dagster job materializing gold → ontology entities (new bridge pattern, roadmap 1.4) |

## Key principles

- The Ubiwhere stack is the **terminal state** (Multi-cycle column). Each lower
  appetite is a **principled subset** — lose pieces that aren't earning their
  keep for that budget.
- Same technology family when possible (e.g., Postgres everywhere until you
  need Trino; FastAPI everywhere), just less of it.
- Canonical grammar kicks in at Small Batch for new APIs; mandatory everywhere at Big Batch+.
- Multi-tenancy at service layer from Big Batch+ (never DB RLS).
- Orion-LD / NGSI-LD publication is BLOCKED until ADR-001 resolves —
  don't propose new wiring.
- New async workflows go to **Temporal** — not Celery, not Zeebe (AP-2 consolidation).
- New backends go to **FastAPI** — don't add more Django monoliths (AP-1).

## References
- `stack-reference.md` — detailed configs
- `anti-patterns.md` — APs to refuse (AP-1..AP-7)
- `platform-gaps.md` — open gaps (G1..G15)
- `bucket-layout.md` — GCS canonical layout
- `multi-tenancy.md` — tenancy at service layer
