---
name: experiment-design
description: Design a statistical experiment from a bet's success metrics and hypothesis
---

# Experiment Design

Design a statistical experiment for the specified bet or feature. $ARGUMENTS

## Process

1. **Extract experiment parameters from the bet**:
   - Read the bet's spec to identify:
     - Primary success metric (what should move?)
     - Current baseline value (what's the metric at today?)
     - Minimum detectable effect (MDE): smallest meaningful change
       - If not specified in the spec, recommend: 5% relative change for large metrics,
         10% for smaller metrics, absolute values for rates (e.g., +0.5% conversion)
     - Guardrail metrics with regression thresholds
     - Target population and any exclusions

2. **Choose experiment type**:

   | Situation | Type | Reason |
   |-----------|------|--------|
   | Standard feature change | A/B test (2 groups) | Simplest, most powerful |
   | Testing multiple variants (colors, copy, layouts) | Multivariate | Test N options simultaneously |
   | Marketplace/network effects | Switchback | Avoids spillover between groups |
   | Pricing/revenue sensitive | A/B with conservative split (90/10) | Limits downside risk |
   | Personalization/ML model | Multi-armed bandit | Optimizes while learning (explore/exploit) |

3. **Calculate sample size**:
   - Inputs:
     - Baseline metric value (current mean or rate)
     - Variance of the metric (from historical data)
     - Minimum detectable effect (MDE)
     - Significance level (α): default 0.05
     - Statistical power (1-β): default 0.80
   - Formula (for a two-sample z-test on proportions):
     ```
     n_per_group = (Z_α/2 + Z_β)² × 2 × σ² / δ²
     ```
     Where σ² = variance, δ = MDE
   - Apply CUPED variance reduction if historical data available:
     - CUPED uses pre-experiment metric values as a covariate
     - Typical variance reduction: 30-50%
     - Adjusted sample: `n_cuped = n × (1 - r²)` where r² is the correlation
       between pre and post metric
   - Estimate duration: `days = n_per_group × num_variants / daily_traffic`
   - **Signal**: required sample per variant, estimated duration in days

4. **Choose analysis methodology**:

   | Duration Estimate | Methodology | Reason |
   |-------------------|------------|--------|
   | < 7 days | Fixed-horizon | Simple, maximum power, minimal complexity |
   | 7-30 days | Sequential (group sequential or mSPRT) | Safe peeking, can stop early |
   | > 30 days | Sequential with futility stopping | Stop early if clearly losing or hopeless |

   - For sequential testing, define the analysis schedule:
     - Check frequency: daily after minimum 7 days
     - Spending function: O'Brien-Fleming (conservative early, liberal late)
     - Early stopping for efficacy: when p < adjusted threshold
     - Early stopping for futility: when conditional power < 10%

5. **Define traffic allocation**:
   - Standard (most cases): 50/50 for A/B
   - Conservative (risky changes): 90/10 (only 10% see treatment)
   - Multivariate: equal split across all variants
   - Ramp-up: start at 5/95, expand to 50/50 after initial safety check
     (useful for changes with uncertain risk)

6. **Produce experiment spec**:

```
## Experiment Design
**Bet**: [name]
**Date**: YYYY-MM-DD

## Hypothesis
- H₀: [metric] is unchanged by the treatment
- H₁: [metric] changes by at least [MDE]
- Direction: [one-tailed: increase/decrease, or two-tailed]

## Design Parameters
- Type: A/B / multivariate / switchback
- Variants: [list with descriptions]
- Traffic split: [allocation]
- Target population: [all users / segment]
- Exclusions: [if any]

## Sample Size
- Baseline metric: [current value ± variance]
- MDE: [absolute or relative]
- α: 0.05, Power: 0.80
- Required sample per variant: N
- CUPED adjustment: [variance reduction estimate, adjusted sample]
- Estimated duration: N days
- Daily eligible traffic: N users/day

## Methodology
- Analysis type: fixed-horizon / sequential
- [If sequential] Check schedule: [frequency after day N]
- [If sequential] Spending function: [type]
- [If sequential] Futility stopping: [threshold]

## Metrics
### Primary
- [Metric name]: [definition, direction, MDE]

### Guardrails (must not regress)
| Metric | Current | Threshold | Direction |
|--------|---------|-----------|-----------|

### Secondary (observe but don't decide on)
- [Metric list]

## Risks
- [Known risks to experiment validity: spillover, novelty effects, etc.]
- [Mitigation for each]
```

## Rules

- CUPED is essentially free variance reduction — always apply it if >7 days of pre-experiment
  data exists for the metric
- MDE must be practically meaningful, not just "any detectable change" — detecting a 0.01%
  change requires enormous samples and probably isn't worth the business complexity
- Minimum experiment duration is 1 full week regardless of sample size — day-of-week
  effects are real and distort results
- One-tailed tests are acceptable when you have a strong directional prior AND the opposite
  direction would be equally actionable (if it can only go up, one-tailed is fine)
- Conservative traffic splits (90/10) are appropriate for pricing, payment, or high-risk changes
- Guardrail metrics are defined at design time, not after seeing results — no post-hoc guardrails
- If estimated duration > 60 days, reconsider: increase MDE, reduce variance (CUPED),
  increase traffic, or question if the metric is the right one
- Network effects (marketplace, social features) may require cluster randomization or
  switchback design — standard A/B will give biased results
