---
name: pfg
description: Platform Flow - golden path maintenance, CI/CD optimization, DX measurement, infrastructure drift detection
argument-hint: [scope: inventory | golden-path | optimize | drift | measure-dx | agent-platform | full]
---

# PFG — Platform Flow, Go

Run the platform process for the specified scope: $ARGUMENTS

If no scope is specified, run Phase 3 (Optimize) to analyze CI/CD pipeline performance.

## Phase 1: Inventory

**When**: At project onboarding or quarterly platform review.
**Purpose**: Map current platform capabilities and identify gaps.

1. **Inventory platform components**:
   - CI/CD pipelines: what runs, how long, how often, failure rate
   - Golden paths: what paved roads exist for common tasks?
   - Infrastructure: declared state (IaC), actual state, drift status
   - Agent tooling: what agents are available, what tools do they have?
   - Developer workflows: how do devs create, test, deploy, debug?
   - **Signal**: component count, coverage %, staleness indicators

2. **Identify gaps vs process needs**:
   - Cross-reference against what QFG, SFG, OFG, MFG, XFG need:
     - Does QFG have access to mutation testing tools? Property test frameworks?
     - Does SFG have secret scanning in pre-commit hooks? SAST in CI?
     - Does OFG have progressive rollout infrastructure? SLO monitoring?
     - Does MFG have event schema validation in CI? Dashboard templates?
     - Does XFG have experiment platform access? Feature flag infrastructure?
   - Identify: what's available, what's missing, what's broken

3. **Produce inventory report**:

```
## Platform Inventory
**Date**: YYYY-MM-DD

## CI/CD Pipelines
| Pipeline | Trigger | Avg Duration | Success Rate | Last Updated |
|----------|---------|-------------|-------------|-------------|

## Golden Paths
| Task | Path Exists | Adoption | Last Updated | Friction Score |
|------|------------|----------|-------------|---------------|

## Infrastructure
| Component | IaC Managed | Drift Status | Last Verified |
|-----------|------------|-------------|--------------|

## Agent Tooling
| Process | Required Tools | Available | Missing |
|---------|---------------|-----------|---------|

## Gaps
- [ ] [Specific gap with impact and recommended action]
```

## Phase 2: Golden Paths

**When**: When a common task lacks a paved road, or an existing path has high friction.
**Purpose**: Create or improve the path of least resistance for common operations.

4. Run `/golden-path` for the identified task:
   - Focus on **day-50 operations**, not day-1 scaffolding:
     - Deploy a change safely
     - Debug a production issue
     - Scale a service
     - Rotate a secret
     - Add a dependency
     - Create a new API endpoint
     - Set up monitoring for a new service
   - For each path: minimize steps, maximize automation, document with examples
   - **Signal**: steps reduced (before vs after), friction score improvement

5. **Decision rules**:
   - Task takes > 10 manual steps → golden path needed
   - Task is performed > 5 times/month across teams → golden path needed
   - Existing golden path has < 30% adoption → investigate friction, not enforce adoption
   - Golden paths are OPTIONAL — teams can go off-path with justification

## Phase 3: Optimize

**When**: On schedule (weekly) or when build times/costs drift above threshold.
**Purpose**: Keep CI/CD fast, cheap, and reliable.

6. Run `/ci-optimize` to analyze pipeline performance:
   - Profile each pipeline stage: time, cost, failure rate, cache hit rate
   - Identify bottlenecks:
     - Slow test suites (identify the slowest 10% of tests)
     - Uncached dependencies (downloading the same things every run)
     - Serial steps that could run in parallel
     - Unnecessary steps (running lint twice, redundant builds)
   - Identify flaky tests:
     - Tests that pass/fail non-deterministically
     - Calculate flake rate per test over last N runs
   - **Signal**: stage duration (seconds), cache hit rate %, flake rate %

7. **Decision rules based on deterministic signals**:
   - Build time > 150% of 30-day baseline → **INVESTIGATE** and recommend optimizations
   - Cache hit rate < 80% → **FIX** caching configuration
   - Flake rate > 5% for a test → **QUARANTINE** (move to optional, file fix issue)
   - Flake rate > 20% → **DISABLE** test, create urgent fix issue
   - Pipeline cost > 150% of monthly baseline → **ALERT** with breakdown
   - Failed step with > 10% failure rate → **INVESTIGATE** (infra issue, not code)

## Phase 4: Drift

