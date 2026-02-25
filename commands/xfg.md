---
name: xfg
description: Experiment Flow - turn every shipped bet into a statistical experiment with automated conclusion
argument-hint: [scope: hypothesize | design | activate | monitor | conclude | cleanup | full]
---

# XFG — Experiment Flow, Go

Run the experiment process for the specified scope: $ARGUMENTS

If no scope is specified, run Phase 4 (Monitor) to check active experiments.

## Phase 1: Hypothesize

**When**: During BET phase, when a bet is committed with a success metric.
**Purpose**: Turn a product bet into a testable statistical hypothesis.

1. Extract from the bet's spec:
   - Primary success metric: what number should move?
   - Expected direction: up or down?
   - Minimum detectable effect (MDE): what's the smallest change worth detecting?
   - Guardrail metrics: what must NOT regress? (e.g., error rate, latency, support volume)
   - Target population: all users, a segment, a region?

2. Frame the hypothesis:
   - Null hypothesis (H₀): The change has no effect on [primary metric]
   - Alternative hypothesis (H₁): The change increases/decreases [primary metric] by at least [MDE]
   - Significance level (α): default 0.05 (adjustable per bet)
   - Power (1-β): default 0.80 (adjustable per bet)

3. Define guardrail rules:
   - For each guardrail metric, define the failure threshold:
     e.g., "error rate must not increase by more than 0.5%"
   - Guardrails are NON-NEGOTIABLE: if a guardrail regresses beyond threshold,
     the experiment fails regardless of primary metric performance
   - **Signal**: hypothesis defined yes/no, guardrails defined yes/no

## Phase 2: Design

**When**: After hypothesis, before BUILD begins.
**Purpose**: Choose methodology and calculate sample size.

4. Run `/experiment-design` for the bet:
   - Choose experiment type:
     - **A/B test**: standard two-group comparison (default for most bets)
     - **Multivariate**: multiple variants (use when testing >2 options)
     - **Switchback**: alternating treatment periods (use for marketplace/network effects)
   - Calculate required sample size:
     - Based on: current metric baseline, variance, MDE, α, power
     - Apply CUPED variance reduction estimate (if historical data available):
       reduces required sample by 30-50% typically
     - Output: required sample per variant, estimated time to reach sample
   - Choose analysis methodology:
     - **Fixed-horizon**: set sample size, analyze once at end (simplest, most powerful)
     - **Sequential testing**: analyze periodically with spending function (allows safe peeking)
     - Recommend sequential testing for experiments expected to run > 1 week
   - Define traffic allocation:
     - Default: 50/50 for A/B, equal split for multivariate
     - Conservative: 90/10 (for risky changes — allocate only 10% to treatment)
   - **Signal**: sample size, estimated duration, methodology choice

5. **Output experiment spec**:

```
## Experiment Spec
**Bet**: [name]
**Hypothesis**: [H₁ in plain language]
**Type**: A/B / multivariate / switchback
**Methodology**: fixed-horizon / sequential

## Metrics
- Primary: [metric] (MDE: N%, direction: up/down)
- Guardrails: [metric list with thresholds]

## Design
- Variants: [control, treatment1, ...]
- Traffic split: [allocation per variant]
- Required sample per variant: N
- Estimated duration: N days
- CUPED applied: yes/no (estimated variance reduction: N%)
- Significance level (α): 0.05
- Power (1-β): 0.80
```

## Phase 3: Activate

**When**: During SHIP, after the bet is deployed (feature-flagged).
**Purpose**: Start the experiment in the analytics/experimentation platform.

6. Configure the experiment:
   - Set up in experiment platform (Statsig, Eppo, PostHog Experiments, or LaunchDarkly):
     - Create experiment with defined variants
     - Set targeting rules (user segments, traffic %)
     - Configure primary metric and guardrails
     - Set analysis schedule (for sequential testing)
   - If no experiment platform: set up feature flag with percentage rollout
     and manual metric collection

7. Verify instrumentation:
   - Confirm events are firing for primary and guardrail metrics
   - Verify variant assignment is logged (which users got which variant)
   - Check sample ratio: traffic split matches configured allocation (within 1%)
   - Run a quick data check: events flowing for both control and treatment
   - **Signal**: events flowing yes/no, sample ratio within tolerance yes/no

8. **Decision rules**:
   - Events not flowing → **BLOCK experiment start**. Fix instrumentation first.
   - Sample ratio mismatch > 1% → **ALERT**. Possible assignment bug.
   - All checks pass → **START** experiment. Begin collecting data.

## Phase 4: Monitor

**When**: While experiment is running. Check daily or on schedule.
**Purpose**: Watch for early issues and track progress toward significance.

