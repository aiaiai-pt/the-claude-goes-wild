---
name: metric-dashboard
description: Create or update a metrics dashboard for a shipped bet
---

# Metric Dashboard

Create or update a metrics dashboard for the specified bet or feature. $ARGUMENTS

## Process

1. **Identify key metrics**:
   - Read the bet's spec to extract:
     - Primary success metric (the hypothesis: "we expect X to increase by Y%")
     - Guardrail metrics (must not regress: error rate, latency, support volume)
     - Secondary metrics (interesting to watch but not decisive)
   - For each metric, determine:
     - Data source (analytics platform, database, APM, logs)
     - Query or event that produces the metric
     - Expected direction (up is good? down is good?)
     - Comparison baseline (previous period, control group, target)

2. **Design dashboard layout**:
   - Follow information hierarchy:
     ```
     ┌─────────────────────────────────────────┐
     │ KPI ROW: Primary metric + guardrails    │
     │ Big numbers with trend arrows            │
     │ Red/green based on direction vs expected  │
     ├─────────────────────────────────────────┤
     │ TREND CHARTS: Time series per metric     │
     │ Current period vs previous period         │
     │ Deploy date annotated with vertical line  │
     ├─────────────────────────────────────────┤
     │ FUNNEL: Conversion steps (if applicable) │
     │ Step-by-step with drop-off rates          │
     ├─────────────────────────────────────────┤
     │ SEGMENTS: Breakdowns by key dimensions   │
     │ User type, platform, geography, cohort    │
     └─────────────────────────────────────────┘
     ```

3. **Build the dashboard**:
   - In the analytics platform (PostHog, Amplitude, Grafana, etc.):
     - Create dashboard with descriptive title: "[Bet Name] Impact Dashboard"
     - Add description: what this bet does, what we're measuring, when it shipped
     - Add KPI cards for primary + guardrail metrics
     - Add time series charts with appropriate time ranges
     - Add deploy date annotation
     - Add funnel visualization if applicable
     - Add segment breakdowns for the most relevant dimensions
   - If no analytics platform access, generate dashboard config or spec:
     - Dashboard specification in `dev_docs/dashboards/[bet-name].md`
     - Include exact queries, chart types, layout, and thresholds

4. **Add context and annotations**:
   - Dashboard title must be self-explanatory (not just "Metrics" or "Dashboard 1")
   - Each chart must have a title and subtitle explaining what it shows
   - Add annotations for: deploy date, experiment start/end, incidents
   - Set appropriate time range defaults (7 days for fresh bets, 30 days for established)
   - Add threshold lines where applicable (target values, SLO boundaries)

5. **Verify dashboard health**:
   - All queries return data (no empty charts)
   - Data freshness is within acceptable range
   - Numbers make sense (sanity check against known values)
   - Dashboard loads within acceptable time
   - **Signal**: charts rendering yes/no, data fresh yes/no, load time in seconds

6. **Produce report**:

```
## Dashboard Report
**Date**: YYYY-MM-DD
**Bet**: [name]
**Dashboard URL**: [url or file path]

## Metrics Included
| Metric | Type | Source | Chart Type | Status |
|--------|------|--------|-----------|--------|
| [name] | primary/guardrail/secondary | [source] | [type] | rendering/empty/stale |

## Annotations
- Deploy date: YYYY-MM-DD
- [Other relevant dates]

## Health
- All charts rendering: yes/no
- Data freshness: [within/outside] acceptable range
- Load time: Ns
```

## Rules

- Every shipped bet MUST have a dashboard within 1 day — no exceptions
- Primary success metric MUST be the most prominent element (top-left, biggest)
- Guardrail metrics must be visible alongside the success metric — can't celebrate
  a win if a guardrail regressed
- Deploy date annotation is mandatory — you can't assess impact without knowing when
  the change went live
- Dashboard titles must be self-explanatory — someone unfamiliar with the bet should
  understand what they're looking at
- Use consistent time ranges across charts on the same dashboard
- Never use pie charts for time series data
- Compare against the right baseline: previous period, not all-time average
- Segment breakdowns should reveal WHO is affected, not just WHAT changed
- If a dashboard has no viewer for 30 days, it's a candidate for archival
