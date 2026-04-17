# Test Pyramid

## The Shape: Trophy, Not Pyramid

For a data-heavy platform with an analytical pipeline, the classic test pyramid
(many unit, fewer integration, fewest E2E) becomes a **test trophy**:

```
        ╱  E2E (browser)        ╲        ← Few, critical paths only
       ╱  Performance             ╲       ← Key endpoints + pipeline throughput
      ╱  Integration               ╲      ← Service boundaries, real infra
     ╱  Contract (schema)           ╲     ← API + event schema validation
    ╱  Data Quality                  ╲    ← THE BIG LAYER — pipeline gates
   ╱  Unit                            ╲   ← Business logic, transforms
  ╱  Static (types / lint / SAST)      ╲  ← Catches bugs before tests run
```

The **data quality layer is wide** for data-centric systems because that's where
trust in downstream dashboards and APIs comes from.

For non-data systems, the shape reverts to a classic pyramid (fewer layers).

## Layer Details

### Layer 1: Static Analysis (every save / every commit)
| Concern | Tool Category | Examples |
|---------|---------------|----------|
| Type checking | Type checker | mypy, pyright (Python); tsc (TS) |
| Linting | Linter | ruff (Python); Biome / ESLint (JS/TS) |
| Security (SAST) | Security scanner | Semgrep |
| Formatting | Formatter | ruff format, Biome, Prettier |

Specific tool choices come from the active `platform-stack` skill.

### Layer 2: Unit Tests (every commit, < 2 min)
Test pure business logic in isolation. Mock external dependencies.

Assert on **observable outcomes** (returned data, side-effects), not on
internal method calls.

### Layer 3: Data Quality Gates (on pipeline run, on merge)
See `data-quality-gates.md`. This is the most important layer for data platforms.

### Layer 4: Contract Tests (every commit, < 3 min)
Validate API and event schemas without running full integration.

Tools typically used: `schemathesis` (OpenAPI-driven), JSON Schema validators,
Schema Registry clients for Kafka Avro/JSON.

### Layer 5: Integration Tests (on merge, < 10 min)
Test real system boundaries using disposable infra (testcontainers, docker-compose).
Never mock infrastructure — spin it up.

### Layer 6: Performance Tests (nightly + pre-release)
Measure RPS, latency percentiles, and pipeline throughput. Integrate with the
same observability stack as production so dashboards are familiar.

Typical performance targets (adjust per module):

| Endpoint Type | p50 | p95 | p99 | RPS target |
|--------------|-----|-----|-----|------------|
| Dashboard KPI (aggregated) | < 200ms | < 500ms | < 1s | 50 |
| Entity CRUD | < 50ms | < 150ms | < 300ms | 100 |
| List/search | < 300ms | < 800ms | < 1.5s | 30 |
| Ingestion throughput | — | — | — | 1000 events/s |

### Layer 7: E2E Tests (on merge + nightly)
Browser automation for critical paths only — don't test the whole UI.

### Layer 8: Exploratory Testing (pre-release, manual)
Structured session-based testing with charters:

```markdown
## Exploratory Test Charter

**Area**: {module / feature}
**Risk**: {what could go wrong — data, UX, security, performance}
**Duration**: 30 minutes
**Tester**: {name}

### Scenarios to Explore
- What happens with an empty tenant (no data)?
- What happens when switching tenants mid-session?
- What does the error state look like?

### Findings
- {timestamped findings}
```
