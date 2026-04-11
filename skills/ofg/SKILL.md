---
name: ofg
description: Ops Flow - progressive rollout orchestration, SLO monitoring, incident detection, self-healing
argument-hint: [scope: assess | instrument | deploy | watch | respond | health-report | full]
---

# OFG — Ops Flow, Go

Run the ops process for the specified scope: $ARGUMENTS

If no scope is specified, run Phase 4 (Watch) as the default — check current production health.

## Phase 1: Assess

**When**: At project onboarding or when establishing operational baselines.
**Purpose**: Map current infrastructure state, SLOs, and monitoring gaps.

1. **Inventory infrastructure**:
   - Services and their dependencies (database, cache, queue, external APIs)
   - Deployment targets (Kubernetes, ECS, Lambda, bare metal, PaaS)
   - Current monitoring setup (what's instrumented, what's dark)
   - Existing SLOs and error budgets (or lack thereof)
   - Alerting rules and on-call configuration
   - **Signal**: service count, instrumented %, SLO coverage %

2. **Identify monitoring gaps**:
   - Services without health checks
   - Endpoints without latency/error monitoring
   - Dependencies without circuit breakers
   - Missing SLO definitions for user-facing services
   - Alert fatigue indicators (too many alerts, too few actionable)

3. **Produce infrastructure assessment**:

```
## Infrastructure Assessment
**Date**: YYYY-MM-DD

## Service Inventory
| Service | Dependencies | Monitored | SLO Defined | Health Check |
|---------|-------------|-----------|-------------|-------------|

## Monitoring Coverage
- Services instrumented: N/N (N%)
- SLOs defined: N/N
- Error budgets tracked: N/N
- Alerting rules: N (N actionable, N noise candidates)

## Gaps
- [ ] [Specific gap with recommended action]
```

## Phase 2: Instrument

**When**: During BUILD when new services or endpoints are added.
**Purpose**: Ensure observability is built in, not bolted on.

4. Verify OpenTelemetry instrumentation for new/changed services:
   - Traces: are spans created for incoming requests, outgoing calls, database queries?
   - Metrics: are RED metrics (Rate, Error, Duration) being emitted?
   - Logs: are structured logs (JSON) with correlation IDs being produced?
   - **Signal**: instrumentation present yes/no per service endpoint

5. Define SLOs for new user-facing services:
   - Availability SLO: e.g., 99.9% of requests succeed (non-5xx)
   - Latency SLO: e.g., 99% of requests complete within 500ms
   - Error budget: calculated from SLO (e.g., 99.9% = 43.2 minutes downtime/month)
   - Burn rate alerts: 1x, 2x, 10x burn rate windows

6. **Decision rules**:
   - New user-facing endpoint without RED metrics → **BLOCK SHIP**
   - New service without health check → **BLOCK SHIP**
   - Missing SLO for user-facing service → **WARN** (recommend defining before next bet)

## Phase 3: Deploy

**When**: During SHIP. Manages the progressive rollout.
**Purpose**: Safe, observable deployment with automated rollback.

7. Run `/progressive-rollout` for the current deployment:
   - Stage 1 — Canary (1%): Deploy to canary. Watch error rate, latency, business
     KPIs for the configured bake time (default: 10 minutes).
   - Stage 2 — Analysis: Compare canary metrics against stable pod metrics.
     LLM-analyze log differences between canary and stable for novel errors.
   - Stage 3 — Staged expansion: If canary healthy, expand to 10% → 50% → 100%.
     Each stage has its own bake time (5 min → 5 min → observe).
   - **Signal per stage**: error rate delta, latency delta, new error patterns (yes/no)

8. **Decision rules for promote/rollback**:
   - Error rate delta > 1% (canary vs stable) → **ROLLBACK**
   - p99 latency delta > 100% (canary vs stable) → **ROLLBACK**
   - New error pattern in canary logs not present in stable → **PAUSE + human review**
   - All metrics within threshold → **PROMOTE to next stage**
   - Rollback triggers auto-create of an issue with: metrics snapshot,
     log diff, suspected cause

9. **Decision rules for human escalation during deploy**:
   - Rollback triggered → **LOG**. Auto-rollback is always safe. Notify human.
   - Second consecutive rollback for same change → **ALERT human**. Something is wrong
     beyond a transient issue.
   - Deploy to a new service/region for first time → **REQUIRE human approval** for
     final promotion to 100%.

## Phase 4: Watch

