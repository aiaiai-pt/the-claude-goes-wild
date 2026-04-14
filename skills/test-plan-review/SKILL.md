---
name: test-plan-review
description: Review and improve a spec's test plan to follow the project's testing policy
allowed-tools: Read, Grep, Glob
---

# Test Plan Review

Review and improve a spec's test plan to follow the project's testing policy.

## Arguments

- A spec file path (e.g., `dev_docs/specs/m7_composable_workflows.md`)
- Or no argument — finds the most recent spec in `dev_docs/specs/` or `dev_docs/features/`

## Testing Policy

### Core Principles

1. **Outside-in, always real infrastructure.** Tests follow the code path the user would trigger. Start at the outermost boundary (API endpoint, Temporal client, CLI) and go through the full stack to DB and back.
2. **Three tiers, not one.** Every feature needs to be evaluated for all three:
   - **Tier 1 (CI):** Real infrastructure (Temporal env, real DB), external APIs mocked INSIDE activities/services (never mock the dispatch).
   - **Tier 2 (Evals):** Same paths but with REAL external service calls for critical non-deterministic boundaries. LLM calls get eval assertions (pass-rate over N attempts). HTTP calls get contract assertions. Marked `@pytest.mark.eval`, skipped in default CI.
   - **Tier 3 (Contract):** Pure data transformation tests — serialization round-trips, schema validation, seed idempotency.
3. **Never extract helpers just to make things testable.** If the code runs through Temporal, the test runs through Temporal. If it goes through FastAPI, the test hits the FastAPI endpoint.
4. **Assertions verify observable outcomes, not code internals.** Assert on data state, API responses, and side effects — NOT method return values, internal operation names, or mock call counts. "Do the right rows exist on main?" not "Did merge_branch return operation=set_current_snapshot?"

### What to Mock (and Where)

- Mock external APIs (litellm, HTTP endpoints, S3) **inside** activities/services — patch the call site, not the dispatch.
- NEVER mock internal infrastructure: DB sessions, Temporal activity dispatch, service layer calls, internal method calls.
- In Tier 2 evals, don't mock anything — call the real external service and evaluate the result.

### Eval Infrastructure (`tests/eval_utils.py`)

The project has (or should have) shared eval utilities:

- `EvalResult` — dataclass capturing: passed, expected, actual, model, latency_ms, tokens_used, attempt
- `eval_llm_classification()` — calls real LLM N times, returns list of EvalResult
- `assert_eval_pass_rate(results, min_rate=0.8)` — asserts pass rate threshold
- `eval_http_function()` — calls real HTTP endpoint, validates response status + shape

If `tests/eval_utils.py` doesn't exist yet, flag it as a prerequisite.

### Test Smells to Flag

For each test in the plan, check:

1. **Passes with no-op?** If implementing the function as `pass` or `return {}` makes the test pass, it's a false positive. Flag it.
2. **Asserts mock call counts?** `mock.assert_called_once_with(...)` is testing wiring, not behavior. Replace with output assertion. Exception: system boundary contract tests (e.g., "correct model passed to litellm") — these are acceptable.
3. **Tests internal implementation?** "prompt contains category names" tests how, not what. Reframe to test observable behavior.
4. **Duplicate coverage?** Two tests exercising the same code path with trivially different inputs. Merge or drop.
5. **Missing error paths?** Every external call can fail. Is there a test for the failure case?
6. **Missing Tier 2 eval?** Any feature involving LLM calls MUST have at least one eval test with real LLM + pass-rate assertion. Any feature calling external HTTP services SHOULD have a contract eval.
7. **Too vague?** Test description doesn't specify what the assertion is. Reframe to include the expected output.
8. **Wrong tier?** A test marked as CI that requires real external calls, or a test marked as eval that only uses mocks.
9. **Asserts on return values instead of outcomes?** `assert result["operation"] == "set_current_snapshot"` tests code, not behavior. Reframe: what observable state changed? What data exists now? What can the user see?
10. **Mocks infrastructure that could be real?** If the test mocks DB, Iceberg, Trino, or other infrastructure that's available behind a skip guard, it's hiding potential bugs. Prefer integration tests with `@pytest.mark.skipif(not infra_available)` over mocks that pass while real code is broken.
11. **Circular assertion?** `assert data["count"] == result["count"]` — both sides come from the same state object. If both are wrong, the test passes. Use concrete expected values: `assert data["count"] == 42`.
12. **Hidden fixture dependency?** Test relies on seed scripts or external state (seeded DB rows, config files) without declaring or creating that state in a fixture. The test will fail on a clean environment with a confusing error.
13. **`pytest.raises(Exception)` too broad?** Catches any error including import errors and typos. Use the specific exception type (`ValidationError`, `ValueError`, `HTTPException`).

## Process

1. **Read the spec** — find the test plan section.
2. **Read existing test patterns** — check `tests/integration/` and `tests/unit/` for the project's established patterns (fixtures, DB setup, Temporal env usage).
3. **Check for `tests/eval_utils.py`** — if it exists, verify the eval tests use it. If not, flag it as a prerequisite to create.
4. **Review each test** against the 10 smell checks above.
5. **Classify each test into tiers** — is it Tier 1, 2, or 3? Is it in the right tier?
6. **Assess mutation testing readiness:**
   - Identify the critical code paths (auth guards, tenant isolation, state transitions, error classification)
   - Check that tests use concrete expected values, not circular comparisons (`data["x"] == result["x"]` is circular — use `data["x"] == 42`)
   - Check that tests would fail if the feature code were deleted or no-op'd
   - Flag any test that only asserts mock call counts without verifying observable outcomes
   - Recommend specific files for `/mutation-test` in Phase 4 of LFG
7. **Identify missing tests:**
   - Missing error/failure paths for external calls
   - Missing eval tests for LLM interactions
   - Missing contract tests for data round-trips
   - Missing backwards compatibility tests
7. **Produce a structured report:**

```
## Test Plan Review: [Feature Name]

### Tier Assessment
| Test | Current Tier | Correct Tier | Issue |
|------|-------------|-------------|-------|

### Smells Found
| Test | Smell | Fix |
|------|-------|-----|

### Missing Tests
| What | Tier | Why |
|------|------|-----|

### Eval Coverage
- LLM calls in feature: [list]
- Eval tests covering them: [list or MISSING]
- eval_utils.py status: exists / NEEDS CREATION

### Mutation Testing Readiness
- Critical code paths identified: [list]
- Tests use concrete assertions (not circular/mock-only): [yes/no]
- Recommended `/mutation-test` targets: [files]
- Estimated mutation score: [high/medium/low based on test quality]

### Verdict
[Ready / Needs revision] — [summary of changes needed]
```

## Rules

- Do NOT modify code — this is a review-only skill
- Do NOT add tests for style/linting — focus on logic, behavior, and integration
- When in doubt about tier placement, prefer higher tier (Tier 2 > Tier 1)
- Flag any test that would pass with `return {}` as the implementation
- If the spec has no test plan section, say so and stop
