# Appetite Stack Map Template

Profiles should fill in real technologies for each cell. This is the structural
template.

## Universal axes (all modules)

| Axis | Spike ≤2d | Small Batch 1–2w | Big Batch 6w | Multi-cycle 2×6w |
|---|---|---|---|---|
| Git workflow | solo branch | feature branch + MR | + CODEOWNERS | trunk-ish + required reviews |
| Commit format | freeform | manual conv. commits | commitlint + pre-commit hook | + semantic-release + auto CHANGELOG |
| Container build | none | `docker build` | multi-stage | rootless + registry cache + signing |
| Registry | — | public / local | team registry | + signing + SBOM upload |
| CI | none | basic pipeline | full pipeline (quality → build → scan → deploy) | + environments, gates, canary |
| GitOps | — | — | staging only | full GitOps (prod + DR) |
| Secrets scan | — | on commit | + SAST, SCA | + SBOM, signing, policy gates |
| Observability | `print()` | JSON logs | + traces | + SLOs, alerts, dashboards |

## Backend module axes (if module ships a service)

| Axis | Spike | Small Batch | Big Batch | Multi-cycle |
|---|---|---|---|---|
| Runtime | local | Docker Compose | Orchestrator (dev cluster) | Full prod orchestration + HPA |
| Framework | minimal HTTP | `{canonical framework}` + OpenAPI | + versioning | + AsyncAPI + canonical event envelope |
| App store | embedded DB | `{canonical DB}` | managed DB | + HA/replicas |
| Analytical store | — | — | basic table | Full medallion / analytical layer |
| Async runtime | — | in-proc | `{canonical workflow engine}` | + full workflow graph |
| AuthN | hardcoded | dev IdP | staging IdP | prod IdP + WIF |
| AuthZ | — | role check | + `{canonical authz engine}` | + fine-grained + tenant isolation |
| Tests | smoke | pytest/jest | + integration (testcontainers) | + contract + perf + chaos |

## Frontend module axes (if module ships a UI)

| Axis | Spike | Small Batch | Big Batch | Multi-cycle |
|---|---|---|---|---|
| Runtime | local | `{canonical Node version}` + pnpm/npm | + frozen lockfile | + distroless base |
| Framework | minimal | `{canonical framework}` | + SSR | + full SSR + data loaders |
| Routing | none | file-based | + typed params | + prefetch + suspense |
| Server state | fetch | `{data-fetching lib}` | + SSR hydration | + cache-warming |
| Client state | `useState` | `{state lib}` single store | + slices | + full slice isolation |
| UI composition | hand-coded | + design system | + dynamic composition | + schema-driven |
| Styling | plain CSS | `{styling}` | + theme tokens | + token pipeline |
| Auth client | fake | OIDC lib + dev IdP | + refresh | + silent-renew, role-aware routes |
| Lint | — | `{formatter}` | + CI blocks merge | + custom rules |
| Tests | — | smoke | unit + integration | + E2E + visual regression |

## Data module axes (if module processes analytical data)

| Axis | Spike | Small Batch | Big Batch | Multi-cycle |
|---|---|---|---|---|
| Storage | flat files | `{canonical DB}` | `{raw/bronze layer}` | Full medallion (raw → clean → business) |
| Ingestion | hardcoded | basic ETL | `{canonical ingestion}` | + streaming + backfill |
| Transforms | — | cron + scripts | `{canonical pipeline engine}` | + asset graph + sensors |
| Query | ORM | SQL | `{canonical query engine}` | + federated queries |
| Quality gates | — | — | schema checks | + quality rules on every layer |
| Tenancy | single | single | tenant column | + tenant isolation + global records |

## Profile fills these in

A profile's `appetite-stack-map.md` replaces the `{placeholders}` with concrete
technologies. For example, the Ubiwhere profile fills in:
- `{canonical framework}` → FastAPI
- `{canonical DB}` → PostgreSQL + PostGIS
- `{canonical workflow engine}` → Temporal
- `{canonical authz engine}` → SpiceDB (UMS v2)
- `{canonical ingestion}` → dlt (dltHub)
- `{canonical pipeline engine}` → Dagster
- `{canonical query engine}` → Trino
- etc.
