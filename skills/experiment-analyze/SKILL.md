---
name: experiment-analyze
description: Analyze experiment results with statistical rigor and produce impact reports
---

# Experiment Analyze

Analyze the results of the specified experiment. $ARGUMENTS

## Process

1. **Gather experiment data**:
   - Read the experiment spec (from Phase 2: Design)
   - Pull metric data from the experiment platform or analytics API:
     - Per-variant: sample size, metric mean, metric variance
     - For each guardrail metric: per-variant values
     - Assignment data: how many users per variant
   - Verify data completeness:
     - Expected sample vs actual sample
     - Missing data rate per variant
     - Date range coverage
   - **Signal**: data completeness %, sample size per variant

2. **Check data quality**:
   - **Sample Ratio Mismatch (SRM)**:
     - Expected ratio: [from experiment design, e.g., 50/50]
     - Observed ratio: [actual assignment counts]
     - Chi-squared test: `χ² = Σ((observed - expected)² / expected)`
     - p-value from chi-squared distribution with df = num_variants - 1
     - SRM detected if p < 0.01
   - If SRM detected → **EXPERIMENT INVALID**. Stop analysis. Report:
     - Observed vs expected ratio
     - Possible causes: buggy assignment, bot traffic, filter issues
     - Do NOT trust any metric results
   - **Signal**: SRM detected yes/no, chi-squared p-value

3. **Run primary metric analysis**:
   - For fixed-horizon:
     - Two-sample t-test (for continuous metrics) or z-test (for proportions)
     - Calculate: effect size (absolute and relative), confidence interval, p-value
   - For sequential:
     - Apply the spending function to get the adjusted significance threshold
     - Compare observed p-value against adjusted threshold (not raw 0.05)
   - Calculate practical significance:
     - Is the effect size ≥ MDE? (Statistical significance with tiny effect = noise)
     - What's the confidence interval? Does it include zero?
     - What's the probability of being best (Bayesian complement if desired)?
   - **Signal**: p-value, effect size, CI, practically significant yes/no

4. **Check guardrail metrics**:
   - For each guardrail metric:
     - Calculate treatment vs control difference
     - Compare against the pre-defined regression threshold
     - A guardrail "fails" if the treatment regresses beyond threshold
       AND the regression is statistically significant (p < 0.10 — more lenient
       than primary to catch genuine harm)
   - **Signal**: guardrail pass/fail per metric

5. **Determine conclusion**:

   | SRM | Primary | Guardrails | Conclusion | Recommendation |
   |-----|---------|-----------|------------|----------------|
   | Detected | — | — | **INVALID** | Investigate assignment, re-run |
   | Clean | Sig. positive, practical | All pass | **WINNER** | Ship 100%, clean up flag |
   | Clean | Sig. positive, practical | Any fail | **TRADEOFF** | Human decides: is the win worth the cost? |
   | Clean | Sig. positive, NOT practical | All pass | **INCONCLUSIVE** | Effect too small to matter — iterate |
   | Clean | Not significant | All pass | **INCONCLUSIVE** | Need more sample, bigger change, or different metric |
   | Clean | Sig. negative | — | **LOSER** | Kill treatment, revert |
   | Clean | — | Multiple fail | **LOSER** | Guardrail failures dominate — kill treatment |

6. **Generate impact report**:

```
## Experiment Impact Report
**Date**: YYYY-MM-DD
**Bet**: [name]
**Duration**: N days (YYYY-MM-DD to YYYY-MM-DD)

## Data Quality
- Total sample: N (control: N, treatment: N)
- Expected ratio: N/N, Observed ratio: N/N
- SRM test: p = N → PASS / FAIL
- Data completeness: N%
- Missing data: N%

## Primary Metric: [name]
| Variant | N | Mean | Std Dev |
|---------|---|------|---------|
| Control | N | N | N |
| Treatment | N | N | N |

- Absolute effect: N (CI: [N, N])
- Relative effect: N% (CI: [N%, N%])
- p-value: N
- Statistically significant (α=0.05): yes/no
- Practically significant (≥ MDE of N%): yes/no

## Guardrail Metrics
| Metric | Control | Treatment | Delta | Threshold | p-value | Status |
|--------|---------|-----------|-------|-----------|---------|--------|

## Conclusion
**WINNER / LOSER / INCONCLUSIVE / TRADEOFF / INVALID**

## Interpretation
[Plain language: what happened, why it matters, what to do next]

## Recommended Action
- **SHIP**: Deploy to 100%. Remove feature flag within 1 week.
- **ITERATE**: [Specific suggestions for next experiment]
- **KILL**: Revert treatment code. Clean up feature flag.
- **INVESTIGATE**: [For INVALID/TRADEOFF — what needs human judgment]

## Statistical Details
- Test type: [t-test / z-test / sequential with spending function]
- Methodology: [fixed-horizon / sequential]
- [If sequential] Adjusted threshold: N (from spending function)
- [If CUPED applied] Variance reduction: N%
```

## Rules

- ALWAYS check SRM before any other analysis — SRM invalidates everything else
- NEVER report a result as significant if SRM is detected — the data cannot be trusted
- Confidence intervals are more informative than p-values — report both, emphasize CI
- Practical significance matters: a statistically significant 0.01% lift is noise, not a win
- Guardrail failures require statistical evidence too — don't fail on random noise
  (use p < 0.10, more lenient than primary, but still requires evidence)
- For sequential testing, ALWAYS use the adjusted threshold from the spending function —
  using raw p < 0.05 inflates false positive rate
- If the experiment ran for < 7 days, flag potential day-of-week confounding
- Report per-day trends if available — a metric that was winning early but losing late
  suggests novelty effects (users trying the new thing, then abandoning)
- INCONCLUSIVE is a valid result — it means we learned we need a bigger effect or more data,
  not that the experiment "failed"
- All numbers in the report must be reproducible — document the exact queries and calculations
