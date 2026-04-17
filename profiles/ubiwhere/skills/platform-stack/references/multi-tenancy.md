# Multi-Tenancy (UBP)

## The Hierarchy

```
Instance (client organization — CIRA, AMP, TS, VDL, …)
└── Tenant (municipality — aveiro, agueda, gondomar, …)
```

Per ontology ADR-0001 (tenancy):
- **Instance**: deployed **per client** (not per tenant)
- **Tenant**: data ownership boundary inside an instance
- A tenant nested under a client may graduate to a full client later; the
  ontology must replicate to the new instance without breaking pipelines

## Enforcement Layer — Service, NOT Database

Per ontology ADR-0001, multi-tenancy is enforced at the **service layer**, not
at the database layer:

- **Do NOT** use PostgreSQL row-level security for tenancy. Do NOT rely on
  `current_setting('app.current_tenant_id')` with RLS policies.
- **DO** enforce tenancy in UMS v2 / SpiceDB / ACL predicates compiled into SQL.
- **DO** carry tenant context via `X-Tenant-Id` header (REST) / `x-tenant-id`
  metadata (gRPC).

## Request-Level Tenancy (from fleet-manager multi-tenancy.md)

| Transport | Mechanism |
|---|---|
| REST | `X-Tenant-Id` request header |
| gRPC | `x-tenant-id` metadata key |

**Read behavior** (per ACL system):

| Tenant header | Reads return |
|---|---|
| Yes (`X-Tenant-Id: T`) | rules/records where `tenant_id = T` OR `tenant_id IS NULL` |
| No (header absent) | all rules/records (no tenant filter applied — relies on other access controls) |

**Write behavior**:

| Tenant header | Write sets |
|---|---|
| Yes (`X-Tenant-Id: T`) | `tenant_id = T` on the created/updated record |
| No (header absent) | `tenant_id = NULL` (global record) |

## Critical Invariants

1. **Tenant immutability**: once a record has a `tenant_id`, it cannot be
   changed. Moving between tenants is delete + create. This prevents silent
   visibility drift.
2. **Cross-tenant mutation guard**: if a PATCH/DELETE request carries
   `X-Tenant-Id` and the target record has a different non-NULL `tenant_id`,
   reject with **404** (not 403 — avoid leaking existence).
3. **Tenant from header only, never from payload**: the API must NOT accept a
   `tenant_id` field in request bodies. The tenant always comes from the
   header, verified by the identity layer.
4. **UMS does not maintain a tenant registry**: tenant ID validity is the
   caller's responsibility (API gateway, identity provider).
5. **Share grants** may exist: data from one tenant can be shared to another
   via explicit share grants at the service layer (not DB).

## Tenancy by Platform Layer

| Layer | Isolation Strategy | Key |
|---|---|---|
| **DNS** | `{tenant}.{instance}.ubp.pt` | URL path |
| **Keycloak** | Realm per **client** (not instance), roles per tenant, realm sync across client's instances | JWT claims |
| **UMS v2 + SpiceDB** | `tenant:{id}` relations; grant predicates compiled to SQL | Row-level filter |
| **Iceberg** | Namespace per instance (`{instance}.{layer}.{domain}`); tenant segment in path | Namespace + path |
| **Trino** | Catalog per instance, schema per layer/domain | Query-level |
| **PostgreSQL** | `tenant_id` column (nullable = global) | Column + service-layer enforcement |
| **Kafka** | Tenant segment in topic path: `{env}.{instance}.{tenant}.{domain}.{entity}.{event}.v{N}` | Topic isolation |
| **GCS** | `ubp-{instance}-lakehouse-{env}/{tenant}/...` | Path isolation |
| **Metabase** | Collection per tenant, sandboxed Trino queries | Row-level |
| **Grafana** | Datasource per instance, label per tenant | Label filter |

## Database Pattern (operational state)

```sql
CREATE TABLE {entity} (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id TEXT NULL,                   -- NULL = global; non-NULL = tenant-scoped
    -- ... domain columns
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Compound index for tenant-scoped lookups
CREATE INDEX idx_{entity}_tenant_lookup
    ON {entity} (tenant_id, /* ...other lookup columns... */);

-- NO ROW-LEVEL SECURITY policies — enforce at service layer
```

## Resolve Path (UNION ALL for tenant + global)

Avoid `OR tenant_id IS NULL` scans. Use UNION ALL for index seeks:

```sql
-- Tenant-specific rules
SELECT ... FROM acl_rules r WHERE r.tenant_id = $tenant_id AND ...
UNION ALL
-- Global rules (tenant_id IS NULL)
SELECT ... FROM acl_rules r WHERE r.tenant_id IS NULL AND ...
```

## Middleware Pattern (FastAPI)

```python
from fastapi import Request, Header

async def tenant_middleware(request: Request, x_tenant_id: str | None = Header(None)):
    request.state.tenant_id = x_tenant_id
    # Pass tenant_id to UMS when resolving grants
    return request
```

## Admin / List Path vs Resolve Path

- **Resolve** (user-facing queries): return rules/records where `tenant_id = T`
  OR `tenant_id IS NULL` (inclusive).
- **Admin list** (management endpoints): exact match only. If the admin wants
  to see global records, they must explicitly filter (`tenant_id=__null__` or
  `include_global=true`).

## SDK Pattern

SDK client methods accept an optional `tenant_id: str | None = None`. When
provided, it's added to the request headers/metadata. The SDK does not know
what the value means — it just propagates it.

## Rules

- **Never** query across tenants without explicit cross-tenant permission
- **Always** include `tenant_id` in Kafka topic path
- **Always** validate tenant access via UMS v2 / SpiceDB before data access
- Platform-admin can see all tenants; instance-admin can see all tenants in
  their instance
- Citizen users are scoped to a single tenant
- Tenant is NEVER in the request body — always from the header
- Tenant-specific records are immutable on `tenant_id` — delete + create to move
