# Platform Topology

Actual deployed topology as of 2026-04-15. Load this when designing modules
so you don't introduce fantasy infrastructure that doesn't exist.

## GCP Project

| Key | Value |
|---|---|
| Project ID | `urban-platform-415114` |
| Region | `europe-west1` |
| Zone (default) | `europe-west1-b` |
| Account | `aduarte@ubiwhere.com` |

## GKE Cluster

| Key | Value |
|---|---|
| Cluster name | `ubp-gke-prod` |
| Mode | GKE Standard + Node Auto-Provisioner (NAP) |
| K8s version | 1.30+ |
| Workload Identity | Enabled (cluster-wide) |
| Network policy | Calico (default-deny in `fleet-system` ns) |

## Environments

| Env | Purpose | Notes |
|---|---|---|
| `local` | Developer laptops | Docker Compose |
| `stg` | Staging | Shared staging cluster (subset of prod services) |
| `prod` | Production | 3 municipalities live: CIRA, TS, VDL |
| `wec` | Western European Customer | Dev/early-access tier |

## Production Instances (per-client)

| Instance | Full Name | Notes |
|---|---|---|
| **cira** | CIRA — Comunidade Intermunicipal da Região de Aveiro | 12 municipalities: aveiro, águeda, anadia, albergaria-a-velha, estarreja, ílhavo, murtosa, oliveira-do-bairro, ovar, sever-do-vouga, vagos, +common |
| **ts** | Tâmega e Sousa CIM | |
| **vdl** | Viseu Dão Lafões CIM | |
| **pbs** | (another CIM) | Staging only so far |
| **amp** | Área Metropolitana do Porto | Seen in POC as `cim_amp` |
| **wec** | Western European Customer | Dev only |
| **ode** | Open Data Explorer | Special — not a municipality; has `ode-dropzone` bucket |

## GCS Buckets — Canonical Pattern

**Format**: `ubp-{instance}-{purpose}-{env}`

```
instance  ∈ {cira, ts, vdl, pbs, amp, wec, ode}
purpose   ∈ {lakehouse, media, dropzone}
env       ∈ {dev, stg, prod}
```

### Observed production buckets

```
ubp-cira-lakehouse-prod       ubp-cira-media-prod
ubp-cira-lakehouse-stg        ubp-cira-media-stg
ubp-ts-lakehouse-prod         ubp-ts-media-prod
ubp-vdl-lakehouse-prod        ubp-vdl-media-prod
ubp-pbs-lakehouse-stg         ubp-pbs-media-stg
ubp-wec-lakehouse-dev
ubp-ode-media-prod            ubp-ode-media-stg
ubp-ode-dropzone              (warehouse/exports/, warehouse/staging/)
```

### Cross-cutting (no instance prefix)

| Bucket | Purpose |
|---|---|
| `ubp-lakehouse-prod-global` / `ubp-lakehouse-stg-global` | Shared/cross-instance lakehouse |
| `ubp-backoffice-modules` | MFE module static assets (multi-region EU) |
| `ubp-ontology-testing` | Ontology QA sandbox |
| `ubp-tofu-state` | Terraform / OpenTofu remote state |
| `ubp-loki-prod` / `ubp-loki-stg` | LGTM: Loki log storage |
| `ubp-mimir-prod` / `ubp-mimir-stg` | LGTM: Mimir metrics |
| `ubp-tempo-prod` / `ubp-tempo-stg` | LGTM: Tempo traces |

### Deprecated (do NOT follow)

- `ubp-bronze-poc` — abandoned POC from months ago with a layer-first structure
  (`{layer}/{cim_group}/{tenant}/{domain}/`). The canonical pattern is
  per-instance bucket with tenant-first paths. See `bucket-layout.md`.

## Shared Platform Services

Deployed once in the shared cluster, consumed by all instances:

| Service | Version | Location |
|---|---|---|
| EMQX | v5.8.3 | `platform-iot` ns |
| Kafka (Strimzi) | KRaft 4.1.1, 3 brokers, 7-day retention | `platform-events` ns |
| Iceberg Kafka Connector | — | `platform-events` ns |
| Apache Polaris | — | `platform-data` ns |
| Trino | — | `platform-data` ns |
| TimescaleDB | pg17 | shared CloudSQL |
| Orion-LD + Mintaka | 1.12.0 (2 replicas) | **DISABLED everywhere** — see AP-5 / ADR-001 |
| Airbyte | 1.8.5 | `platform-data` ns |
| Keycloak | — | `platform-auth` ns |
| HashiCorp Vault | v0.29.1 | `platform-auth` ns |
| Temporal | — | `platform-events` ns |
| Nominatim | — | `platform-iot` ns |
| ArgoCD | — | `argocd` ns |
| UMS v2 + SpiceDB | v1.49.1 | `platform-auth` ns (gRPC :50052) |

## Per-Instance Services

Deployed per-tenant or per-instance namespace:

| Service | Deploy Scope |
|---|---|
| PGU API | per-instance |
| Dagster | per-instance (custom code locations per client — G2 roadmap to standardize) |
| GeoServer | per-instance |
| Metabase | per-instance |
| Nginx (legacy) | per-instance |
| RabbitMQ (legacy for `core`) | per-instance |

## Managed GCP Services

| Service | Config | Notes |
|---|---|---|
| **CloudSQL Postgres** | db-custom-2-8192, 50 GiB, **ZONAL (no HA)** | ⚠ SPOF — R1 roadmap: Regional HA |
| **Cloud Storage** | ubp-* buckets (see above) | europe-west1 |
| **Secret Manager** | + External Secrets Operator | |
| **Artifact Registry** | Images (alongside Harbor) | |

## Ingress / DNS

- **Traefik** (Gateway API) + **cert-manager** + **Cloudflare DNS** (wildcard for `ubp.pt`)
- Multi-level wildcard SSL (~100 municipality subdomains)
- Typical URL: `{tenant}.{instance}.ubp.pt`

## External Registries

- **Harbor**: `harbor.ubiwhere.com/ubp/` (container images)
- **Nexus**: NPM registry for `@ubiwhere/*` packages (requires token)
- **GitLab**: `gitlab.ubiwhere.com` (source + CI)

## Monthly Cost Estimate (from platform assessment)

| Resource | Monthly EUR |
|---|---|
| GKE nodes (~3-4 e2-standard-4) | 300–500 |
| CloudSQL shared instance | 120–150 |
| GCS storage | ~5 |
| Artifact Registry + Secret Manager | ~8 |
| Network egress | ~20 |
| **Total** | **~450–680** |

## Team Capacity (from platform assessment)

~10–11 active contributors across 26 repos. Under-resourced areas (flag when proposing work in these):

| Area | Contributors |
|---|---|
| Data engineering / lakehouse | **1** — severely under-resourced |
| Infrastructure / K8s | 1–2 |
| Ontology / UMS backend | 2–3 |
| Frontend | 3–4 |
| Verticals | 2–3 (fragmented) |
| AI / Martha | Unknown |