9. Daily checks:
   - **Sample Ratio Mismatch (SRM)**: Compare expected vs actual traffic split
     using chi-squared test. If p-value < 0.01, SRM is detected.
   - **Guardrail metrics**: Are any guardrails regressing beyond threshold?
   - **Data quality**: Are events still flowing? Any tracking disruptions?
   - **Progress**: What % of required sample has been collected?
     When is the estimated completion date?
   - **Signal**: SRM detected yes/no, guardrails healthy yes/no, sample progress %

10. **Decision rules**:
    - SRM detected (chi-squared p < 0.01) → **HALT experiment**. The results
      cannot be trusted. Investigate assignment mechanism before proceeding.
    - Guardrail regression beyond threshold → **FAIL experiment immediately**.
      The change is hurting a critical metric regardless of primary performance.
    - Data quality issue → **PAUSE** until tracking is verified.
    - Sample < 10% of required → **CONTINUE** (too early for any signal)
    - For sequential testing: apply spending function before checking significance.
      **NEVER peek at p-values without sequential correction.**

## Phase 5: Conclude

**When**: When required sample is reached (fixed-horizon) or significance
detected (sequential).
**Purpose**: Make a statistically sound conclusion.

11. Run `/experiment-analyze` for the completed experiment:
    - Verify SRM one final time
    - Run the statistical test:
      - For fixed-horizon: t-test or z-test on the primary metric
      - For sequential: apply final analysis with spending function correction
    - Calculate: effect size, confidence interval, p-value
    - Check practical significance: is the effect size large enough to matter?
      (Statistically significant but tiny effect = not worth the complexity)
    - Check guardrails one final time

12. **Conclusion logic**:

    | Primary Metric | Guardrails | Conclusion | Action |
    |---------------|-----------|------------|--------|
    | Significant positive | All healthy | **WINNER** | Ship to 100%, remove flag |
    | Significant positive | Any regressed | **TRADEOFF** | Human decision — is the win worth the cost? |
    | Not significant | All healthy | **INCONCLUSIVE** | Need more time, bigger MDE, or different approach |
    | Significant negative | — | **LOSER** | Kill treatment, keep control |
    | — | SRM detected | **INVALID** | Results cannot be trusted |

13. **Produce impact report**:

```
## Experiment Results
**Bet**: [name]
**Duration**: N days
**Sample size**: N per variant

## Primary Metric: [name]
- Control: N (mean ± CI)
- Treatment: N (mean ± CI)
- Effect size: N% (CI: [low, high])
- p-value: N
- Practically significant: yes/no

## Guardrail Metrics
| Metric | Control | Treatment | Delta | Threshold | Status |
|--------|---------|-----------|-------|-----------|--------|

## Data Quality
- SRM check: PASS (p=N) / FAIL
- Sample ratio: N% / N% (expected: N% / N%)
- Data completeness: N%

## Conclusion
**WINNER / LOSER / INCONCLUSIVE / TRADEOFF / INVALID**
[Plain language explanation of what happened and what to do next]

## Recommendation
- SHIP: [deploy to 100%, remove feature flag]
- ITERATE: [what to change for the next version]
- KILL: [revert to control, clean up]
```

## Phase 6: Clean Up

**When**: After conclusion is accepted by human.
**Purpose**: Remove experiment infrastructure and capture learnings.

14. Based on conclusion:
    - **WINNER**: Remove feature flag (ship treatment to 100%). Remove variant logic from code.
    - **LOSER/INVALID**: Remove treatment code. Ensure control is the default.
    - **INCONCLUSIVE**: Human decides: extend experiment, redesign, or abandon.
    - **TRADEOFF**: Human decides: ship with tradeoff or iterate.

15. Update experiment catalog:
    - Log the experiment, result, and key learnings
    - Feed the conclusion to LEARN phase for impact tracking
    - If the result contradicts priors (expected win but lost), flag for deeper analysis

## Rules

- NEVER peek at p-values without sequential testing correction — this inflates false positive rates
- ALWAYS check SRM before trusting any result — SRM invalidates everything
- Guardrail metrics are NON-NEGOTIABLE — if a guardrail regresses beyond threshold,
  the experiment fails regardless of the primary metric
- Practical significance matters as much as statistical significance — a real but tiny
  effect may not be worth the code complexity
- CUPED variance reduction is free power — use it whenever historical data is available
- Minimum experiment duration: 1 full week (to capture day-of-week effects), even if
  sample size is reached earlier
- Feature flags must be cleaned up within 1 week of conclusion — stale flags are debt
- Experiment results feed LEARN — every experiment is a data point about our mental model
- If an experiment is inconclusive after 2x the estimated duration, recommend kill or redesign —
  it's unlikely more data will help
