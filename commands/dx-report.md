---
description: >
  Generate a DX report for senior architects and CTO. Summarizes architecture decisions,
  risks, stack alignment, and readiness. Run anytime after shaping is complete.
argument-hint: "[brief|readiness|summary]"
---

# /dx-report — Generate DX/Leadership Report

1. Read all architect process artifacts from `docs/architect-process/`
2. Use `@agent-dx-reporter` to generate the appropriate report type:
   - **Architecture Brief**: after shaping (default)
   - **Cycle Readiness**: before a build cycle (pass `readiness`)
   - **Process Summary**: after the full pipeline completes (pass `summary`)
3. Save to `docs/architect-process/dx-reports/`

Pass `$ARGUMENTS` to specify report type: `brief` (default), `readiness`, `summary`.
