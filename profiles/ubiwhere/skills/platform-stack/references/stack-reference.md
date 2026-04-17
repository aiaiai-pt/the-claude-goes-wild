# Ubiwhere Stack — Detailed Configuration Patterns

## Medallion Architecture — Data Flow

```
┌──────────────────────────────────────────────────────────────────┐
│                        DATA SOURCES                              │
│  IoT/LoRaWAN    External APIs     Municipal DBs     File Uploads │
│  (ChirpStack)   (IPMA/ANEPC/GTFS) (PostgreSQL)    (CSV/Excel)    │
└──────┬──────────────┬────────────────┬────────────────┬──────────┘
       │              │                │                │
       ▼              ▼                ▼                ▼
┌──────────────┐ ┌─────────────────────────────────────────────────┐
│ EMQX → Kafka │ │         dlt (dltHub) + Dagster                  │
│ Redpanda     │ │  Batch ingestion with schema inference,         │
│ Connect      │ │  incremental loads, automatic schema evolution  │
│ (Benthos)    │ │  Shared data-library for standard transforms    │
│ w/ schemas   │ │  (G2 roadmap — currently per-client custom)     │
│ + DLQ        │ │                                                 │
└──────┬───────┘ └──────────────────┬──────────────────────────────┘
       │                            │
       ▼                            ▼
┌─────────────────────────────────────────────────────────────────┐
│  BRONZE LAYER — Apache Iceberg on GCS (Apache Polaris catalog)  │
│  Raw, append-only. Schema-on-read. Partitioned by tenant+date.  │
│  Namespace: {instance}.bronze.{domain}                          │
│  GCS: ubp-{instance}-lakehouse-{env}/{tenant}/bronze/{entity}/  │
└──────────────────────────┬──────────────────────────────────────┘
                           │ Dagster transforms (Trino SQL)
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│  SILVER LAYER — Apache Iceberg on GCS                           │
│  Cleaned, deduplicated, conformed. Type-safe. Tenant-isolated.  │
│  Namespace: {instance}.silver.{domain}                          │
│  GCS: ubp-{instance}-lakehouse-{env}/{tenant}/silver/{entity}/  │
└──────────────────────────┬──────────────────────────────────────┘
                           │ Dagster asset materializations
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│  GOLD LAYER — Apache Iceberg on GCS                             │
│  Business-ready views, KPIs, aggregations. Domain-specific.     │
│  Namespace: {instance}.gold.{domain}                            │
│  GCS: ubp-{instance}-lakehouse-{env}/{tenant}/gold/{entity}/    │
└──────┬──────────────────────┬───────────────────────┬───────────┘
       │                      │                       │
       ▼                      ▼                       ▼
┌────────────┐    ┌──────────────────┐    ┌──────────────────────┐
│   Trino    │    │    Metabase      │    │    Orion-LD          │
│ (queries)  │    │  (dashboards)    │    │ ⚠ DISABLED (ADR-001) │
│ Primary    │    │  on gold-layer   │    │ Do NOT wire new      │
│ query      │    │  Trino queries   │    │ NGSI-LD publication  │
│ engine     │    │                  │    │ until resolved       │
└────────────┘    └──────────────────┘    └──────────────────────┘
```

## GKE Cluster Layout

Production: `ubp-gke-prod` (GKE Standard + NAP + Workload Identity + Calico) in `europe-west1`.

Namespaces:
```
{instance}-{tenant}          # Per-tenant services (cira-aveiro, cira-agueda, ...)
{instance}-shared            # Cross-tenant at instance level (e.g., cira-shared)
platform-data                # Dagster, Trino, Polaris
platform-events              # Kafka/Strimzi, Redpanda Connect, EMQX
platform-iot                 # ChirpStack v4
platform-auth                # Keycloak, UMS v2, SpiceDB
observability                # LGTM stack, Alloy
argocd                       # ArgoCD ApplicationSets
fleet-system                 # Default-deny network policy (Calico)
```

Environments via ArgoCD overlays: `local`, `stg`, `prod`, `wec`.

## Dagster + dlt Pipeline Pattern

```python
import dlt
import dagster as dg

# dlt source for external API ingestion (bronze)
@dlt.source
def ipma_source():
    @dlt.resource(
        table_name="fire_weather_index",
        write_disposition="merge",
        primary_key="location_id",
    )
    def fire_weather_index(
        updated_at=dlt.sources.incremental("forecast_date")
    ):
        yield from paginate_ipma_fwi(updated_at.last_value)

    return fire_weather_index

# dlt pipeline targeting Iceberg bronze layer
ipma_pipeline = dlt.pipeline(
    pipeline_name="ipma_ingestion",
    destination="filesystem",  # or iceberg destination
    dataset_name="cira.bronze.environment",
)

# Dagster asset for bronze → silver transform
@dg.asset(
    key=["cira", "silver", "environment", "fire_risk_clean"],
    deps=["cira.bronze.environment.fire_weather_index"],
)
def fire_risk_clean(context, trino):
    """Clean and conform IPMA fire risk data."""
    trino.execute("""
        INSERT INTO cira.silver.environment.fire_risk_clean
        SELECT
            location_id,
            forecast_date,
            CAST(fwi_index AS DOUBLE) as fwi_index,
            tenant_id,
            NOW() as processed_at
        FROM cira.bronze.environment.fire_weather_index
        WHERE forecast_date > (SELECT MAX(forecast_date) FROM cira.silver.environment.fire_risk_clean)
    """)

# Dagster asset for silver → gold aggregation
@dg.asset(
    key=["cira", "gold", "environment", "fire_risk_daily_kpi"],
    deps=["cira.silver.environment.fire_risk_clean"],
)
def fire_risk_daily_kpi(context, trino):
    trino.execute("""
        INSERT INTO cira.gold.environment.fire_risk_daily_kpi
        SELECT
            tenant_id,
            forecast_date,
            AVG(fwi_index) as avg_fwi,
            MAX(fwi_index) as max_fwi,
            COUNT(*) as station_count
        FROM cira.silver.environment.fire_risk_clean
        GROUP BY tenant_id, forecast_date
    """)
```

