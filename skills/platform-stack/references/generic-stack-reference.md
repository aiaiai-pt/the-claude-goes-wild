# Generic Stack Reference

Stack-agnostic principles. Use these when no profile is active. For real
technology choices, install a platform profile.

## Principles (not technologies)

### Compute
- Containerized, orchestrated (Kubernetes preferred when scale warrants)
- Stateless services; state lives in dedicated backing services
- Horizontal scalability: design for N replicas from day 1

### Storage
- Separate operational state (transactional DB) from analytical data (columnar / lake)
- Multi-tenancy primitive in every data model (from Spike onwards — defer only for throwaway)
- Versioned schemas; avoid "schemaless" as an excuse to skip contracts

### APIs
- REST with OpenAPI 3.1 for app-to-app
- Event-driven for async integration (with schema contracts)
- GraphQL only when client-driven queries clearly dominate

### Identity & Authorization
- OIDC-based authentication (Keycloak, Auth0, Okta, Cognito — pick one)
- Fine-grained authorization via a dedicated engine (SpiceDB, OPA, OpenFGA) — not ad-hoc roles in code
- JWT claims carry identity; authorization checks happen per-resource

### Events
- Canonical event envelope (event_id, correlation_id, timestamp, schema_version, payload)
- Topic naming convention captured in an ADR
- Schema registry or inline AsyncAPI — never freeform JSON

### Observability
- OpenTelemetry for traces, metrics, logs
- Structured JSON logs (no printf)
- One dashboard per service + one SLO dashboard per tenant

### CI/CD
- Trunk-based or short-lived feature branches
- Pipeline stages: lint → test → build → scan → deploy
- GitOps for deployments (ArgoCD, Flux, or equivalent)
- Conventional Commits + semantic-release for version management

### Security
- Secrets never in code — use a secrets manager with envelope encryption
- Workload Identity (no long-lived service account keys)
- SAST + SCA + secret scan + SBOM in every pipeline
- Container image signing (Cosign)

## Profile-Provided Content

For actual technology defaults (e.g., "PostgreSQL for operational state, Iceberg
+ Trino for analytical"), install a platform profile. The profile ships with:

- `stack-reference.md` — canonical stack with specific technologies
- `appetite-stack-map.md` — recommended stack per Shape Up appetite tier
- `platform-topology.md` — actual deployed topology
- Any additional profile-specific references
