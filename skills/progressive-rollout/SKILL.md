---
name: progressive-rollout
description: Manage a progressive deployment lifecycle with automated promote/rollback decisions
---

# Progressive Rollout

Manage a progressive rollout for the specified deployment. $ARGUMENTS

## Process

1. **Pre-deploy checks**:
   - Verify all quality gates passed (QFG certification, SFG scan, code review)
   - Verify the deployment artifact exists and is tagged
   - Verify monitoring is in place for the target service (RED metrics, health check)
   - Verify rollback mechanism is available (previous version tagged, rollback script ready)
   - If any pre-check fails → **ABORT** with specific failure reason

2. **Stage 1 — Canary (1% traffic)**:
   - Deploy the new version to canary instance(s)
   - Route 1% of production traffic to canary
   - Start bake timer: default 10 minutes (configurable per service)
   - Collect metrics during bake period:
     - Error rate: canary vs stable pods
     - Latency (p50, p95, p99): canary vs stable pods
     - Business KPIs: conversion rate, key action rate (if applicable)
   - Collect log diff: new error messages in canary not present in stable
   - **Signal**: error rate delta %, latency delta %, new error patterns count

3. **Canary analysis**:
   - Compare canary metrics against stable metrics:

   | Metric | PROMOTE | PAUSE | ROLLBACK |
   |--------|---------|-------|----------|
   | Error rate delta | < 0.5% | 0.5-1% | > 1% |
   | p99 latency delta | < 50% | 50-100% | > 100% |
   | New error patterns | 0 | 1-2 (unknown severity) | > 2 or 1 known-critical |
   | Business KPI delta | > -1% | -1% to -5% | > -5% |

   - LLM analysis of log diff: are the new errors in canary concerning?
     Look for: unhandled exceptions, panic/crash patterns, auth failures,
     data corruption indicators, dependency failures
   - **Decision**: PROMOTE / PAUSE (human review) / ROLLBACK

4. **Stage 2 — Staged expansion (if promoted)**:
   - 10% traffic: bake 5 minutes, same analysis as canary
   - 50% traffic: bake 5 minutes, same analysis
   - 100% traffic: deployment complete
   - At each stage, re-run the same metric comparison against the now-smaller stable group
   - Any stage can trigger rollback using the same thresholds

5. **Rollback procedure** (if triggered):
   - Route all traffic back to stable version (0% to new version)
   - Verify stable version is handling all traffic correctly
   - **Signal**: stable error rate returned to pre-deploy baseline yes/no
   - Auto-create issue with:
     - Metrics snapshot at time of rollback decision
     - Log diff showing canary-specific errors
     - Suspected root cause (if identifiable from logs/metrics)
     - Link to the deployment commit/PR

6. **Produce report**:

```
## Rollout Report
**Date**: YYYY-MM-DD
**Service**: [name]
**Version**: [old] → [new]

## Stages
| Stage | Traffic | Duration | Error Delta | Latency Delta | Decision |
|-------|---------|----------|-------------|---------------|----------|
| Canary | 1% | Nmin | N% | N% | PROMOTE/ROLLBACK |
| 10% | 10% | Nmin | N% | N% | PROMOTE/ROLLBACK |
| 50% | 50% | Nmin | N% | N% | PROMOTE/ROLLBACK |
| 100% | 100% | — | — | — | COMPLETE |

## Log Analysis
- New error patterns in canary: N
- [Pattern descriptions if any]

## Result
**DEPLOYED** / **ROLLED BACK**
[If rolled back: issue link, suspected cause]
```

## Rules

- Canary deployment is MANDATORY — no direct 0→100% deploys
- Rollback is always safe and does not require human approval
- PAUSE (human review) is for ambiguous signals only — clear pass or fail should be automatic
- Bake times are minimums, not maximums — extend if metrics are noisy
- Business KPI comparison requires enough traffic to be statistically meaningful —
  skip at canary (1%) if traffic is low, check at 10%+
- Log analysis is best-effort — it supplements metric-based decisions, doesn't override them
- A rolled-back deployment MUST have an auto-created issue — rollbacks without follow-up will recur
- Second consecutive rollback for the same change escalates to human — the issue isn't transient
- Never promote while metrics are still converging — wait for the bake timer even if metrics look good early
