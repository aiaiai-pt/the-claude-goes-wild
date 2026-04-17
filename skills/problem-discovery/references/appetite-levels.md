# Appetite Levels & Solution Types

## Appetite Calibration Matrix

| Signal from User | Likely Appetite | Reasoning |
|-----------------|----------------|-----------|
| "Can we just try it?" | 0 — Spike | Feasibility unknown |
| "It's a small fix/addition" | 1 — Small Batch | Bounded, clear scope |
| "We need a new feature/module" | 2 — Big Batch | Full shaping needed |
| "We need a new platform capability" | 3 — Multi-cycle | Needs phasing |
| "We need to rebuild X" | ⚠ Probe deeper | Could be 2 or 3, narrow the pain |

## Solution Type Decision Tree

```
Is the primary goal learning/validation?
├── YES → Is code quality important?
│   ├── NO → Dev/Spike
│   └── YES → Prototype
└── NO → Will real users see this?
    ├── NO → Prototype
    └── YES → Is this a long-term investment?
        ├── NO → MVP (ship fast, iterate or discard)
        └── YES → Does it need production resilience NOW?
            ├── NO → Production MVP (feature-flagged, monitored)
            └── YES → Real Production (full stack, hardened)
```

## Solution Type → Engineering Requirements

The engineering requirements scale with solution type. The specifics (which
Kubernetes cluster, which auth provider, which observability stack) come from
the active `platform-stack` skill. The **principles** below are stack-agnostic.

### Dev/Spike (Appetite 0)
- **Code**: Throwaway, exploratory
- **Tests**: None required
- **CI/CD**: None
- **Docs**: Decision notes only
- **Infra**: Local or dev cluster
- **Multi-tenancy**: Not required
- **Observability**: Console logs
- **Security**: Not scoped
- **Output**: "Can we do this? What did we learn?"

### Prototype (Appetite 0–1)
- **Code**: Working, readable, not production-grade
- **Tests**: Smoke tests for core flow
- **CI/CD**: Manual deploy
- **Docs**: README + basic API shape
- **Infra**: Dev environment, single tenant
- **Multi-tenancy**: Optional
- **Observability**: Basic logging
- **Security**: Basic auth only
- **Output**: "Here's what it looks like / how it works"

### MVP (Appetite 1–2)
- **Code**: Clean, follows project conventions
- **Tests**: Core paths covered (happy + main error paths)
- **CI/CD**: Basic pipeline (build, test, deploy to staging)
- **Docs**: API docs (OpenAPI), user-facing docs
- **Infra**: Staging environment
- **Multi-tenancy**: Instance-level minimum
- **Observability**: Structured logs, basic metrics
- **Security**: Authenticated, basic authorization
- **Output**: "Real users can use this for the core scenario"

### Production MVP (Appetite 2)
- **Code**: Production-grade, reviewed
- **Tests**: Full coverage (unit + integration + e2e for critical paths)
- **CI/CD**: Full pipeline with staging → production promotion
- **Docs**: Full API docs, ADRs, runbook basics
- **Infra**: Production, feature-flagged rollout
- **Multi-tenancy**: Full tenancy model (per platform profile)
- **Observability**: Full metrics/logs/traces
- **Security**: Full scan suite (SAST, SCA, secrets)
- **Output**: "This runs in production behind a feature flag"

### Real Production (Appetite 2–3)
- **Code**: Hardened, performance-optimized
- **Tests**: Full + load tests + chaos tests
- **CI/CD**: Full pipeline + rollback + canary/blue-green
- **Docs**: Full + architecture docs + runbooks + incident procedures
- **Infra**: Multi-env (dev/staging/prod) with DR
- **Multi-tenancy**: Full with tenant isolation guarantees
- **Observability**: Alerts + SLOs + dashboards
- **Security**: Full DevSecOps (SAST, DAST, SCA, SBOM, signing)
- **Output**: "This is our permanent production system"

## Appetite → Team Size

| Appetite | Recommended Team | Duration |
|----------|-----------------|----------|
| 0 — Spike | 1 dev | 1–2 days |
| 1 — Small Batch | 1 dev + 1 designer (optional) | 1–2 weeks |
| 2 — Big Batch | 2 devs + 1 designer | 6 weeks |
| 3 — Multi-cycle | 3 devs + 1 designer + 1 ops | 2× 6 weeks |

## Scope Hammering Techniques

1. **Cut a whole feature** rather than degrade all features
2. **Simplify the data model** — fewer entities, fewer relations
3. **Hardcode what you'd normally configure** — make it work for 80% case
4. **Skip the admin UI** — use direct DB/API for ops tasks
5. **Reduce the surface** — one vertical/domain, not all
6. **Defer multi-tenancy** — single-tenant first, isolation later
7. **Use existing platform primitives** — dashboard tool instead of custom UI
