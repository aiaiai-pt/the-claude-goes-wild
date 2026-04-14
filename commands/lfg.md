---
name: lfg
description: Full autonomous engineering workflow - from idea to committed, tested code
argument-hint: [feature description]
---

# LFG - Autonomous Feature Pipeline

Build this feature end-to-end: $ARGUMENTS

Run these phases in order. Do NOT skip phases.

## Phase 1: Explore + Shape

1. **Explore first**: Before asking anything, read project docs to understand context:
   - Project CLAUDE.md (conventions, architecture, key patterns)
   - Recent sprint plans in dev_docs/sprint_*/planning/
   - Existing specs in dev_docs/specs/ that relate to this feature
   - Solution docs in dev_docs/solutions/ for reusable patterns
   - Relevant source files to understand what already exists
2. Create a feature branch: `git checkout -b feat/<short-name>`
3. **Breadboard first**: Before writing a full spec, sketch the flow:
   - List the key places (screens, endpoints, workflow steps)
   - List affordances at each place (what the user/system can do)
   - Draw connection lines (what leads where)
   - Present this to the user for feedback before expanding
4. **Set appetite**: NOW ask the user: "What's the appetite for this?" — they can gauge it because you've presented what exists and what's needed. Record their answer in the spec header. This is the ceiling — when scope threatens to exceed it, cut rather than extend.
5. Write a spec in `dev_docs/specs/<feature-name>.md` with:
   - `**Appetite:** [Small | Medium | Large]` in the header
   - Requirements and success criteria
   - Edge cases
   - Affected components (backend services, frontend, database)
   - **Rabbit Holes** — decisions already made, with rationale. Do NOT revisit these during implementation.
   - **Out of Scope** — future work, unrelated to this feature.
6. Present the spec to the user. Wait for approval before continuing.

## Phase 2: Deepen

7. Run `/deepen-plan` to enhance the spec with:
   - Existing patterns to reuse
   - Dependency verification
   - Risk assessment with rabbit hole identification
   - Test plan (three-tier: CI, Eval, Contract)
   - Hill chart assessment per scope
8. **SFG threat model** (parallel with deepen): If the bet touches auth, data, payments, API keys,
   file uploads, or admin interfaces, run `/threat-model` against the spec. Append the threat
   model to the spec as a Security section. High/Critical threats become rabbit holes.
9. **Hill chart gate**: Review the hill chart. If any scope is still "Uphill" (we don't know HOW), run a focused research spike to bring it to "Hilltop" before proceeding. Spikes produce artifacts: test files, bug fixes, decision docs in `dev_docs/sprint_*/planning/SPIKE_*.md`. Update the plan with findings — spikes often change the approach or surface new rabbit holes.
10. Present the deepened plan. Wait for approval before continuing.

## Phase 3: Implement (Parallel where possible)

11. Write failing tests that encode the spec's success criteria
12. Implement the feature using Red-Green-Refactor:
    - Smallest change to make each test pass
    - Refactor after green - do NOT skip this
13. **QFG alongside implementation**: Run `/mutation-test` on changed code as each scope completes.
    Don't wait until the end — test quality is a build-time concern. Mutation testing proves tests
    catch real bugs (not just exercise code). Target: 80% mutation score per scope. Key fault classes
    to mutate: auth/tenant guards, error classification branches, opt-in/feature flag checks,
    return value handling. If a mutant survives, write a killing test before moving to the next scope.
14. **SFG scans every commit**: Run `/security-scan` after each significant commit.
    Secrets or Critical SAST findings block progress immediately.
15. For multi-component work, use agent teams:
    - Assign **vertical scopes** (feature slices end-to-end), not horizontal layers
    - Each scope includes its own activity + workflow + tests
    - Each teammate owns separate files to avoid conflicts
    - Use shared task list for coordination
16. Run the full test suite to verify nothing is broken
17. **Circuit breaker**: If you've attempted the same fix 2+ times without progress, or scope has grown beyond the stated appetite, STOP and present a choice:
    - (a) Cut scope to fit appetite
    - (b) Extend appetite with justification
    - (c) Pause and revisit later

## Phase 4: Review

18. **QFG quality certification**: Run `/qfg certify` — mutation score must meet target
    (set at BET, default 80%). Contract tests must pass. Quality certification is a hard gate.
19. Run `/review` to perform a fresh-context code review
20. Fix any Critical or Major findings
21. Run tests again after fixes

## Phase 5: Commit

22. **MFG instrumentation check**: Verify that the bet's success metrics are instrumented.
    Run `/tracking-plan` in audit mode against the new code. If success metric events are
    missing, add them before committing — you can't measure impact without tracking.
23. Run `/commit` to verify and commit with component discovery

## Phase 6: Compound

24. Run `/compound` to capture learnings for future work
25. **XFG experiment activation**: If the bet includes a success metric hypothesis,
    run `/xfg activate` to start the experiment. Configure the feature flag for
    experiment traffic allocation.

## Rules

- Stop and ask the user at approval gates (after spec, after deepened plan)
- Use agent teams ONLY when components are truly independent (different files)
- Assign vertical scopes to teammates, not horizontal layers
- If tests fail after Phase 3, fix before moving to Phase 4
- If review finds Critical issues, fix before committing
- The feature is NOT done until tests pass and review is clean
- Respect the appetite — cut scope before extending time
- Never revisit a documented Rabbit Hole during implementation