**When**: Always-on. Continuous production monitoring.
**Purpose**: Detect issues before users do.

10. Monitor continuously:
    - **Error budget burn rate**: How fast are we consuming our error budget?
      - Normal: < 1x burn rate (will last the full window)
      - Elevated: 1-2x burn rate (will exhaust before window ends)
      - Critical: > 2x burn rate (rapid budget consumption)
    - **SLO compliance**: Are we meeting our latency and availability targets?
    - **Dependency health**: Are external services responding normally?
    - **Infrastructure metrics**: CPU, memory, disk, pod restarts, node health
    - **Cost anomalies**: Spending outside expected range?

11. **Decision rules based on deterministic signals**:
    - Error budget burn rate > 2x → **ALERT** with projected exhaustion time
    - Error budget burn rate > 10x → **PAGE** (wake someone up)
    - SLO breached (availability or latency) → **ALERT** with contributing factors
    - Pod restart loop (> 3 restarts in 10 min) → **AUTO-REMEDIATE** (scale up, investigate)
    - Dependency timeout rate > 5% → **OPEN circuit breaker** + alert
    - Cost > 150% of 30-day average → **ALERT** with breakdown by service

## Phase 5: Respond

**When**: Triggered by Phase 4 alerts or external incident reports.
**Purpose**: Fast detection, diagnosis, and resolution.

12. Run `/incident-response` when an incident is detected:
    - Gather context: What changed recently? (deploys, config, traffic patterns)
    - Correlate: Match anomaly timing with events from deploy log, config changes,
      dependency status pages
    - Diagnose: Build a causal hypothesis from available telemetry
    - Remediate: If the pattern is known and the fix is safe, apply automatically

13. **Decision rules for auto-remediation**:
    - Recent deploy correlates with error spike → **AUTO-ROLLBACK** the deploy
    - Pod OOMKilled → **AUTO-SCALE** memory limit (within pre-approved bounds)
    - Circuit breaker tripped on dependency → **FALLBACK** to cached/degraded mode
    - Known transient failure pattern → **RETRY** with backoff
    - All other patterns → **ESCALATE to human** with pre-populated incident summary

14. **Post-incident**:
    - Auto-generate incident report: timeline, root cause, impact, fix applied
    - Create follow-up issue if root cause needs permanent fix
    - Update known pattern library if a new auto-remediation was successful
    - Feed learnings to SENSE

## Phase 6: Health Report

**When**: On demand or scheduled (daily/weekly).
**Purpose**: Production health summary for human review.

15. Generate health report:

```
## Production Health Report
**Date**: YYYY-MM-DD
**Period**: [timeframe]

## SLO Status
| Service | SLO Target | Current | Error Budget Remaining | Burn Rate |
|---------|-----------|---------|----------------------|-----------|

## Incidents (This Period)
| Incident | Severity | Duration | Root Cause | Auto-remediated? |
|----------|----------|----------|------------|-----------------|

## Deployments
| Service | Deployments | Rollbacks | Success Rate |
|---------|------------|-----------|-------------|

## Infrastructure
- Total pods: N (healthy: N, unhealthy: N)
- Avg CPU utilization: N%
- Avg memory utilization: N%
- Cost this period: $N (delta vs last period: N%)

## Dependency Health
| Dependency | Availability | p99 Latency | Circuit Breaker Trips |
|-----------|-------------|-------------|----------------------|

## Alerts
- Total alerts: N
- Actionable: N
- Noise candidates: N (recommend tuning)

## Verdict
- SLOs: ALL MET / N BREACHED
- Error budgets: HEALTHY / N AT RISK
- Incidents: N (N auto-remediated, N human-resolved)
- **Overall**: HEALTHY / DEGRADED / CRITICAL
```

## Rules

- Auto-rollback is ALWAYS safe to execute without human approval — it's reverting to a known-good state
- Auto-remediation of KNOWN patterns is safe (scale up, retry, circuit break, rollback)
- Novel incidents MUST escalate to human — never guess at a fix for an unseen pattern
- Never silence an alert without human approval — alert fatigue is real but suppressing is worse
- SLOs must be defined BEFORE the service goes to production, not after
- Error budget burn rate is the primary operational signal — not uptime percentage
- Canary deployments are mandatory for all production changes — no YOLO deploys
- Rollback on second consecutive failure for the same change requires human investigation
- Cost alerts use relative thresholds (150% of baseline), not absolute dollar amounts
- Post-incident follow-ups are mandatory — an incident without a follow-up will recur
