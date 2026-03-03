---
name: sdfg
description: Swarm DFG - parallel autonomous product design using agent teams
argument-hint: [design problem or feature description]
---

# SDFG - Swarm Design Flow, Go

Design this using parallel agent teams: $ARGUMENTS

Run these phases in order. Parallelize where indicated.

## Sequential Phase

1. **Explore first**: Before asking anything, read project docs to understand context:
   - Project CLAUDE.md (conventions, design system, brand guidelines)
   - Existing design specs in dev_docs/specs/
   - Solution docs in dev_docs/solutions/ for reusable patterns
   - Any existing .pen files, Figma references, or design tokens
   - Check Pencil MCP: run `get_editor_state()` and `get_variables`
2. **Jobs-to-be-Done interview**: Ask the user the switching forces questions:
   - Job statement, push/pull/anxiety/habit forces
   - Who are the users, what state of mind?
3. **Set appetite**: Ask the user: "What's the appetite for this?" Record in spec header.
   - Small → use `/dfg` instead. SDFG is for Medium and Large only.
   - Medium: 3-5 screens, all states
   - Large: Full feature, multiple flows, responsive, design system extensions
4. **Constraint mapping**: Platform, output format, design system, accessibility, brand, technical.
5. **SFG security consideration**: If the design touches auth flows, data display, permission UI,
   payment screens, or admin interfaces, flag security implications in the brief (sensitive data
   visibility, trust boundaries in the UI, role-based display logic).
6. Write a **Problem Brief** in `dev_docs/specs/<feature>-design.md` with appetite, JTBD, success metrics, design principles, security considerations (if applicable), rabbit holes, out of scope.
7. Wait for user approval of the problem brief.
7. Run `/design-research` to enhance with parallel research agents (competitive analysis, pattern mining, content model, constraint validation, hill chart).
8. **Hill chart gate**: All scopes must be at Hilltop or Downhill before entering Swarm Phase. Run focused spikes for any Uphill scopes.
9. Wait for user approval of the research synthesis.

## Architecture Phase

10. **Object model** (OOUX): Define objects, attributes, relationships, CTAs.
11. **Breadboard**: Sketch places, affordances, connections. Present to user.
12. **State inventory**: Enumerate ALL states per screen (empty, loading, partial, populated, overflow, error, permission, first-use).
13. **Concept exploration (10→3→1)**: Generate 3 structurally different concepts. Present to user — user selects one or hybrid.
14. **Establish design foundation** (this is shared context for the swarm):
    - Commit to a bold aesthetic direction and visual tone
    - Define typography system (display + body font)
    - Define color system (primary, secondary, accent, surface, text)
    - Define spacing scale and grid
    - Define motion language
    - Set all tokens via `set_variables` or CSS custom properties
    - This foundation MUST be locked before the swarm starts — teammates don't invent their own tokens
15. Wait for user approval of architecture + design foundation.

## Swarm Phase

16. Create an agent team for design:
    - Break the design into **vertical slices** — each slice is one screen/flow + ALL its states
    - Each slice is independently reviewable
    - Spawn teammates per slice, not per concern:
      - **screen-a**: Complete screen A (happy path + all states from inventory)
      - **screen-b**: Complete screen B (happy path + all states from inventory)
      - **screen-c**: Complete screen C (happy path + all states from inventory)
      - **shared**: Design system extensions, shared components, icons, illustrations
    - Each teammate:
      - Receives the design foundation (tokens, typography, color, spacing, motion language)
      - Receives the state inventory for their screen
      - Receives the selected concept wireframe as reference
      - Must run the inner critique loop per screen (screenshot → critique → fix)
      - Owns a distinct canvas area or file — no overlapping edits
    - If using Pencil MCP:
      - Use `find_empty_space_on_canvas` to allocate non-overlapping canvas regions per teammate
      - Each teammate works within their allocated region
      - The `shared` teammate creates reusable components that others reference
    - If using code:
      - Each teammate owns distinct component/page files
      - Shared teammate owns the design system file (tokens, base components)
    - **Appetite check**: After each teammate completes, check if accumulated work is within appetite. If exceeding, stop spawning and ask user.
    - Wait for all teammates to complete

## Review Phase

After design completes:

17. **Critique**: Run `/design-critique` on all screens
18. Fix any Critical or Major critique findings
19. Re-screenshot and verify fixes

## Token Compliance + Visual Baselines Phase

20. **Stylelint token audit** (if project has a `lint:tokens` script):
    - Run `npm run lint:tokens` to check all CSS/Svelte files for raw values, wrong-role tokens, and raw primitives
    - Fix all violations. Rebuild and verify a clean pass.
    - If `lint:tokens` is not available, grep design files for raw `px`/`rem` in spacing, color, font-size,
      border-radius, and border-width properties. Fix all tokenizable values.
21. **Visual regression baselines**: Capture screenshots of the approved post-critique state:
    - Run `/visual-regression` for each key screen at desktop (1440x900), plus mobile/tablet if responsive
    - These baselines lock in the approved state before validation may trigger further fixes

## Validation Phase

22. **Validate**: Run `/design-validate` (accessibility, responsive, compliance, content stress)
23. **MFG analytics verification**: Run `/tracking-plan` in audit mode to verify that analytics
    events are defined for key user interactions. Every button, form, and navigation should
    map to a trackable event.
24. Fix any Critical validation failures (Must Fix items)
25. **Visual regression comparison**: If baselines were captured in the previous phase, re-run
    `/visual-regression` on each baselined screen. SIGNIFICANT changes indicate the
    validation fixes caused unintended regressions — investigate and fix.
26. Present validation report to user. Wait for approval.

## Finalize Phase

27. Re-screenshot and verify consistency across all screens (the swarm may have drifted)
    - Run `search_all_unique_properties` across the full design to find inconsistencies
    - Fix with `replace_all_matching_properties` if systematic
    - Manual fix if one-off
28. Present final prototype to user for approval
29. Run `/design-compound` to capture learnings
30. **XFG experiment consideration**: If the design includes a testable hypothesis,
    run `/xfg hypothesize` to frame the experiment that engineering will implement.

## Rules

- ONLY use swarm phase when there are 3+ screens/flows
- For small features (1-2 screens), use `/dfg` instead
- The design foundation (tokens, typography, color, spacing) MUST be locked before the swarm starts
- Each teammate must own a distinct canvas region or file set — no overlapping edits
- The inner critique loop is mandatory for EVERY teammate, EVERY screen
- State inventory completeness is non-negotiable — every screen gets all applicable states
- Critique MUST complete and fixes applied BEFORE validation runs — validation checks the post-fix state
- After the swarm, run a consistency check — parallel design drifts
- Shut down teammates before cleanup
- Stop at approval gates (after brief, after research, after architecture, after validation, before compound)
- Respect the appetite — cut scope before extending time
- Never revisit a documented Rabbit Hole during design
