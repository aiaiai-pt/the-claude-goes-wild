# Architectural Anti-Patterns (UBP)

From the platform assessment (2026-04-10). Architect agents **MUST** refuse to
propose a design that reinforces any of these — recommend the documented
alternative instead.

`validate-architect-output.py` flags module specs that reinforce an AP.

---

## AP-1: Dual Backend in Ontology Repo (Severity: HIGH)

**Context**: `ontology-core` (Django) and `ontology-core-v2` (FastAPI) coexist
in the same repository. The legacy Django version still manages geo-layer
permissions. Two ORMs, two auth stacks, two pipelines in one repo with no
published cut-over plan.

**Detection**: New module proposes adding to the Django `ontology-core` codebase.

**Refuse + recommend**:
- New features go in `ontology-core-v2` (FastAPI)
- Legacy Django ontology is in deprecation — migrate, don't extend

---

## AP-2: Monolith with Three Async Runtimes (Severity: HIGH)

**Context**: `multivertical-django` runs Django WSGI (Daphne for WebSockets),
Celery (Redis broker), and Zeebe/pyzeebe (with `asyncio.run()` sync bridge)
in the same codebase. Event loop contention under load. The platform's
declared async runtime is **Temporal** (ADR-003 recommendation).

**Detection**: Module proposes Celery, Zeebe, or any new async runtime.

**Refuse + recommend**:
- Use **Temporal** for durable async workflows
- Use **Dagster** for data pipelines (already canonical)
- Use **K8s Jobs** for ad-hoc batch
- Do NOT add Celery, Zeebe, RQ, Airflow, or any other runtime — consolidation target is Temporal

---

## AP-3: Air Quality Data Bypass (Severity: HIGH)

**Context**: Kunak/Monitar connectors write directly to per-provider
PostgreSQL, bypassing MQTT/Kafka/Iceberg entirely. Air quality data is siloed
and cannot be queried via Trino alongside traffic and weather data. The EMQX
bridge has an `air-quality-vertical` schema slot suggesting integration was
intended but never built.

**Detection**: Data module proposes direct DB ingestion bypassing Kafka+Iceberg bronze.

**Refuse + recommend**:
- New ingestion paths go through EMQX → Kafka → Bronze (for real-time)
  or dlt + Dagster → Bronze (for batch)
- If integrating an existing siloed source, migration path includes adding to the EMQX bridge

---

## AP-4: Opaque Internal Services (Severity: CRITICAL)

**Context**: `martha-api` (3 deployments) and `ubp-core` are deployed from
Harbor images but have no source repo in the GitLab group. Their API contracts,
dependencies, and domain responsibilities are undocumented.

**Detection**: Module proposes a new service without documenting its API
contract, source repo, and operational ownership.

**Refuse + recommend**:
- Every new service has a source repo in `gitlab.ubiwhere.com/cities/urban-platform-v2/`
- Every service has an OpenAPI spec + README + runbook at minimum
- Module spec must declare the `component` and its lifecycle owner

---

## AP-5: Context Broker Deployed but Unwired (Severity: HIGH)

**Context**: Orion-LD 1.12.0 with Mintaka is fully deployed. Nothing publishes
to it. Nothing subscribes from it. It consumes infrastructure resources with
zero production value. Status: `"fiware": {"enabled": false}` in all prod
instances.

**Detection**: Module proposes new NGSI-LD publication to Orion-LD.

**Refuse + recommend**:
- **Do not** wire new Orion-LD publication paths until **ADR-001** (Orion integration
  strategy) is resolved — see `platform-gaps.md` G3
- If NGSI-LD compliance is truly required, flag as blocked and escalate to
  architecture for ADR-001 resolution
- Alternative: build the new module to publish via Trino queries; adapt to
  NGSI-LD later once the canonical path is decided

---

## AP-6: Untyped MFE Contract (Severity: MEDIUM)

**Context**: `backoffice-modules` receives data from Django via `data-config`
HTML attribute. The shape is not typed, not versioned, not formally documented.
API calls in modules use raw `fetch` against local TypeScript types. Backend
changes silently break modules.

**Detection**: Frontend module proposes ad-hoc data passing from backend (e.g.,
embedded in HTML attributes, untyped fetch).

**Refuse + recommend**:
- Frontend modules consume typed APIs (OpenAPI-generated clients)
- Contracts versioned with the backend component (SemVer)
- `@ubiwhere/schema-renderer` YAML is versioned per schema-renderer release

---

## AP-7: Hardcoded Credentials in Source (Severity: CRITICAL)

**Context**: The ontology `docker-compose.yml` contains a plaintext Nexus PyPI
token, Keycloak client secrets, and UMS credentials. Development-only, but
they exist in repository history.

**Detection**: Module proposes storing credentials in `docker-compose.yml`,
checked-in `.env`, Dockerfile ENV, or any committed file.

**Refuse + recommend**:
- Use GCP Secret Manager + External Secrets Operator for runtime secrets
- Use HashiCorp Vault for app-level secrets
- Use `.env.example` (checked in) with placeholder values; actual `.env` stays in `.gitignore`
- CI/CD uses GitLab CI variables (Protected + Masked) + BuildKit `--secret` mounts
- Rotate any exposed credentials immediately (R2)

---

## Detection in `validate-architect-output.py`

The validator runs heuristic scans on module specs:

| AP | Pattern scanned |
|---|---|
| AP-1 | Mentions of adding to `ontology-core` (not `-v2`) or extending legacy Django ontology |
| AP-2 | Mentions of `celery`, `zeebe`, `camunda`, `airflow` in new-module spec |
| AP-3 | Data module with direct DB ingestion bypassing Kafka+Iceberg |
| AP-4 | Service spec without `component`, `source_repo`, `openapi_spec` fields |
| AP-5 | Mentions of `ngsi-ld`, `orion-ld`, `fiware` in new module |
| AP-6 | Frontend module with `data-config` / untyped fetch / raw JSON passing |
| AP-7 | Any spec with plaintext credentials, tokens, or passwords |

Each is a warning (not an error) so the architect can mark exceptions with
rationale in an ADR — but reviewers see them clearly.
