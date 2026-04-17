---
name: test-strategy
description: >
  Test strategy and planning framework. Covers test pyramid, data quality gates,
  API contract testing, E2E, performance, and CI/CD pipeline integration. Use
  when designing test plans, reviewing test coverage, or setting up test
  infrastructure. Stack-specific tools and patterns come from the active
  platform-stack skill.
---

# Test Strategy Skill

## When to Use
- Designing test plans for new modules
- Reviewing test coverage for existing systems
- Setting up CI/CD test pipelines
- Defining data quality gates for analytical pipelines
- Choosing test tools and patterns

## Process

1. Determine solution type (from `.architect-state.json`) — this drives test depth
2. Load `references/test-pyramid.md` for the test layer framework
3. Load `references/data-quality-gates.md` for analytical-pipeline testing (when applicable)
4. Load the active `platform-stack` skill to pick tools aligned with the canonical stack
5. For each module, identify test boundaries (API, data flow, UI, integration)
6. Design tests at each boundary
7. Define CI/CD pipeline stages for test execution
8. Write TEST-PLAN.md

## Key Principles

### 1. Test the Contracts
At every system boundary, validate the contract:
- **API boundary**: Response matches OpenAPI spec
- **Event boundary**: Messages match schema (AsyncAPI / JSON Schema / Schema Registry)
- **Data boundary**: Stored data matches expected schema/quality
- **Auth boundary**: Permission checks behave correctly
- **UI boundary**: User flows complete successfully

### 2. Data Quality Gates Are Non-Negotiable
Every data pipeline module MUST have quality gates at each layer transition.
See `references/data-quality-gates.md`.

### 3. Performance Testing Is Continuous
Performance runs are part of the CI/CD pipeline, not one-offs:
- **Baseline**: Established on first deployment
- **Regression**: Compared against baseline on each merge (< 10% degradation)
- **Load**: Full load test before production release
- **Soak**: Sustained load for Real Production only

### 4. Prefer the Preferred Tool
When the platform-stack skill names a preferred tool (e.g., Playwright for E2E),
new tests use it. Legacy tests in other frameworks keep running but aren't
extended.

### 5. Manual Testing Is Structured
Exploratory testing uses **session-based test charters**:
```
Charter: Explore {area} looking for {risk}
Duration: {timeboxed}
Notes: {findings recorded in structured format}
```

## Test Depth by Solution Type

| Solution Type | Unit | Integration | Contract | Data Quality | E2E | Performance | Exploratory |
|---------------|:----:|:----------:|:--------:|:------------:|:---:|:----------:|:-----------:|
| Dev/Spike | — | — | — | — | — | — | — |
| Prototype | Smoke | — | — | — | — | — | — |
| MVP | Core | Core paths | API shape | Bronze schema | Happy path | — | Light |
| Prod MVP | Full | Full | Full | All layers | Critical flows | Baseline | Structured |
| Real Prod | Full | Full + chaos | Full + versioned | All + anomaly | Full + a11y | Full + soak | Full |

## Gotchas
- Infrastructure-dependent tests must not silently fail — if infra is
  unreachable, spin it up (`docker compose up -d`) before skipping
- Integration tests with testcontainers need Docker-in-Docker or socket mount in CI
- Performance testing with OTel needs the same collector as production
- Browser E2E in CI typically needs only one browser project; add webkit/firefox
  only when explicitly required
