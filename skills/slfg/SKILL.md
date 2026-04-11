---
name: slfg
description: Swarm LFG - parallel autonomous engineering using agent teams
argument-hint: [feature description]
---

# SLFG - Swarm Autonomous Feature Pipeline

Build this feature using parallel agent teams: $ARGUMENTS

Run these phases in order. Parallelize where indicated.

## Sequential Phase

1. **Explore first**: Before asking anything, read project docs to understand context:
   - Project CLAUDE.md (conventions, architecture, key patterns)
   - Recent sprint plans in dev_docs/sprint_*/planning/
   - Existing specs in dev_docs/specs/ that relate to this feature
   - Solution docs in dev_docs/solutions/ for reusable patterns
   - Relevant source files to understand what already exists
2. Create a feature branch: `git checkout -b feat/<short-name>`
3. **Breadboard first**: Sketch the flow (places, affordances, connections) before writing a full spec. Present to user for feedback.
4. **Set appetite**: NOW ask the user: "What's the appetite for this?" — they can gauge it because you've presented what exists and what's needed. Record in spec header.
5. Write a spec in `dev_docs/specs/<feature-name>.md` with appetite, rabbit holes, and out-of-scope sections.
6. Wait for user approval of the spec.
7. Run `/deepen-plan` to enhance with parallel research agents (includes hill chart and rabbit hole identification).
8. **SFG threat model** (parallel with deepen): If the bet touches auth, data, payments, API keys,
   file uploads, or admin interfaces, run `/threat-model` against the spec. Append the threat
   model to the spec. High/Critical threats become rabbit holes.
9. **Hill chart gate**: All scopes must be at Hilltop or Downhill before entering Swarm Phase. Run focused spikes for any Uphill scopes — spikes produce artifacts (test files, bug fixes, decision docs). Update the plan with findings.
10. Wait for user approval of the deepened plan.

## Swarm Phase

10. Create an agent team for implementation:
   - Break the plan into **vertical scopes** (feature slices), not horizontal layers
   - Each scope is independently demoable (e.g., "N1 SubWorkflow: activity + workflow + tests")
   - Spawn teammates per scope, not per layer:
     - **scope-a**: Complete slice A (backend + frontend + tests)
     - **scope-b**: Complete slice B (backend + frontend + tests)
     - **shared**: Cross-cutting concerns (migrations, seed, config)
   - Each teammate claims tasks from the shared task list
   - Use delegate mode (Shift+Tab) to coordinate without coding yourself
   - **Appetite check**: After each teammate completes, check if accumulated work is within appetite. If exceeding, stop spawning new teammates and ask the user.
   - Wait for all teammates to complete

## Quality + Security Phase

After implementation completes, launch these as parallel sub-agents:

11. **QFG certification**: Run `/qfg certify` — mutation score, property tests, contract tests
12. **SFG scan**: Run `/security-scan` on all changes
13. **Review agent**: Run `/review` on all changes
14. **Test runner**: Run the full test suite and report results

Wait for all to complete before continuing.

## Finalize Phase

15. Fix any Critical/Major review, QFG, or SFG findings
16. **MFG instrumentation check**: Run `/tracking-plan` audit to verify success metric events
    are instrumented before committing.
17. Run `/commit` to verify and commit
18. Run `/compound` to capture learnings
19. **XFG experiment activation**: If the bet includes a success metric hypothesis,
    run `/xfg activate` to configure the experiment.

## Rules

- ONLY use swarm phase when there are 3+ independent scopes
- For small features (1-2 scopes), use `/lfg` instead
- Assign vertical scopes to teammates, not horizontal layers
- Each teammate must own a distinct set of files - no overlapping edits
- Shut down teammates before cleanup
- Stop at approval gates - do NOT auto-approve specs
- Respect the appetite — cut scope before extending time
- Never revisit a documented Rabbit Hole during implementation
