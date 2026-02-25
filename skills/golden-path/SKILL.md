---
name: golden-path
description: Create or update a golden path for a common developer task
---

# Golden Path

Create or update a golden path (paved road) for the specified task. $ARGUMENTS

## Process

1. **Identify the task and current friction**:
   - What task is being paved? (deploy, debug, scale, rotate secrets, add dependency, etc.)
   - How is it done today? Document the current steps.
   - Where is the friction? (manual steps, unclear docs, missing tools, error-prone)
   - How often is this task performed? By how many people?
   - **Signal**: step count (before), time to complete (before), error rate

2. **Design the paved road**:
   - Goal: minimize human steps, maximize automation
   - Principles:
     - **One command** is the ideal — everything should flow from a single invocation
     - **Progressive disclosure** — simple for the common case, options for the advanced case
     - **Fail safely** — errors should be clear, recovery should be documented
     - **Self-documenting** — the tool should explain what it's doing as it does it
   - Design the workflow:
     - What's the entry point? (CLI command, script, CI workflow, agent skill)
     - What inputs are needed? (minimize — use sensible defaults)
     - What are the steps? (automate as many as possible)
     - What's the output? (clear success/failure with next steps)
   - Identify what can be automated vs what requires human judgment:
     - Automate: builds, tests, deploys, config generation, monitoring setup
     - Human judgment: architecture decisions, naming, security reviews, scope changes

3. **Implement the golden path**:
   - Create the automation (script, CI workflow, agent skill, or CLI tool)
   - Write documentation:
     - Quick start (the 80% case — get it done in <2 minutes)
     - Full reference (all options, edge cases, troubleshooting)
     - Examples with real (not lorem ipsum) scenarios
   - Test the path end-to-end:
     - Happy path: does it work for the common case?
     - Error cases: what happens when things go wrong?
     - Edge cases: unusual inputs, existing state, concurrent runs

4. **Measure improvement**:
   - Compare before vs after:
     - Step count reduction
     - Time to complete reduction
     - Error rate reduction (if measurable)
   - **Signal**: steps before/after, time before/after, adoption rate after 30 days

5. **Produce report**:

```
## Golden Path Report
**Date**: YYYY-MM-DD
**Task**: [what was paved]

## Before
- Steps: N
- Estimated time: N minutes
- Common failure points: [list]

## After
- Steps: N
- Estimated time: N minutes
- Automation coverage: N%

## Implementation
- Entry point: [command/script/workflow]
- Documentation: [location]
- Tests: [what was tested]

## Adoption (after 30 days)
- Teams using the path: N/N
- Off-path usage: N (with justification: N)
```

## Rules

- Golden paths are OPTIONAL — provide the best path, not the only path
- Focus on day-50 operations (recurring tasks), not day-1 scaffolding (project setup)
- The path must be TESTED end-to-end before publishing — an untested golden path
  that fails on first use destroys trust
- Documentation must include REAL examples, not hypothetical ones
- Friction is the enemy: if the golden path has more steps than the ad-hoc way,
  nobody will use it
- Adoption is earned, not mandated — if adoption is low, the path has friction.
  Fix the friction, don't mandate the path.
- Version the golden path — breaking changes need migration guides
- Quick start must fit in a terminal screen — if it requires scrolling, it's too long
