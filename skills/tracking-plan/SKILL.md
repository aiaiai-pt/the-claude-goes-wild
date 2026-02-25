---
name: tracking-plan
description: Audit or extend the tracking plan for event tracking compliance
---

# Tracking Plan

Audit or extend the tracking plan for the specified scope. $ARGUMENTS

## Process

1. **Determine mode**:
   - If arguments say "audit": run audit mode (check existing tracking)
   - If arguments specify a bet or feature: run instrument mode (add tracking)
   - If no arguments: default to audit mode on the full codebase

2. **Audit mode — inventory existing tracking**:
   - Scan codebase for analytics SDK calls. Search patterns by platform:
     - PostHog: `posthog.capture`, `usePostHog`, `$posthog`
     - Amplitude: `amplitude.track`, `amplitude.logEvent`
     - Segment: `analytics.track`, `analytics.identify`, `analytics.page`
     - Mixpanel: `mixpanel.track`, `mixpanel.people`
     - GA4: `gtag('event'`, `logEvent`
     - Custom: check for project-specific analytics wrappers
   - For each event found, extract:
     - Event name (string literal or variable reference)
     - Properties passed (object keys)
     - File:line location
     - Trigger condition (what user action or system event causes it)
   - Cross-reference against tracking plan document (if exists):
     - Look in: `dev_docs/tracking-plan/`, `docs/events.md`, `analytics/schema/`
     - Check for JSON Schema or TypeScript type definitions of events
   - Classify each event:
     - **Documented + implemented**: in both plan and code
     - **Undocumented**: in code but not in plan (possible rogue tracking)
     - **Unimplemented**: in plan but not in code (gap)
   - **Signal**: counts per category, property completeness %

3. **Instrument mode — add tracking for a bet's metrics**:
   - Read the bet's spec to identify success metrics and guardrail metrics
   - For each metric, determine the event(s) needed:
     - What user action or system event represents this metric?
     - What properties are needed for segmentation?
     - What's the expected volume (events per day)?
   - Design each event:
     - Name: `object_action` convention (e.g., `checkout_completed`, `search_performed`)
     - Properties: typed, documented, with required/optional classification
     - Trigger: exact code location where the event should fire
     - Schema: JSON Schema definition for validation
   - Implement:
     - Add the tracking call at the correct location
     - Add schema definition to the schema directory (if project uses schema validation)
     - Update the tracking plan document
   - Verify:
     - Write a test that asserts the event fires with correct properties
     - If possible, trigger the event and check the analytics platform received it
   - **Signal**: event implemented yes/no, schema valid yes/no, test passes yes/no

4. **Validate schema compliance**:
   - For each event, validate against its JSON Schema (if defined):
     - Required properties present
     - Property types match (string, number, boolean, etc.)
     - No unexpected properties (if schema is strict)
     - No PII in unprotected fields (check for email, name, phone, IP patterns)
   - Use `ajv-cli` (Node) or `jsonschema` (Python) for validation
   - **Signal**: schema validation pass/fail per event

5. **Produce report**:

```
## Tracking Plan Report
**Date**: YYYY-MM-DD
**Mode**: audit / instrument
**Scope**: [project or bet name]

## Event Inventory
| Event Name | Status | File:Line | Properties | Schema | Notes |
|-----------|--------|-----------|-----------|--------|-------|

## Gaps
| Event | Issue | Action Needed |
|-------|-------|--------------|

## New Events (instrument mode only)
| Event Name | Properties | Trigger | Schema | Test |
|-----------|-----------|---------|--------|------|

## Summary
- Total events: N
- Documented + implemented: N
- Undocumented (rogue): N
- Unimplemented (gap): N
- Schema compliance: N%
```

## Rules

- Event names MUST follow `object_action` convention — consistent naming is non-negotiable
- Every event MUST have a defined schema, even if it's informal (property list with types)
- PII in event properties requires explicit justification and consent mechanism
- Undocumented events are not automatically wrong — they may be useful but need documentation
- Unimplemented events from the tracking plan are gaps that should be flagged
- Schema validation must be deterministic — same event, same verdict
- When instrumenting, verify the event actually fires — don't trust that the code works
- Never instrument tracking for metrics that don't have a clear owner and definition
