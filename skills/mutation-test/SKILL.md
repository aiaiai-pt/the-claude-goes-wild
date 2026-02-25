---
name: mutation-test
description: Generate targeted mutants and tests that kill them to prove test effectiveness
---

# Mutation Test

Generate mutants for the specified code and verify tests catch them. $ARGUMENTS

## Process

1. **Identify target code**:
   - If arguments specify files: use those
   - If invoked during BUILD: target changed files (`git diff --name-only` against base branch)
   - If invoked standalone: target files with lowest coverage or highest complexity
   - Skip: test files, config files, generated code, type definitions

2. **Generate mutants** (Meta ACH pattern — LLM generates fault + killing test):

   For each target function/method, generate mutants from these fault classes:
   - **Boundary**: off-by-one errors, wrong comparison operator (< vs <=, > vs >=)
   - **Negation**: inverted boolean conditions, swapped if/else branches
   - **Arithmetic**: wrong operator (+/-/\*/÷), missing operation, wrong operand
   - **Null/empty**: removed null checks, empty collection handling, missing default values
   - **Return value**: wrong return value, early return, missing return
   - **Exception**: removed try/catch, wrong exception type, swallowed error
   - **State**: wrong variable assignment, missed state update, wrong initialization
   - **API contract**: wrong parameter order, missing required field, wrong type coercion

   For each mutant:
   - Describe the fault in plain language (e.g., "changed >= to > on line 42")
   - Apply the mutation to a copy of the code
   - Run existing tests against the mutant
   - **Signal**: test suite exit code — 0 means mutant SURVIVED (tests are weak),
     non-zero means mutant was KILLED (tests caught the bug)

3. **For surviving mutants — generate killing tests**:
   - For each mutant that survived:
     - Describe what the mutant changed
     - Generate a test that specifically exercises the mutated behavior
     - The test MUST fail against the mutant AND pass against the real code
     - Verify both conditions by running the test twice
   - **Signal per generated test**: kills mutant (yes/no) + passes real code (yes/no)
   - If a generated test doesn't kill its target mutant, discard and regenerate (max 3 attempts)

4. **Validate generated tests are not facades**:
   - For each generated test, check: would this test pass if the function under test
     returned a hardcoded value or no-op? If yes, the test is a facade — delete it.
   - The test must assert on observable outcomes (data state, API response, side effects),
     NOT on return values alone or internal method calls.

5. **Calculate mutation score**:

   ```
   Mutation Score = (Killed Mutants / Total Mutants) × 100%
   ```

6. **Produce report**:

```
## Mutation Test Report
**Date**: YYYY-MM-DD
**Scope**: [files]

## Summary
- Total mutants generated: N
- Killed by existing tests: N
- Killed by new tests: N
- Surviving (unkillable): N
- **Mutation Score**: N% (target: N%)

## Surviving Mutants
| File:Line | Fault Class | Mutation | Why It Survived |
|-----------|-------------|----------|-----------------|

## Generated Tests
| Test | Target Mutant | Kills Mutant | Passes Real Code | Facade Check |
|------|--------------|-------------|-----------------|-------------|

## Files by Score
| File | Mutants | Killed | Score |
|------|---------|--------|-------|
```

## Rules

- Generate at least 3 mutants per non-trivial function, more for complex functions
- Never generate a mutant that would cause a syntax error or compilation failure
- Always verify generated tests against BOTH mutant (must fail) and real code (must pass)
- Discard any test that is a facade (passes with no-op)
- If a mutant survives and no killing test can be generated after 3 attempts,
  mark it as "unkillable" with a note explaining why (equivalent mutant, or
  genuinely untestable behavior)
- Mutation score is the primary output signal — it must be a single number
  that downstream processes can compare against a threshold
- Security-critical code (auth, crypto, payment, data access) gets extra mutants
  focused on bypass and escalation fault classes
