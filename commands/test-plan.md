---
description: >
  Design a comprehensive test plan for the architecture. Covers data quality gates,
  unit tests, integration tests, API contract tests, E2E tests, performance tests,
  and CI/CD pipeline design. Run after module specs are complete, or standalone
  for existing systems.
argument-hint: "[module ID or scope]"
---

# /test-plan — Design Test Strategy

1. Check if module specs exist in `docs/architect-process/architecture/modules/`
   - If yes, use them as input
   - If no, ask the user which system/modules to test-plan

2. Use `@agent-test-architect` with the module specs and architecture overview

3. Output: `docs/architect-process/architecture/TEST-PLAN.md` containing:
   - Test strategy overview (calibrated to solution type)
   - Per-module test plans (data quality gates, unit, integration, contract, E2E, performance)
   - CI/CD test pipeline design (what runs when)
   - Test infrastructure recommendations

Pass `$ARGUMENTS` to scope the test plan (e.g., `M-02` for a single module, `data-flow` for quality gates only, `performance` for load scenarios only).
