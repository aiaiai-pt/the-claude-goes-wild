---
name: qfg
description: Quality Flow - mutation testing, property-based tests, contract tests, load tests. Proves tests catch real bugs.
argument-hint: [scope: assess | mutate | harden | stress | certify | full]
---

# QFG — Quality Flow, Go

Run the quality process for the specified scope: $ARGUMENTS

If no scope is specified, run Phase 2 (Mutate) on the current codebase as the default.

## Phase 1: Assess

**When**: Before writing new tests. Understand the current test landscape.
**Purpose**: Measure what exists and identify gaps worth closing.

1. **Inventory the test suite**:
   - Count tests by type: unit, integration, e2e, contract, property, load
   - Run the full suite and capture: pass count, fail count, skip count, duration
   - Measure line and branch coverage for changed files (or full codebase if standalone)
   - **Signal**: coverage % per file, test count by type, suite exit code

2. **Identify gaps**:
   - Changed code paths without corresponding tests
   - Public functions/methods with zero test coverage
   - Error paths with no negative test (only happy path tested)
   - API endpoints without contract tests
   - High-complexity functions (cyclomatic complexity > 10) without property tests

3. **Score the current state**:

```
## Quality Assessment
**Date**: YYYY-MM-DD
**Scope**: [files/full]

## Coverage
| File | Line % | Branch % | Gap |
|------|--------|----------|-----|

## Test Inventory
| Type | Count | Passing | Failing | Skipped |
|------|-------|---------|---------|---------|

## Gaps Identified
- [ ] [Specific gap with file:line and suggested test type]

## Baseline Mutation Score
- [If previous mutation run exists, report it. Otherwise: "No baseline — run Phase 2"]
```

## Phase 2: Mutate

**When**: During BUILD, alongside implementation. Also invocable standalone.
**Purpose**: Prove that tests catch real bugs, not just exercise code.

4. Run `/mutation-test` against changed code paths (or specified scope)
5. **Decision rules based on deterministic signals**:
   - Mutation score >= target (set at BET, default 80%) → **PASS**
   - Mutation score < target but > 60% → **WARN**. Identify surviving mutants, generate tests to kill them.
   - Mutation score <= 60% → **FAIL**. Tests are not catching enough real faults. Block SHIP.
   - Any surviving mutant in security-critical code → **FAIL** regardless of score
6. For each surviving mutant, generate a test that kills it:
   - Describe the fault class in plain language
   - Generate the test
   - Verify the test kills the mutant (run it)
   - Verify the test passes against the real (unmutated) code
   - **Signal**: mutant killed yes/no per generated test

## Phase 3: Harden

**When**: After Mutate, or standalone to strengthen test suite.
**Purpose**: Find edge cases humans miss.

7. Run `/property-test` on modules with public APIs or complex logic:
   - Identify invariants: what must ALWAYS be true regardless of input?
   - Examples: "output length <= input length", "parse(serialize(x)) == x",
     "balance never goes negative", "sorted output is same length as input"
   - Generate property-based tests using Hypothesis (Python), fast-check (JS/TS),
     or equivalent for the project language
   - Run with sufficient examples (default: 200 per property, configurable)
   - **Signal**: property violation found yes/no + shrunk counterexample

8. Run `/contract-test` on new or changed API endpoints:
   - Identify all API contracts (OpenAPI specs, GraphQL schemas, gRPC protos)
   - For new endpoints: generate consumer contract tests from the spec
   - For changed endpoints: verify existing contracts still hold
   - **Signal**: contract verification pass/fail per consumer-provider pair

9. **Decision rules**:
   - Property violation found → **FIX the code** (the property is an invariant,
     the code is wrong). Report the counterexample.
   - Contract broken → **BLOCK SHIP**. Either fix the provider or update the contract
     with a version bump and consumer notification.

## Phase 4: Stress

**When**: During SHIP, before progressive rollout. Only for bets with performance-sensitive changes.
**Purpose**: Establish performance baselines and catch regressions.

10. Run `/load-test` on changed or new endpoints:
    - Generate k6 or Gatling scripts targeting the changed endpoints
    - Run against staging with realistic load patterns:
      - Ramp-up: 0 → target RPS over 30 seconds
      - Sustained: hold target RPS for 2 minutes
      - Spike: 2x target RPS for 30 seconds
    - Capture: p50, p95, p99 latency, error rate, throughput
    - **Signal**: all numeric, comparable against baseline

11. **Decision rules**:
    - p99 latency > 2x baseline → **WARN**. Investigate before rollout.
    - p99 latency > 5x baseline → **BLOCK**. Performance regression confirmed.
    - Error rate > 1% under sustained load → **BLOCK**.
    - Error rate > 5% under spike load → **WARN**.
    - If no baseline exists, this run BECOMES the baseline. Store it.

## Phase 5: Certify

**When**: Before SHIP. Produces the quality gate verdict.
**Purpose**: Single pass/fail decision that downstream processes can trust.

12. Aggregate all quality signals into a certification report:

```
## Quality Certification
**Date**: YYYY-MM-DD
**Bet**: [name/id]
**Target mutation score**: N% (set at BET)

## Mutation Testing
- Score: N% (target: N%) — PASS / FAIL
- Surviving mutants: N (N in security-critical code)
- Tests generated to kill survivors: N

## Property Testing
- Properties tested: N
- Violations found: N — PASS / FAIL
- [If violations: counterexamples listed]

## Contract Testing
- Contracts verified: N
- Broken contracts: N — PASS / FAIL
- [If broken: consumer-provider pairs listed]

## Load Testing
- Endpoints tested: N
- p99 vs baseline: [delta]
- Error rate: N% — PASS / FAIL / SKIPPED
- [If regression: specific endpoints listed]

## Coverage
- Line coverage (changed files): N%
- Branch coverage (changed files): N%

## Verdict
**CERTIFIED** / **NOT CERTIFIED**
Blocking issues: [list]
```

13. **Verdict logic** (all must pass for CERTIFIED):
    - Mutation score >= target
    - Zero property violations (all fixed)
    - Zero broken contracts (all fixed or versioned)
    - Load test within thresholds (or SKIPPED if not performance-sensitive)
    - No surviving mutants in security-critical code

## Rules

- NEVER modify application code — QFG only creates and modifies tests
- Mutation score target is set per-bet during BET phase. Default: 80%.
- Property tests must use REAL invariants, not tautologies ("result is not null" is not a property)
- Contract tests test the INTERFACE, not the implementation
- Load test baselines are stored and versioned — never discard a baseline without reason
- If a test generated by QFG is a facade (passes with no-op implementation), delete it and try again
- Quality certification is a hard gate — NOT CERTIFIED blocks SHIP, no override by agents
- All signals must be numeric and deterministic: scores, counts, pass/fail exit codes
