---
name: status
description: Check the current state of the agent orchestration pipeline
---

Check the current state of the agent run. Read-only — do not modify any files.

Read the following files if they exist and summarise their status:

- `.agent-handoffs/orchestrator-log.md` — what phases have completed
- `.agent-handoffs/ci-findings.json` — scan status (complete/partial/failed)
- `.agent-handoffs/security-report.md` — security findings summary
- `.agent-handoffs/joint-plan.md` — approved: true/false, task list
- `.agent-handoffs/implementation-notes.md` — what was implemented
- `.agent-handoffs/review-feedback.md` — ralph_approved: true/false
- `.agent-handoffs/spec-delta.md` — spec_approved: true/false, recommendation

Report a one-line status per file. If `.agent-handoffs/` does not exist, say so.
