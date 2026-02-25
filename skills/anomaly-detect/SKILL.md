---
name: anomaly-detect
description: Detect and diagnose metric anomalies by comparing against historical baselines
---

# Anomaly Detect

Detect and diagnose anomalies in the specified metrics. $ARGUMENTS

## Process

1. **Identify metrics to monitor**:
   - If arguments specify metrics: use those
   - If invoked during SENSE: monitor all key business and operational metrics
   - If invoked post-deploy: monitor metrics related to the deployed change
   - Key metric categories:
     - **Business**: conversion rate, revenue, signups, active users, funnel steps
     - **Operational**: error rate, latency (p50/p95/p99), request volume, queue depth
     - **Tracking**: event counts, property completeness, schema violations
     - **Infrastructure**: CPU, memory, disk, network, pod restarts

2. **Establish baselines**:
   - For each metric, compute baseline from historical data:
     - Rolling average: 7-day window (or 28-day for weekly-cyclic metrics)
     - Standard deviation: same window
     - Account for known patterns: day-of-week effects, time-of-day patterns,
       seasonal trends, known traffic spikes (launches, promotions)
   - If no history exists: use the first 24 hours as provisional baseline
   - **Signal**: baseline mean and stddev per metric

3. **Detect anomalies**:
   Apply these detection rules to current metric values:

   | Anomaly Type | Detection Rule | Severity |
   |-------------|---------------|----------|
   | **Flatline** | Count = 0 for > 1 hour on a normally-active metric (baseline avg > 10/hr) | Critical |
   | **Spike** | Value > baseline mean + 3σ | High |
   | **Drop** | Value < baseline mean - 3σ | High |
   | **Drift up** | 7 consecutive days above baseline mean + 1σ | Medium |
   | **Drift down** | 7 consecutive days below baseline mean - 1σ | Medium |
   | **Missing data** | Expected data point not received within expected interval | High |
   | **Schema violation** | > 5% of events fail schema validation in a 1-hour window | Medium |

   - **Signal**: anomaly detected yes/no, type, severity, z-score, metric value vs baseline

4. **Diagnose detected anomalies**:
   For each anomaly, correlate with potential causes:
   - **Recent deploys**: Check git log and deploy history. Was anything shipped
     within 24 hours of the anomaly? If so, the deploy is the likely cause.
   - **Config changes**: Check for feature flag changes, environment variable
     updates, infrastructure changes.
   - **External events**: Known outages of dependencies, marketing campaigns,
     press coverage, competitor actions.
   - **Infrastructure**: Pod restarts, scaling events, database failovers,
     network issues.
   - Classify the anomaly:
     - **Real change**: something legitimately changed (feature launch, marketing campaign)
     - **Bug**: a code change broke something (regression)
     - **Data issue**: tracking broke, schema changed, pipeline delayed
     - **Unknown**: can't determine cause — escalate

5. **Route and recommend**:
   Based on classification:
   - **Real change** → LOG with context. No action needed unless it's a guardrail regression.
   - **Bug** → ALERT SENSE team. Include: anomaly details, suspected deploy/PR,
     suggested investigation steps.
   - **Data issue** → ALERT MFG (self-referential: fix the instrumentation).
     Include: which events are affected, schema violation details.
   - **Unknown** → ALERT human with full context. Include: anomaly details,
     what was checked, what was ruled out.

6. **Produce report**:

```
## Anomaly Detection Report
**Date**: YYYY-MM-DD
**Scope**: [metrics monitored]

## Anomalies Detected
| Metric | Type | Severity | Current | Baseline | Z-score | Classification |
|--------|------|----------|---------|----------|---------|---------------|

## Diagnosis
### [Metric Name] — [Anomaly Type]
- **Detected**: YYYY-MM-DD HH:MM
- **Current value**: N (baseline: N ± N)
- **Z-score**: N
- **Correlated events**:
  - [Deploy/config/external event with timestamp]
- **Classification**: real change / bug / data issue / unknown
- **Recommended action**: [specific action]

## Summary
- Metrics monitored: N
- Anomalies detected: N
- Classified as bugs: N (action required)
- Classified as data issues: N (instrumentation fix needed)
- Classified as real changes: N (no action)
- Unknown: N (human investigation needed)
```

## Rules

- Flatline on a normally-active metric is ALWAYS an alert — it means tracking or
  the feature is broken
- Z-scores must be computed against the SAME DAY OF WEEK baseline for metrics
  with weekly patterns (e.g., weekday vs weekend traffic)
- Never alert on a known pattern (scheduled maintenance, marketing campaign start)
  — maintain an event calendar
- Correlation is not causation: a deploy happened before an anomaly doesn't prove
  the deploy caused it. Present the correlation, let humans decide.
- Anomaly thresholds are RELATIVE to the metric's own history (z-scores), not
  absolute values — what's normal for one metric is abnormal for another
- When in doubt, alert. False alerts are annoying; missed regressions are costly.
- Include enough context in alerts that the recipient can start investigating
  immediately without asking "what does this mean?"
- Schema violation detection should be near-real-time — don't wait for batch processing