**When**: On schedule (daily) or triggered by infrastructure alerts.
**Purpose**: Detect and correct infrastructure drift.

8. Compare declared state vs actual state:
   - Run IaC plan commands:
     - `terraform plan -json` / `tofu plan -json`
     - `pulumi preview --json`
   - Classify detected drift:

   | Drift Type | Example | Action |
   |-----------|---------|--------|
   | **Safe drift** | Tag changes, description updates, scaling adjustments within bounds | Auto-correct |
   | **Suspicious drift** | Security group changes, IAM policy changes, network config | Alert human |
   | **Dangerous drift** | Deleted resources, exposed ports, removed encryption | Alert immediately |
   | **Expected drift** | Auto-scaling changes, dynamic config | Ignore (add to exceptions) |

   - **Signal**: resources drifted count, drift classification per resource

9. **Decision rules**:
   - Safe drift → **AUTO-CORRECT** (apply IaC to restore declared state)
   - Suspicious drift → **ALERT** human with diff and risk assessment
   - Dangerous drift → **ALERT immediately** + investigate who/what changed it
   - Expected drift → **LOG** and ensure exception list is current

## Phase 5: Measure DX

**When**: On schedule (monthly) or triggered by developer friction signals.
**Purpose**: Quantify developer experience and identify friction.

10. Run `/dx-measure` to collect developer experience signals:
    - **DORA metrics** (computed from git + CI/CD data):
      - Deploy frequency: how often do we ship to production?
      - Lead time: from commit to production (how fast?)
      - Change failure rate: % of deploys causing incidents (how safe?)
      - Mean time to restore: how fast do we recover from failures?
    - **Build experience**:
      - Average build time (CI and local)
      - Average test suite duration
      - Time from PR open to merge
      - Number of CI retries per PR
    - **Onboarding**:
      - Time to first commit for new services
      - Steps to set up local dev environment
      - Documentation freshness (when were docs last updated?)
    - **Signal**: all numeric, all trend-able

11. **Decision rules**:
    - Deploy frequency declining → **INVESTIGATE** (growing batch size? more gatekeeping?)
    - Lead time > 2x baseline → **INVESTIGATE** (slow reviews? slow CI? slow deploys?)
    - Change failure rate > 15% → **ALERT** (quality process gap)
    - MTTR > 1 hour → **INVESTIGATE** (observability gap? complex rollback?)
    - Build time > 10 minutes → **OPTIMIZE** (developer patience threshold)

## Phase 6: Agent Platform

**When**: On schedule (monthly) or when agent capability gaps are identified.
**Purpose**: Health of the agent infrastructure itself.

12. Assess agent platform health:
    - Which agents are available? (List from .claude/agents/)
    - Which skills are available? (List from .claude/skills/)
    - What's the coverage: do all Steering Model phases have supporting agents?
    - What are common agent failure modes? (from recent invocations)
    - What tasks still require human intervention that agents could handle?

13. Produce agent platform report:

```
## Agent Platform Health
**Date**: YYYY-MM-DD

## Agent Coverage
| Steering Model Phase | Process | Agent | Skills | Status |
|---------------------|---------|-------|--------|--------|

## Capability Gaps
| Task | Current: Human/Agent | Recommended | Effort |
|------|---------------------|-------------|--------|

## Agent Health
| Agent | Invocations (30d) | Success Rate | Common Failures |
|-------|-------------------|-------------|-----------------|

## Recommendations
- [ ] [Specific capability addition or improvement]
```

## Rules

- Golden paths are OPTIONAL — never lock down. Teams can go off-path with justification.
  The path should be so good that nobody wants to leave it, not so enforced that nobody can.
- Platform changes that affect ALL teams require human approval — unilateral platform changes
  cause more damage than they solve
- Thinnest viable platform — resist adding capabilities that only 1-2 teams need.
  Every platform feature has maintenance cost; justify it with adoption data.
- CI/CD optimization is a continuous process, not a one-time project — build times
  creep up. Check weekly.
- Flaky tests destroy developer trust in CI — quarantine aggressively, fix urgently
- Infrastructure drift detection runs daily — drift accumulates and becomes harder to fix
- DX measurement uses QUANTITATIVE signals, not surveys alone — surveys are valuable
  but lagging. CI timing and git metrics are leading indicators.
- Auto-correct only SAFE drift — anything touching security, networking, or permissions
  requires human review
- DORA metrics are trends, not targets — improving the trend matters more than hitting
  an absolute number
