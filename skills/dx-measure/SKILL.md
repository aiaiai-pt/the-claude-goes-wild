---
name: dx-measure
description: Measure developer experience using DORA metrics and quantitative DX signals
allowed-tools: Read, Grep, Glob, Bash
---

# DX Measure

Measure developer experience for the specified project or team. $ARGUMENTS

## Process

1. **Collect DORA metrics**:
   - **Deployment Frequency**: How often do we deploy to production?
     - Source: deploy logs, CI/CD pipeline history, `gh release list`, deploy tags
     - Metric: deploys per day/week
     - Elite: multiple per day. High: weekly. Medium: monthly. Low: less than monthly.
   - **Lead Time for Changes**: Time from first commit to production
     - Source: `git log` timestamps + deploy timestamps
     - Metric: median hours from commit to production
     - Elite: < 1 hour. High: < 1 day. Medium: < 1 week. Low: > 1 week.
   - **Change Failure Rate**: % of deployments causing a failure
     - Source: rollbacks, hotfixes, incident count correlated with deploys
     - Metric: failed deploys / total deploys × 100%
     - Elite: < 5%. High: < 10%. Medium: < 15%. Low: > 15%.
   - **Mean Time to Restore (MTTR)**: Time from failure detection to resolution
     - Source: incident timestamps (detection to resolution)
     - Metric: median minutes from detection to restore
     - Elite: < 1 hour. High: < 1 day. Medium: < 1 week. Low: > 1 week.
   - **Signal**: four numeric metrics, each classifiable as Elite/High/Medium/Low

2. **Collect build experience metrics**:
   - **CI build time**: Average pipeline duration for PRs
     - Source: `gh run list --json` or CI platform API
     - Track: p50, p95, trend over 30 days
   - **Local build time**: Time to build and test locally
     - Source: sample from recent developer activity or timed test run
   - **PR cycle time**: Time from PR opened to merged
     - Source: `gh pr list --json createdAt,mergedAt`
     - Break down: time to first review, review cycles, merge delay
   - **CI retry rate**: How often are CI runs retried (flaky failures)?
     - Source: CI platform data — runs with same commit hash
   - **Signal**: all in minutes/hours, trend direction

3. **Collect onboarding metrics** (if applicable):
   - Time from repo clone to first successful local run
   - Number of manual setup steps
   - Documentation freshness: days since README/getting-started was updated
   - **Signal**: setup time in minutes, step count, doc age in days

4. **Identify friction points**:
   - Any DORA metric in Medium or Low category → friction source
   - CI build time > 10 minutes → developer patience threshold exceeded
   - PR cycle time > 2 days → review bottleneck
   - CI retry rate > 10% → flaky test problem
   - Setup time > 30 minutes → onboarding friction
   - Correlate friction with developer behavior:
     - Are devs batching commits (large PRs) → likely slow CI pushing batch behavior
     - Are devs skipping tests locally → likely slow local test suite
     - Are devs deploying less often → likely deploy friction or fear

5. **Compare against baseline** (if previous measurement exists):
   - For each metric, calculate delta:
     - Improving, stable, or degrading?
     - Rate of change (how fast is it improving/degrading?)
   - Flag any metric that degraded by > 20% since last measurement

6. **Produce report**:

```
## Developer Experience Report
**Date**: YYYY-MM-DD
**Scope**: [project/team]

## DORA Metrics
| Metric | Value | Classification | Trend | Delta vs Last |
|--------|-------|---------------|-------|--------------|
| Deploy Frequency | N/week | Elite/High/Med/Low | ↑↓→ | +N% |
| Lead Time | N hours | Elite/High/Med/Low | ↑↓→ | +N% |
| Change Failure Rate | N% | Elite/High/Med/Low | ↑↓→ | +N% |
| MTTR | N hours | Elite/High/Med/Low | ↑↓→ | +N% |

## Build Experience
| Metric | Value | Threshold | Status | Trend |
|--------|-------|-----------|--------|-------|
| CI build time (p50) | N min | < 10 min | OK/SLOW | ↑↓→ |
| CI build time (p95) | N min | < 15 min | OK/SLOW | ↑↓→ |
| PR cycle time | N hours | < 48 hours | OK/SLOW | ↑↓→ |
| CI retry rate | N% | < 10% | OK/HIGH | ↑↓→ |

## Friction Points
| Issue | Impact | Affected Metric | Recommended Action |
|-------|--------|----------------|-------------------|

## Trends (30-day)
[Time series or sparklines for key metrics]

## Recommendations
1. [Highest-impact improvement with expected effect]
2. [Second priority]
3. [Third priority]
```

## Rules

- DORA metrics are TRENDS, not targets — improving the trend matters more than
  hitting an absolute number
- Measure from real data (git, CI, deploys), not surveys alone — surveys are lagging
  indicators, metrics are leading
- Compare against your OWN baseline, not industry benchmarks — context matters more
  than percentiles
- Friction detection should lead to ACTION, not just dashboards — if nobody acts on
  the measurement, stop measuring it
- Developer time is expensive — a 1-minute CI improvement × 50 runs/day = nearly an
  hour saved daily. Quantify in developer-hours.
- Don't optimize what you can't measure — establish baselines before starting improvements
- DORA classification (Elite/High/Medium/Low) is from the Accelerate research — it
  provides context but is not prescriptive
- PR cycle time should exclude weekends/holidays for fair comparison
- Deploy frequency can be artificially inflated by splitting deploys — measure meaningful
  deployments only
