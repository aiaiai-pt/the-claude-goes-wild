---
name: dfg
description: Full autonomous product design workflow - from problem to high-fidelity prototype
argument-hint: [design problem or feature description]
---

# DFG - Design Flow, Go

Design this end-to-end: $ARGUMENTS

Run these phases in order. Do NOT skip phases.

## Phase 1: Frame

**Goal**: Define the problem with enough precision that the design is constrained.

1. **Explore first**: Before asking anything, read project docs to understand context:
   - Project CLAUDE.md (conventions, design system, brand guidelines)
   - Existing design specs in dev_docs/specs/ that relate to this feature
   - Solution docs in dev_docs/solutions/ for reusable patterns
   - Any existing .pen files, Figma references, or design tokens in the project
   - Check Pencil MCP: run `get_editor_state()` to see if there's an active design context
   - If Pencil MCP available: run `get_variables` to discover existing design tokens
2. **Jobs-to-be-Done interview**: Ask the user these questions (adapt to context — skip what's obvious):
   - What job is the user hiring this design to do?
   - What's the current solution? What's pushing them away from it? (Push force)
   - What would attract them to the new solution? (Pull force)
   - What anxieties would prevent adoption? (Anxiety force)
   - What habits keep them stuck on the current approach? (Habit force)
   - Who are the users and what state of mind are they in when they use this?
3. **Set appetite**: Ask the user: "What's the appetite for this?" — they can gauge it because you've presented what exists and what's needed.
   - **Small**: 1 screen or single interaction flow, 1-3 states
   - **Medium**: 3-5 screens or a multi-step flow, all states
   - **Large**: Full feature with multiple flows, all states, responsive, design system extensions
   Record their answer in the spec header. This is the ceiling.
4. **Constraint mapping**: Establish and record:
   - Platform: web / iOS / Android / responsive web / all
   - Output format: .pen file (Pencil) / HTML+CSS prototype / Figma spec / all
   - Existing design system: tokens, components, visual language to follow or extend
   - Accessibility level: WCAG AA (default) or AAA
   - Brand constraints: colors, fonts, tone, personality
   - Technical constraints: framework, performance budget, browser support
5. **SFG security consideration**: If the design touches auth flows, data display, permission UI,
   payment screens, or admin interfaces, flag security implications early. Note in the brief:
   which screens handle sensitive data, where trust boundaries exist in the UI, what the
   user should/shouldn't be able to see based on role.
6. Write a **Problem Brief** in `dev_docs/specs/<feature>-design.md` with:
   - `**Appetite:** [Small | Medium | Large]` in the header
   - `**Platform:** [web | iOS | Android | responsive | all]`
   - `**Output:** [.pen | HTML+CSS | Figma spec]`
   - Jobs-to-be-Done summary (job statement, forces diagram)
   - Success metrics: both user-outcome metrics and business metrics
   - Design principles for this project (3-5, derived from the JTBD — e.g., "Progressive complexity: power features exist but don't clutter the default view")
   - Security considerations (if applicable — auth states, data visibility, permissions)
   - **Rabbit Holes** — decisions already made, with rationale. Do NOT revisit these during design.
   - **Out of Scope** — future work, explicitly deferred.
7. Present the problem brief to the user. Wait for approval before continuing.

## Phase 2: Discover

7. Run `/design-research` to enhance the brief with:
   - Competitive analysis (visual + interaction patterns from 3-5 reference products)
   - Existing design patterns to reuse (from codebase, design system, .pen files)
   - Content model (real data shapes, character counts, edge cases)
   - Constraint validation (technical feasibility, platform requirements)
   - Hill chart assessment per scope
8. **Hill chart gate**: Review the hill chart. If any scope is still "Uphill" (we don't know HOW to design it), run a focused research spike to bring it to "Hilltop" before proceeding. Spikes produce artifacts: moodboards, interaction sketches, reference screenshots in `dev_docs/specs/<feature>-research/`.
9. Present the research synthesis. Wait for approval before continuing.

## Phase 3: Architect

**Goal**: Nail information architecture and interaction model before pixels.

10. **Object model** (OOUX): Define the objects users interact with:
    - For each object: name, core attributes, relationships to other objects, primary CTA
    - Example: "Issue → title, status, assignee, priority | belongs to Project | CTA: change status"
11. **Breadboard**: Sketch the flow as text:
    - **Places**: Each screen or view (name + purpose)
    - **Affordances**: What the user can do at each place
    - **Connections**: What leads where (arrows between places)
    - Present to user for feedback
12. **State inventory**: For the selected concept, enumerate ALL states per screen:
    - Empty (first use, no data yet)
    - Loading (skeleton, progressive, or spinner)
    - Partial (some data, onboarding not complete)
    - Populated (normal use, happy path)
    - Overflow (too much data — 1000 items, long names, deep nesting)
    - Error (failed load, failed action, offline, timeout)
    - Permission (unauthorized, read-only, upgrade required)
    - First-use (onboarding, guided tour, contextual hints)
    This is NOT optional. Every screen gets a state inventory.
13. **Concept exploration (10→3→1)**:
    - Generate **3 meaningfully different concepts** — not color variations, but structurally different approaches:
      - Different IA (sidebar nav vs. top nav vs. command palette)
      - Different interaction models (direct manipulation vs. form-based vs. conversational)
      - Different emphasis (data-dense dashboard vs. focused single-task vs. progressive disclosure)
    - Each concept should be a wireframe-level sketch:
      - If Pencil MCP available: create 3 wireframe frames on the canvas using `batch_design`
      - If code-based: create 3 HTML wireframes with distinct layout structures
      - If text-based: detailed ASCII/markdown layout descriptions
    - For each concept, explain: what it optimizes for, what it sacrifices, which design principles it embodies
    - Present all 3 to user — user selects one or describes a hybrid
14. **Hill chart update**: Classify each scope:
    - **Uphill** — IA unclear, interaction model uncertain → needs spike
    - **Hilltop** — structure clear, visual design needed → ready for Phase 4
    - **Downhill** — existing pattern, just apply it → straightforward
    ALL scopes must be Hilltop or Downhill before proceeding.
15. Present the architecture (object model + breadboard + selected concept + state inventory + hill chart). Wait for approval before continuing.

## Phase 4: Design (Inner Loop)

**Goal**: High-fidelity prototype with all states.

16. **Setup the design environment**:
    - If Pencil MCP: open or create .pen file via `open_document`
    - Fetch style direction: `get_style_guide_tags` → select relevant tags → `get_style_guide`
    - Fetch design guidelines: `get_guidelines` for relevant topics (landing-page, table, tailwind, etc.)
    - Set up design tokens via `set_variables` (from existing system or create new)
    - Find canvas space via `find_empty_space_on_canvas`
    - If code-based: set up project structure, install fonts, define CSS custom properties

17. **Commit to a bold aesthetic direction** before designing any screen:
    - Review the design principles from Phase 1
    - Choose a visual tone — not "modern and clean" (that's nothing), but specific:
      Brutally minimal | Maximalist/dense | Retro-futuristic | Organic/natural |
      Luxury/refined | Playful/toy-like | Editorial/magazine | Brutalist/raw |
      Art deco/geometric | Soft/pastel | Industrial/utilitarian | Swiss/typographic
    - Define the typography system: display font + body font (NEVER Inter, Roboto, Arial, system fonts)
    - Define the color system: primary, secondary, accent, surface, text hierarchy
    - Define the spacing scale: base unit (4px or 8px), named steps (xs through 3xl)
    - Define the motion language: duration range, easing curves, choreography principles
    - Record all of this in the design tokens

18. **Design each screen using the inner critique loop**:

    For each screen in the breadboard, in dependency order:

    ```
    INNER LOOP (max 5 iterations per screen):
    ┌──────────────────────────────────────────┐
    │  a. DESIGN: Create/update the screen     │
    │     - batch_design operations (Pencil)   │
    │     - or write HTML/CSS/JSX (code)       │
    │                                          │
    │  b. SEE: Capture what you built          │
    │     - get_screenshot (Pencil)            │
    │     - or render in browser + screenshot  │
    │                                          │
    │  c. CRITIQUE: Evaluate against checklist │
    │     □ 5-second test: primary action      │
    │       obvious?                           │
    │     □ Hierarchy: 1st/2nd/3rd priority    │
    │       content distinguishable?           │
    │     □ Squint test: layout structure      │
    │       holds when blurred?                │
    │     □ Typography: using scale, not       │
    │       arbitrary sizes?                   │
    │     □ Spacing: on the grid?              │
    │     □ Color: using tokens, not hardcoded?│
    │     □ Raw values: zero hardcoded px/rem │
    │       in spacing, borders, font-size?   │
    │     □ Contrast: text readable?           │
    │     □ Distinctiveness: would someone     │
    │       screenshot this for inspiration?   │
    │     □ Brand fit: feels specific to THIS  │
    │       product, not "generic SaaS"?       │
    │                                          │
    │  d. FIX: Address critique findings       │
    │                                          │
    │  e. VERIFY: Screenshot again             │
    │     - All items pass? → next screen      │
    │     - Items fail? → back to (c)          │
    │     - 5 iterations, no progress?         │
    │       → STOP, ask user for direction     │
    └──────────────────────────────────────────┘
    ```

19. **Design all states** for each screen:
    - Don't just design the happy path — design from the state inventory (Phase 3, step 12)
    - Empty states: NOT just "No data yet." — include illustration/icon, explanation, primary CTA
    - Error states: What happened + why + what to do next + recovery action
    - Loading states: Skeleton screens that match the populated layout structure
    - Overflow states: What happens with 1000 items? A 200-character name?
    - Each state goes through the inner critique loop (abbreviated — 2-3 iterations max)

20. **Circuit breaker**: If design work has expanded beyond the stated appetite:
    - (a) Cut states — design only the critical path states, document the rest as spec
    - (b) Extend appetite with justification
    - (c) Pause and ship what's done as a design direction for user feedback

## Phase 5: Critique

21. Run `/design-critique` to perform a fresh-context design review
22. Fix any Critical or Major findings
23. Re-screenshot and verify fixes

## Phase 5.5: Token Compliance Sweep + Visual Baselines

After critique fixes land, run automated compliance and capture visual baselines before validation:

23b. **Stylelint token audit** (if project has a `lint:tokens` script):
    - Run `npm run lint:tokens` to check all CSS/Svelte files for:
      - Raw values where tokens exist (spacing, color, font-size, border-radius, border-width)
      - Wrong-role token usage (e.g., a spacing token used in a color property)
      - Raw `--raw-*` primitive tokens in consuming projects (configurable via `allowRawTokens`)
    - Fix all violations. Rebuild and verify a clean pass.
    - If `lint:tokens` is not available, fall back to a manual grep sweep:
      - Grep design files for raw `px`/`rem` in `gap`, `padding`, `margin`, `border`,
        `border-width`, `font-size`, `border-radius`, `outline`, `outline-offset`,
        `text-underline-offset`, and `height`/`width` when used as spacing
      - Classify each as MUST TOKENIZE / NEEDS NEW TOKEN / ACCEPTABLE
      - Fix all MUST TOKENIZE items. Create tokens for NEEDS NEW TOKEN items.
    - **The goal is zero raw px/rem values in spacing, borders, font-size, and border-radius.**
      Icon/element dimensions and layout constraints are acceptable raw values.

23c. **Visual regression baselines**: Capture screenshots of the approved post-critique state:
    - Run `/visual-regression` for each key screen at desktop viewport (1440x900)
    - Add mobile (375x812) and tablet (768x1024) if the design is responsive
    - These baselines lock in the approved state before validation may trigger further fixes
    - If baselines already exist from a previous iteration, compare first — a SIGNIFICANT diff
      means the critique fixes caused regressions elsewhere that need attention

23d. Rebuild and verify.

## Phase 6: Validate

24. Run `/design-validate` to perform automated validation:
    - Accessibility audit (contrast ratios, touch targets, semantic structure)
    - Responsive validation (if applicable — screenshots at key breakpoints)
    - Design system compliance (stylelint + raw value sweep, off-system values, inconsistent tokens)
    - Content stress test (extreme data in all screens)
25. **MFG analytics verification**: Run `/tracking-plan` in audit mode to verify that analytics
    events are defined for key user interactions in the design. Every button, form submission,
    and navigation should map to a trackable event. Flag gaps before handoff to engineering.
26. Fix validation failures.
27. **Visual regression comparison**: If baselines were captured in Phase 5.5, re-run
    `/visual-regression` on each baselined screen. SIGNIFICANT changes indicate the
    validation fixes caused unintended regressions — investigate and fix before approval.
28. Present validation results to user. Wait for approval.

## Phase 7: Compound

29. Run `/design-compound` to capture design learnings
30. **XFG experiment consideration**: If the design includes a testable hypothesis (e.g.,
    "this new layout will increase conversion"), run `/xfg hypothesize` to frame the
    experiment design that engineering will implement with feature flags.

## Rules

- Stop and ask the user at approval gates (after brief, after research, after architecture, after validation)
- The inner critique loop is MANDATORY — never ship a first draft. Screenshots are how you see your work.
- Design ALL states, not just the happy path. State inventory completeness is a hard requirement.
- Use design tokens for EVERYTHING — no hardcoded colors, font sizes, spacing, borders, or border-radius values. Run a raw px/rem sweep (Phase 5.5) before validation to catch any that slipped through.
- NEVER use generic fonts (Inter, Roboto, Arial, system fonts) unless the existing design system mandates them
- NEVER produce "AI slop" — every design choice should be intentional and specific to this product
- Respect the appetite — cut scope before extending time
- Never revisit a documented Rabbit Hole during design
- If the project has an existing design system, follow it and extend it — don't invent a parallel system
- If Pencil MCP is not available, produce HTML+CSS prototypes using the frontend-design skill's guidelines
- The prototype is NOT done until the critique is clean and validation passes