## ArgoCD Application Pattern

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: {service}-{instance}
  namespace: argocd
spec:
  project: {instance}
  source:
    repoURL: https://gitlab.ubiwhere.com/cities/urban-platform-v2/{group}/{service}.git
    targetRevision: main
    path: deploy/overlays/{instance}
  destination:
    server: https://kubernetes.default.svc
    namespace: {instance}-shared
  syncPolicy:
    automated: { prune: true, selfHeal: true }
    syncOptions: [CreateNamespace=true]
  revisionHistoryLimit: 3
```

## SpiceDB Schema Pattern (Zanzibar)

```zed
definition user {}

definition instance {
    relation admin: user
    relation member: user
    permission manage = admin
    permission access = admin + member
}

definition tenant {
    relation parent: instance
    relation operator: user
    relation viewer: user
    permission manage = parent->manage + operator
    permission view = manage + viewer
    permission access = parent->access
}

definition resource {
    relation owner: user
    relation tenant: tenant
    permission edit = owner + tenant->manage
    permission view = edit + tenant->view
}
```

UMS v2 (FastAPI) compiles grant predicates into row-level SQL filters injected
into the Repository / QueryBuilder layer. See `ontology-core-v2` for the
reference implementation.

## Frontend Pattern (TanStack Start + schema-renderer)

```
{service}/
├── src/
│   ├── routes/
│   │   ├── __root.tsx           # Root layout with SchemaRendererProvider
│   │   ├── _layout.tsx          # Auth-guarded layout
│   │   ├── index.tsx            # Dashboard home
│   │   ├── callback.tsx         # OIDC callback
│   │   └── _layout/
│   │       └── {routes}
│   ├── features/                # Feature components
│   ├── registry/                # schema-renderer component registry
│   ├── services/
│   │   ├── auth/                # oidc-client-ts integration with Keycloak
│   │   └── http/                # API client w/ X-Tenant-Id
│   ├── configs.ts               # Reads window._env_
│   └── styles.css
├── server/plugins/              # Nitro server plugins
├── Dockerfile                   # multi-stage BuildKit, --secret mounts
├── .gitlab-ci.yml               # build → push Harbor
├── biome.json                   # tabs, double quotes
├── lefthook.yml                 # pre-commit: biome check
└── package.json                 # pnpm 10, Node 25-alpine runtime
```

`@ubiwhere/schema-renderer` drives UI composition — YAML configs describe
components (`code`, `properties`, `actions`, `events`, `children`). Hand-coded
JSX only where the schema can't express.

## Runtime Config Pattern

The frontend reads runtime config from `window._env_` (not build-time env) so
the same image runs across `local`, `stg`, `prod`, `wec`:

```ts
// src/configs.ts
export const getConfig = (): RuntimeConfig => {
  if (!window._env_) throw new Error("Runtime configuration is not available");
  const env = window._env_;
  const missing = ENV_KEYS.filter(k => !env[k]);
  if (missing.length) throw new Error(`Missing config: ${missing.join(", ")}`);
  return env;
};
```

The Nitro server plugin injects `<script>window._env_ = {...}</script>` on page
load based on runtime env vars.

## Grafana Alloy Config (OTel Collector)

```river
otelcol.receiver.otlp "default" {
  grpc { endpoint = "0.0.0.0:4317" }
  http { endpoint = "0.0.0.0:4318" }
  output {
    metrics = [otelcol.processor.batch.default.input]
    traces  = [otelcol.processor.batch.default.input]
    logs    = [otelcol.processor.batch.default.input]
  }
}

otelcol.processor.batch "default" {
  output {
    metrics = [otelcol.exporter.prometheus.mimir.input]
    traces  = [otelcol.exporter.otlp.tempo.input]
    logs    = [otelcol.exporter.loki.default.input]
  }
}
```

## GitLab CI Pipeline Skeleton

```yaml
stages: [quality, build-image, scan, deploy]

variables:
  HARBOR_HOST: "harbor.ubiwhere.com"
  HARBOR_PROJECT: "ubp"
  APPLICATION_NAME: "$CI_PROJECT_NAME"
  IMAGE_TAG: "${HARBOR_HOST}/${HARBOR_PROJECT}/${APPLICATION_NAME}:${CI_COMMIT_SHORT_SHA}"

lint:
  stage: quality
  script: [pnpm check]

test:
  stage: quality
  script: [pnpm test]

build:image:
  stage: build-image
  image: moby/buildkit:v0.27.1-rootless
  script:
    - buildctl-daemonless.sh build
        --frontend dockerfile.v0
        --secret id=npm_registry,src=/tmp/npm_registry
        --secret id=npm_token,src=/tmp/npm_token
        --output type=image,name=${IMAGE_TAG},push=true

scan:image:
  stage: scan
  image: aquasec/trivy
  script: trivy image --exit-code 1 --severity CRITICAL ${IMAGE_TAG}

scan:sbom:
  stage: scan
  script: trivy image --format cyclonedx --output sbom.cdx.json ${IMAGE_TAG}

sign:
  stage: scan
  script: cosign sign ${IMAGE_TAG}
```
