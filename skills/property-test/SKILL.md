---
name: property-test
description: Generate property-based tests by identifying invariants that must always hold
---

# Property Test

Generate property-based tests for the specified module or code. $ARGUMENTS

## Process

1. **Identify target modules**:
   - If arguments specify modules/files: use those
   - If invoked during BUILD: target modules with changed public APIs
   - If invoked standalone: target modules with highest complexity or most critical business logic
   - Focus on: pure functions, data transformations, serialization/deserialization,
     sorting/filtering, state machines, mathematical operations, parsers

2. **Identify invariants** — what must ALWAYS be true regardless of input:

   Common invariant patterns:
   - **Round-trip**: `deserialize(serialize(x)) == x`, `decode(encode(x)) == x`
   - **Idempotent**: `f(f(x)) == f(x)` (e.g., formatting, normalization)
   - **Monotonic**: output grows/shrinks predictably with input
   - **Conservation**: output preserves some quantity (e.g., sort preserves length)
   - **Commutativity**: `f(a, b) == f(b, a)` where expected
   - **Bounds**: output always within expected range, never negative when shouldn't be
   - **Inverse**: `undo(do(x)) == x` (e.g., encrypt/decrypt, compress/decompress)
   - **Equivalence**: two implementations produce the same result (oracle testing)
   - **No crash**: function handles all valid inputs without throwing (robustness)
   - **Relationship**: output relates to input in a predictable way

   For each function, ask: "If I gave this function a million random valid inputs,
   what would ALWAYS be true about the output?"

3. **Generate property tests**:
   - Use the project's language-appropriate library:
     - Python: `hypothesis` with `@given` decorator and `st.` strategies
     - JavaScript/TypeScript: `fast-check` with `fc.assert` and `fc.property`
     - Rust: `proptest` with `proptest!` macro
     - Go: `testing/quick` or `gopter`
     - Java: `jqwik` with `@Property` annotation
   - For each invariant:
     - Define input generators (strategies) that produce valid inputs
     - Write the property assertion
     - Set example count (default: 200, increase for critical code)
   - **Signal**: property holds (pass) or violation found (fail + shrunk counterexample)

4. **Run and analyze**:
   - Run all generated property tests
   - For each violation:
     - The shrunk counterexample is the smallest input that breaks the property
     - Determine: is this a bug in the code or a bad property definition?
     - If bug in code: report as a finding with the counterexample
     - If bad property: fix the property and re-run
   - **Signal**: violation count, counterexample for each

5. **Validate quality**:
   - Each property must be FALSIFIABLE — it must be possible for it to fail
   - Reject tautological properties:
     - BAD: "result is not undefined" (almost always true, catches nothing)
     - BAD: "function returns a value" (useless)
     - BAD: "output has correct type" (compiler already checks this)
   - GOOD properties test SEMANTIC correctness, not syntactic:
     - GOOD: "sorted array has same elements as input"
     - GOOD: "parsed date is always valid (no Feb 30th)"
     - GOOD: "balance after withdrawal = balance before - amount"

6. **Produce report**:

```
## Property Test Report
**Date**: YYYY-MM-DD
**Scope**: [modules]

## Properties Tested
| Module | Property | Examples Run | Result | Counterexample |
|--------|----------|-------------|--------|----------------|

## Violations Found
| Module | Property | Counterexample | Assessment |
|--------|----------|----------------|------------|
| | | [shrunk input] | Bug in code / Bad property |

## Summary
- Properties defined: N
- Properties holding: N
- Violations found: N (N bugs, N bad properties)
- Total examples run: N
```

## Rules

- Every property must be falsifiable — reject tautologies
- Properties test SEMANTIC invariants, not type safety
- Use the framework's shrinking to produce minimal counterexamples
- A violation is a finding UNTIL proven to be a bad property definition
- 200 examples minimum per property. 1000 for security-critical or financial code.
- Don't write properties for trivial getters/setters — focus on logic
- When a counterexample reveals a bug, the fix belongs in application code,
  not in the property definition. Never weaken a property to make it pass.
- Generated strategies must produce VALID inputs according to the function's
  contract. Testing with invalid inputs is a separate concern (robustness testing).
