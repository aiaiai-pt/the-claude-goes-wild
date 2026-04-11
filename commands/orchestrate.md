---
name: orchestrate
description: Full gated pipeline — scan, implement, review (Ralph-loop), spec review
argument-hint: "<task-description>"
---

You are the orchestration layer. Run the full gated multi-agent pipeline.

Task: $ARGUMENTS
Handoffs directory: `.agent-handoffs/` (create if not exists)
Spec: `spec/requirements.md`

## Phase 1 — Analysis

1. Run `/scan` to execute local security scans and produce a triage report
2. Use the `security-analyst` agent to produce `.agent-handoffs/security-report.md`
3. Produce `.agent-handoffs/joint-plan.md` with task list and `approved: true/false`

### GATE 1
Check `.agent-handoffs/joint-plan.md` for `approved: true`.
Do NOT proceed until present. If missing after analysis, surface to user.

## Phase 2 — Implementation

1. Read `.agent-handoffs/joint-plan.md` — implement per the plan
2. After each task, append a note to `.agent-handoffs/implementation-notes.md`
3. Implement exactly what is in the plan — no gold-plating

## Phase 3 — Code Review (Ralph-Loop)

1. Use the `code-reviewer` agent in Ralph-loop mode
2. Agent reads implementation notes + git diff
3. Agent writes `.agent-handoffs/review-feedback.md`

### GATE 2
Check `.agent-handoffs/review-feedback.md` for `ralph_approved: true`.
If not approved, report blocking issues and halt.

## Phase 4 — Spec Review

1. Use the `technical-product-manager` agent in Ralph-loop spec review mode
2. Agent reads `spec/requirements.md` + implementation notes + review feedback
3. Agent writes `.agent-handoffs/spec-delta.md`

## Cleanup

After Phase 4 completes:
1. Confirm all agents have written their memory entries to `.agent-memory/`
2. Read and record final status values:
   - `spec_approved` from `spec-delta.md`
   - `ralph_approved` from `review-feedback.md`
3. Delete: `rm -rf .agent-handoffs/`
4. Append cleanup entry to `.agent-memory/meta/consolidation-log.md`
5. Report final status to user — quote both approval values and list any open items

## Cleanup on Failure

If halted at any gate or due to blocked agent:
- Still delete `.agent-handoffs/` after reporting to the user
- Memory entries written up to failure point are kept
- Log failure reason to `.agent-memory/meta/consolidation-log.md`

## Rules

- Never skip a gate
- Reference files by path — never inline large content into agent prompts
- If any phase writes `blocked: true`, halt and report to user
- Log all phase transitions to `.agent-handoffs/orchestrator-log.md`
- Report to user only on: gate failure, blocked agent, or final spec-delta written
