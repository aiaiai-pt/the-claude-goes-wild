---
name: orchestrate
description: Full gated pipeline — scan, implement, review (Ralph-loop), spec review
---

# Orchestrate

Run the full gated multi-agent pipeline. $ARGUMENTS

## Phases

### Phase 1 — Analysis

1. Run `/scan` to execute local security scans and produce a triage report
2. Use the `security-analyst` agent to produce `.agent-handoffs/security-report.md`
3. Produce `.agent-handoffs/joint-plan.md` with task list and `approved: true/false`

**GATE 1**: Check `joint-plan.md` for `approved: true`. Do NOT proceed until present.

### Phase 2 — Implementation

1. Read `.agent-handoffs/joint-plan.md` — implement per the plan
2. Append notes to `.agent-handoffs/implementation-notes.md` after each task
3. Implement exactly what is in the plan — no gold-plating

### Phase 3 — Code Review (Ralph-Loop)

1. Use the `code-reviewer` agent in Ralph-loop mode
2. Agent reads implementation notes + git diff
3. Agent writes `.agent-handoffs/review-feedback.md`

**GATE 2**: Check `review-feedback.md` for `ralph_approved: true`. Halt if not approved.

### Phase 4 — Spec Review

1. Use the `technical-product-manager` agent in Ralph-loop spec review mode
2. Agent reads `spec/requirements.md` + implementation notes + review feedback
3. Agent writes `.agent-handoffs/spec-delta.md`

### Cleanup

1. Confirm all agents have written memory entries to `.agent-memory/`
2. Record `spec_approved` and `ralph_approved` values
3. Delete `.agent-handoffs/`
4. Log to `.agent-memory/meta/consolidation-log.md`
5. Report final status to user

## Rules

- Never skip a gate
- Reference files by path — never inline large content
- If any phase writes `blocked: true`, halt and report
- Log all phase transitions to `.agent-handoffs/orchestrator-log.md`
