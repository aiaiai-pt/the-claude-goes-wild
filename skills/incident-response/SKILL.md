---
name: incident-response
description: Handle a detected incident with automated diagnosis and remediation
---

# Incident Response

Handle the detected incident or investigate the specified anomaly. $ARGUMENTS

## Process

1. **Gather context** (first 5 minutes):
   - **What's happening**: Which metrics are anomalous? Error rate, latency, availability.
     Quantify the impact: how many users affected, which endpoints, which regions.
   - **When did it start**: Find the inflection point in the time series.
     Narrow down to a 5-minute window if possible.
   - **What changed**: Query recent events within the anomaly window:
     - Deployments: `git log --since` + deploy timestamps
     - Config changes: feature flag changes, env var updates
     - Infrastructure: scaling events, pod restarts, node changes
     - Dependencies: status pages of external services
   - **Signal**: anomaly start time, impact scope (users/requests affected), correlated changes

2. **Build causal hypothesis**:
   - Map the timeline: change events vs anomaly onset
   - If a deploy correlates (within 30 min before anomaly): high probability cause
   - If a config change correlates: medium probability cause
   - If a dependency status page shows issues: external cause (limited remediation)
   - If nothing correlates: look deeper — check for resource exhaustion (memory leak,
     connection pool, disk full), traffic pattern changes, clock skew
   - Rank hypotheses by likelihood and testability
   - **Signal**: primary hypothesis with confidence level (high/medium/low)

3. **Diagnose**:
   - For the primary hypothesis, gather supporting evidence:
     - If deploy-related: diff the deploy, look for risky changes
       (new dependencies, changed queries, auth changes, config parsing)
     - If resource-related: check resource metrics (CPU, memory, disk, connections)
       over the anomaly window
     - If dependency-related: check dependency response times, error rates,
       and status pages
     - If traffic-related: compare traffic volume and patterns against baseline
   - Check traces for failing requests: what's the common failure point?
   - Check error logs for new exception types or increased frequency
   - **Signal**: root cause identified yes/no, confidence level

4. **Remediate**:
   Apply the appropriate automated response based on diagnosis:

   | Diagnosis | Auto-Remediation | Human Required? |
   |-----------|-----------------|----------------|
   | Recent deploy caused regression | Rollback to previous version | No — rollback is always safe |
   | Pod OOMKilled | Increase memory limit within pre-approved bounds | No |
   | Dependency timeout | Open circuit breaker, serve degraded | No |
   | Connection pool exhausted | Restart affected pods, increase pool size | No |
   | Disk full | Clear temp files, expand volume if auto-scaling enabled | No |
   | Traffic spike (organic) | Scale up if autoscaler is slow | No |
   | Traffic spike (attack) | Enable rate limiting, alert security | Yes — verify it's an attack |
   | Unknown root cause | Mitigate symptoms (scale up, restart), alert human | Yes |
   | Data corruption suspected | **DO NOTHING** — alert human immediately | Yes — always |

   - After applying remediation, verify: did the metrics return to normal?
   - **Signal**: remediation applied, metrics recovered yes/no, time to recovery

5. **Communicate**:
   - If impact is user-facing: prepare status update (internal or external as appropriate)
   - Notify relevant team: the service owner, on-call, and whoever deployed recently
   - Include: what happened, what was done, current status, next steps

6. **Post-incident**:
   - Auto-generate incident report:

```
## Incident Report
**Date**: YYYY-MM-DD HH:MM — HH:MM (duration: Nmin)
**Severity**: P1/P2/P3/P4
**Impact**: [N users/requests affected, N% error rate, Nmin duration]

## Timeline
| Time | Event |
|------|-------|
| HH:MM | Anomaly detected: [description] |
| HH:MM | Investigation started |
| HH:MM | Root cause identified: [description] |
| HH:MM | Remediation applied: [action] |
| HH:MM | Metrics recovered to normal |

## Root Cause
[Detailed explanation of what went wrong and why]

## Remediation
- Immediate: [what was done to stop the bleeding]
- Permanent: [what needs to change to prevent recurrence]

## Follow-up Actions
- [ ] [Specific action with owner]

## Lessons Learned
- [What we learned, what we should do differently]
```

   - Create follow-up issues for permanent fixes
   - Update the known pattern library if a new auto-remediation pattern was discovered
   - Feed the incident into SENSE for pattern detection across incidents

## Rules

- First priority is ALWAYS to stop the bleeding (mitigate), not to understand perfectly
- Rollback is always the safest first response to a deploy-correlated incident
- Data corruption suspicions require IMMEDIATE human involvement — never auto-remediate
- Auto-remediation is only for KNOWN, SAFE patterns — novel incidents escalate to human
- Never apply a remediation you can't reverse — all auto-remediations must be reversible
- Communication is part of the response — not an afterthought
- Post-incident follow-up is mandatory — incidents without follow-ups will recur
- Time to detection is the most important metric — seconds matter
- Always check "what changed?" before exploring exotic hypotheses — most incidents are caused by recent changes
