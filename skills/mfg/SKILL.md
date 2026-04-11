---
name: mfg
description: Measure Flow - event tracking infrastructure, dashboard health, anomaly detection, data pipeline reliability
argument-hint: [scope: audit | instrument | dashboard | anomaly | pipeline | report | full]
---

# MFG — Measure Flow, Go

Run the measurement process for the specified scope: $ARGUMENTS

If no scope is specified, run Phase 1 (Audit) on the current project as the default.

## Phase 1: Audit

**When**: At the start of any bet, or standalone to assess tracking health.
**Purpose**: Map the current state of event tracking and identify gaps.

1. **Inventory existing tracking**:
   - Scan codebase for analytics calls (PostHog, Amplitude, Segment, Mixpanel, GA4 patterns)
   - Extract: event names, properties, trigger locations (file:line)
   - Cross-reference against any existing tracking plan (dev_docs/tracking-plan/ or equivalent)
   - Check for schema definitions (JSON Schema, TypeScript types, Avro)
   - **Signal**: event count, property completeness %, schema coverage %

2. **Identify gaps**:
   - Events defined in tracking plan but not implemented (missing instrumentation)
   - Events implemented but not in tracking plan (undocumented)
   - Events with incomplete properties (required properties missing)
   - Events with no downstream consumer (firing but unused)
   - Success metrics for active bets without corresponding events

3. **Validate event schemas**:
   - Run `/tracking-plan` audit mode against current events
   - For each event, validate: name follows convention, required properties present,
     property types match schema, no PII in unprotected properties
   - **Signal**: schema validation pass/fail per event (ajv-cli or jsonschema)

4. **Produce audit report**:

```
## Tracking Audit Report
**Date**: YYYY-MM-DD
**Scope**: [project/service]

## Event Inventory
- Events in tracking plan: N
- Events in codebase: N
- Documented + implemented: N
- Implemented but undocumented: N
- Documented but not implemented: N

## Schema Compliance
| Event | Properties | Required Present | Schema Valid | Notes |
|-------|-----------|-----------------|-------------|-------|

## Gaps
- [ ] [Specific gap with recommended action]

## Health Score
- Tracking plan coverage: N%
- Schema compliance: N%
- Property completeness: N%
```

## Phase 2: Instrument

**When**: During BUILD, when a bet's success metrics need tracking.
**Purpose**: Implement event tracking for the bet's key metrics.

5. Run `/tracking-plan` in instrument mode for the bet's success metrics
6. For each required event:
   - Design the event: name, properties, trigger condition, expected volume
   - Implement the tracking call at the correct location
   - Add schema validation (JSON Schema or TypeScript type)
   - Verify the event fires correctly (test it)
   - **Signal**: event fires yes/no, properties match schema yes/no

7. **Decision rules**:
   - Event fires with correct properties → **PASS**
   - Event fires but properties incomplete → **FIX** before SHIP
   - Event doesn't fire → **BLOCK SHIP** — success metrics can't be measured without tracking

## Phase 3: Dashboard

**When**: Within 1 day of SHIP. Required for every shipped bet.
**Purpose**: Make the bet's impact visible and measurable.

8. Run `/metric-dashboard` for the shipped bet
9. Dashboard must include:
   - Primary success metric (the bet's hypothesis)
   - Guardrail metrics (must not regress)
   - Funnel visualization (if applicable)
   - Segment breakdowns (user type, platform, geography — whatever is relevant)
   - Deploy date annotations
   - Time comparisons (this period vs previous period)

10. **Decision rules**:
    - Dashboard created with all required metrics → **PASS**
    - Dashboard missing success metric → **BLOCK** — the bet can't be evaluated
    - Dashboard has stale data (>1hr delay for real-time, >1day for batch) → **WARN**

## Phase 4: Anomaly

**When**: Always-on. Continuous monitoring of business metrics.
**Purpose**: Detect metric anomalies before anyone notices.

11. Run `/anomaly-detect` on key metrics:
    - **Flatline detection**: metric count drops to 0 (tracking broke)
    - **Spike detection**: metric jumps > 3 standard deviations from rolling average
    - **Drift detection**: gradual trend change over 7+ days
    - **Missing data**: expected events not received within expected window
    - **Schema violation**: events arriving with wrong property types or missing required fields

12. **Decision rules based on deterministic signals**:
    - Flatline detected (count = 0 for >1 hour on a normally-active metric) → **ALERT SENSE**
    - Spike > 3 sigma from 7-day rolling average → **ALERT** with correlation analysis
      (recent deploys? config changes? external events?)
    - Drift > 2 sigma sustained for 7 days → **ALERT** with trend chart
    - Schema violation rate > 5% of events → **ALERT** + flag for instrumentation fix
    - All normal → **LOG** quietly

## Phase 5: Pipeline

**When**: Always-on. Monitors the measurement infrastructure itself.
**Purpose**: Ensure data pipelines are reliable and fresh.

13. Monitor data pipeline health:
    - Event delivery latency (time from trigger to analytics platform)
    - Event drop rate (events sent vs events received)
    - Schema registry health (if using Avro/Protobuf schemas)
    - Dashboard query freshness (when did each dashboard last refresh?)
    - Storage growth rates (are we generating unsustainable data volumes?)

14. **Decision rules**:
    - Event delivery latency > 2x baseline → **WARN**
    - Event drop rate > 1% → **ALERT**
    - Dashboard not refreshed in 24h (real-time) or 48h (batch) → **ALERT**
    - Dashboard not viewed in 30 days → **FLAG for cleanup** (stale dashboard)
    - Schema change detected without backward compatibility → **BLOCK deploy**

## Phase 6: Report

**When**: On demand or scheduled (weekly).
**Purpose**: Measurement health summary.

15. Generate measurement health report:

```
## Measurement Health Report
**Date**: YYYY-MM-DD
**Scope**: [project/service]

## Tracking Plan Coverage
- Events defined: N
- Events implemented: N
- Schema compliance: N%
- Property completeness: N%

## Dashboard Health
| Dashboard | Last Viewed | Last Refreshed | Status |
|-----------|------------|---------------|--------|

## Anomalies (This Period)
| Metric | Type | Detected | Status | Root Cause |
|--------|------|----------|--------|------------|

## Pipeline Health
- Event delivery p99 latency: Nms
- Event drop rate: N%
- Schema violations: N events

## Stale Dashboards (>30 days no viewer)
- [Dashboard name]: last viewed YYYY-MM-DD — recommend archive/delete

## Action Items
1. [Items requiring human decision]

## Verdict
- Tracking: HEALTHY / GAPS (N events missing)
- Dashboards: HEALTHY / STALE (N dashboards)
- Pipeline: HEALTHY / DEGRADED
- **Overall**: HEALTHY / NEEDS ATTENTION
```

## Rules

- Every bet MUST have its success metric instrumented BEFORE SHIP — no exceptions
- Dashboards MUST be created within 1 day of ship — impact must be visible immediately
- Stale dashboards (no viewer in 30 days) are flagged for cleanup, not silently kept
- Schema changes to existing events MUST be backward compatible — old consumers must still work
- Event names follow a consistent convention: `object_action` (e.g., `user_signed_up`, `order_placed`)
- Never track PII in event properties without explicit data classification and consent
- Anomaly detection thresholds are relative to the metric's own history, not absolute values
- Flatline on a normally-active metric is ALWAYS an alert — it means tracking is broken
- All signals must be numeric and deterministic: counts, percentages, latencies, z-scores
