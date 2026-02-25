---
name: deepen-plan
description: Enhance an implementation plan using parallel research agents before coding begins
---

# Deepen Plan

Enhance the current implementation plan by running parallel research. $ARGUMENTS

## Process

1. **Locate the plan**: Find the most recent plan file in:
   - dev_docs/specs/
   - dev_docs/features/
   - dev_docs/sprint_*/planning/
   - Or the plan file specified in arguments

2. **Launch parallel research agents** (use sub-agents, not agent teams):

   Spawn these simultaneously:

   a. **Pattern scout**: Search the codebase for existing implementations of
      similar features. Look for code that can be reused or extended.
      Report: "Found patterns: [list with file:line references]"

   b. **Dependency checker**: For each component in the plan, verify that
      dependencies exist (packages, APIs, database tables, services).
      Report: "Missing dependencies: [list]" or "All dependencies satisfied"

   c. **Risk assessor**: Identify the riskiest parts of the plan — what's most
      likely to fail or take longer than expected? Check for:
      - Missing migrations
      - API contracts that don't exist yet
      - Services that need to be running
      - Cross-service coordination points
      - **Rabbit holes** — areas where scope could expand unboundedly.
        For each, recommend a fixed boundary and rationale.
      Report: "Risks: [list with severity and mitigation]"
      Report: "Rabbit holes: [list with recommended boundaries]"

   d. **Test planner**: For each deliverable in the plan, define what tests
      should exist. Classify each test into tiers:
      - **Tier 1 (CI):** Real infrastructure, external APIs mocked inside activities/services
      - **Tier 2 (Eval):** Real external calls for critical non-deterministic boundaries (LLM, HTTP). Pass-rate assertions.
      - **Tier 3 (Contract):** Pure data transformations, schema validation, serialization round-trips
      For each test, verify the assertion is outcome-focused:
      - GOOD: "verify sandbox table has 3 rows with expected column values"
      - BAD: "verify create_wap_branch returns branch name"
      Flag any test that asserts on return values instead of observable state.
      Report: "Test plan: [list of test descriptions per component with tier]"

3. **Synthesize findings**: Merge all agent reports into the plan:
   - Add a "## Existing Patterns to Reuse" section
   - Add a "## Risks and Mitigations" section
   - Add a "## Rabbit Holes" section — decisions already made, with rationale. These are NOT to be revisited during implementation.
   - Add a "## Test Plan" section (three-tier)
   - Add a "## Hill Chart" section:
     ```
     | Scope | Position | Why |
     |-------|----------|-----|
     ```
     Classify each scope as:
     - **Uphill** — we don't know HOW yet (needs more research before implementation)
     - **Hilltop** — we know how but haven't done it (ready to implement)
     - **Downhill** — straightforward execution (pattern exists, just wire it)
   - Flag any scope still "Uphill" as a risk — it needs research before implementation begins
   - Flag any tasks that should be reordered based on dependencies
   - Update effort estimates if risks change the picture

4. **Present the deepened plan** to the user for approval before proceeding.

## Rules

- Do NOT modify code during this phase — this is research only
- Do NOT create new files except updating the plan itself
- If a risk is critical (blocks multiple tasks), flag it prominently
- If existing code covers >50% of a planned feature, recommend extending rather than building new
- Every scope must reach at least Hilltop before implementation begins — flag Uphill scopes prominently
