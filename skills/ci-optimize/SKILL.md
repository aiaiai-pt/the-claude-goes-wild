---
name: ci-optimize
description: Analyze and optimize CI/CD pipeline performance
---

# CI Optimize

Analyze and optimize the CI/CD pipeline. $ARGUMENTS

## Process

1. **Profile pipeline stages**:
   - Identify all CI/CD pipelines in the project:
     - GitHub Actions: `.github/workflows/`
     - GitLab CI: `.gitlab-ci.yml`
     - CircleCI: `.circleci/config.yml`
     - Other: Jenkinsfile, Buildkite, etc.
   - For each pipeline, profile stages:
     - Stage name and purpose
     - Average duration (from recent runs — use `gh run list --json` or equivalent)
     - Success/failure rate
     - Cache hit rate (if caching is configured)
     - Cost (if metered — compute minutes × cost per minute)
   - **Signal**: duration per stage (seconds), success rate %, cache hit rate %, cost

2. **Identify bottlenecks**:
   - **Slowest stages**: Which stages take the most time?
     - Are tests slow? Which test files are the slowest 10%?
     - Are builds slow? Is incremental building configured?
     - Are deployments slow? Can they be parallelized?
   - **Uncached dependencies**: Are deps downloaded every run?
     - Check for: `actions/cache`, `pip cache`, `npm cache`, Docker layer caching
     - Estimate time saved with proper caching
   - **Serial steps that could be parallel**: Are independent steps running sequentially?
     - Lint + typecheck + test can often run in parallel
     - Multi-platform builds can run in parallel
   - **Unnecessary steps**: Are any steps redundant?
     - Running lint twice (once in pre-commit, once in CI)
     - Building artifacts that aren't used
     - Running full test suite when only a subset is affected

3. **Detect flaky tests**:
   - Query test history for non-deterministic results:
     - Same test, same code, different results across runs
     - Tests that fail on CI but pass locally (environment-dependent)
     - Tests with timing dependencies (sleep, setTimeout, race conditions)
   - Calculate flake rate per test:
     - `flake_rate = (inconsistent_runs / total_runs) × 100%`
   - **Signal**: flake rate % per test, total flaky test count

4. **Recommend optimizations**:

   | Finding | Optimization | Expected Improvement |
   |---------|-------------|---------------------|
   | Slow test suite (>5 min) | Test parallelization, test sharding | 2-5x speedup |
   | No dependency caching | Add cache steps for package managers | 30-60s savings |
   | No Docker layer caching | Enable BuildKit caching, multi-stage builds | 1-5 min savings |
   | Serial independent stages | Parallelize with matrix/fan-out | 30-50% speedup |
   | Full suite on all PRs | Affected-test detection (test impact analysis) | 50-80% reduction |
   | Flaky tests (>5%) | Quarantine to optional job, file fix issue | Fewer false failures |
   | Redundant steps | Remove duplicates, share artifacts | Direct time savings |
   | Large artifacts | Compress, use artifact storage efficiently | Transfer time savings |

5. **Implement optimizations** (if scope allows):
   - Apply safe optimizations directly:
     - Add caching for dependencies
     - Parallelize independent stages
     - Remove obviously redundant steps
   - For risky optimizations, create a PR with before/after measurements:
     - Test sharding changes
     - Affected-test detection
     - Build system changes
   - **Signal**: build time before vs after (seconds), cost before vs after

6. **Produce report**:

```
## CI/CD Optimization Report
**Date**: YYYY-MM-DD

## Pipeline Profile
| Pipeline | Avg Duration | Success Rate | Cache Hit Rate | Monthly Cost |
|----------|-------------|-------------|----------------|-------------|

## Bottlenecks
| Stage | Duration | Issue | Optimization | Est. Savings |
|-------|----------|-------|-------------|-------------|

## Flaky Tests
| Test | Flake Rate | Last Failure | Recommendation |
|------|-----------|-------------|---------------|

## Applied Optimizations
| Optimization | Before | After | Improvement |
|-------------|--------|-------|-------------|

## Recommended (Not Yet Applied)
| Optimization | Effort | Expected Improvement | Risk |
|-------------|--------|---------------------|------|

## Summary
- Total pipeline duration: N min → N min (N% improvement)
- Flaky tests quarantined: N
- Estimated monthly cost savings: $N
```

## Rules

- Measure before optimizing — intuition about what's slow is often wrong
- Cache everything that doesn't change between runs: dependencies, build artifacts,
  Docker layers, test fixtures
- Parallelism is the biggest lever — independent stages should never run sequentially
- Flaky tests are a trust destroyer — quarantine aggressively (>5%), fix urgently (>20%)
- Affected-test detection is high-effort but high-reward for large test suites —
  only recommend for suites >10 minutes
- Never remove a CI check to make the pipeline faster — optimize the check, don't skip it
- Build time creeps up over time — run this analysis weekly, not quarterly
- Report savings in both time (developer wait time) and cost (compute minutes)
- Test with real PRs after optimization — synthetic benchmarks can be misleading
