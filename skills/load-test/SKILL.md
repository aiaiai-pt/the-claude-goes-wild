---
name: load-test
description: Generate and run performance baseline tests for changed endpoints
---

# Load Test

Generate and run performance tests for the specified endpoints. $ARGUMENTS

## Process

1. **Identify target endpoints**:
   - If arguments specify endpoints: use those
   - If invoked during BUILD/SHIP: target new or changed endpoints
   - Skip: static asset endpoints, health checks, internal-only debug endpoints
   - For each endpoint, determine:
     - Expected request rate (from current traffic or product expectations)
     - Typical payload size
     - Authentication requirements
     - Dependencies (database queries, external API calls, cache lookups)

2. **Check for existing baselines**:
   - Look for previous load test results in:
     - `dev_docs/load-tests/` or equivalent
     - CI artifacts from previous runs
   - If baseline exists: this run will compare against it
   - If no baseline exists: this run establishes the baseline

3. **Generate k6 test scripts** (or Gatling if project prefers):
   - For each target endpoint:
     - Set up authentication (reuse test tokens/sessions)
     - Define realistic request payloads (use representative data, not empty bodies)
     - Define three load phases:

   ```
   Phase 1 — Ramp Up (30s):   0 → target VUs
   Phase 2 — Sustained (120s): hold target VUs
   Phase 3 — Spike (30s):      2x target VUs
   Phase 4 — Recovery (30s):   back to target VUs
   ```

   - Set thresholds based on baseline or defaults:
     - p95 latency < 500ms (or baseline × 2)
     - p99 latency < 1000ms (or baseline × 2)
     - Error rate < 1% during sustained
     - Error rate < 5% during spike

4. **Run the tests**:
   - Execute against staging environment (NEVER production)
   - Capture metrics per phase:
     - p50, p95, p99 latency
     - Requests per second (actual vs target)
     - Error rate by status code
     - Response time distribution
   - **Signal**: all numeric, all deterministic for the same load pattern

5. **Compare against baseline** (if exists):
   - For each metric, calculate delta:
     - `delta = (current - baseline) / baseline × 100%`
   - Apply thresholds:

   | Metric | PASS | WARN | FAIL |
   |--------|------|------|------|
   | p95 latency | delta < 20% | 20-100% | > 100% (2x baseline) |
   | p99 latency | delta < 50% | 50-200% | > 200% (3x baseline) |
   | Error rate (sustained) | < 1% | 1-3% | > 3% |
   | Error rate (spike) | < 5% | 5-10% | > 10% |
   | Throughput | delta > -10% | -10% to -30% | > -30% drop |

6. **Produce report**:

```
## Load Test Report
**Date**: YYYY-MM-DD
**Environment**: staging
**Scope**: [endpoints]

## Results Per Endpoint
### [METHOD] [path]
| Phase | Duration | VUs | RPS | p50 | p95 | p99 | Errors |
|-------|----------|-----|-----|-----|-----|-----|--------|
| Ramp  | 30s      |     |     |     |     |     |        |
| Sustain| 120s    |     |     |     |     |     |        |
| Spike | 30s      |     |     |     |     |     |        |
| Recover| 30s     |     |     |     |     |     |        |

### Baseline Comparison
| Metric | Baseline | Current | Delta | Verdict |
|--------|----------|---------|-------|---------|
| p95    |          |         |       | PASS/WARN/FAIL |
| p99    |          |         |       | PASS/WARN/FAIL |
| Error% |          |         |       | PASS/WARN/FAIL |
| RPS    |          |         |       | PASS/WARN/FAIL |

## Overall Verdict
**PASS / WARN / FAIL**
[If WARN/FAIL: specific endpoints and metrics that triggered]

## Baseline Update
- [If no previous baseline: "New baseline established"]
- [If current run is better: "Recommend updating baseline"]
- [If regression: "Keep existing baseline"]
```

7. **Store results**:
   - Save the report to `dev_docs/load-tests/[endpoint]-[date].md`
   - If this is a new baseline or improvement, update the baseline file

## Rules

- NEVER run load tests against production
- Always use realistic payloads — empty requests don't represent real load
- Authentication must mirror real-world usage (don't skip auth for convenience)
- The spike phase is essential — systems that only work under expected load are fragile
- If no baseline exists, the first run BECOMES the baseline — don't skip it
- Thresholds are based on RELATIVE change vs baseline, not absolute values,
  because different endpoints have different natural latencies
- Report all numbers — let downstream processes apply their own thresholds too
- If the test environment is significantly different from production (fewer instances,
  smaller DB), note this prominently — absolute numbers won't transfer
