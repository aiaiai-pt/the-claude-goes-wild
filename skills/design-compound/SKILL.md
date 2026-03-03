---
name: design-compound
description: Capture design learnings, tokens, components, and patterns from completed design work
---

# Design Compound

After completing a design, capture learnings that make future design work easier and more consistent.
$ARGUMENTS

## Process

1. **Gather what just happened**:
   - Read the design brief from dev_docs/specs/*-design.md
   - If Pencil MCP: `get_editor_state()` to identify the design file
   - If code-based: identify the prototype files
   - Review any design critique and validation reports
   - Read git log to see what design files were created/modified

2. **Extract design tokens and formalize them**:

   a. **If Pencil MCP**:
      - Run `get_variables` to capture the current token state
      - Run `search_all_unique_properties` to find any values used but not tokenized
      - For any un-tokenized values that recur 3+ times: create new tokens via `set_variables`
      - Document the complete token set

   b. **If code-based**:
      - Extract all CSS custom properties / Tailwind config values
      - Find hardcoded recurring values and suggest tokenization
      - Document the complete token set

   c. **Write token documentation** in `dev_docs/solutions/design-tokens.md` (create or update):
      ```
      ## Design Tokens
      Last updated: [date]

      ### Color
      | Token | Value | Usage |
      |-------|-------|-------|

      ### Typography
      | Token | Value | Usage |
      |-------|-------|-------|

      ### Spacing
      | Token | Value | Usage |
      |-------|-------|-------|

      ### Other (radius, shadow, motion)
      | Token | Value | Usage |
      |-------|-------|-------|
      ```

3. **Catalog reusable components**:

   a. **If Pencil MCP**:
      - Run `batch_get` to inventory existing components (search by type or name patterns)
      - For components used in this design that SHOULD be reusable but aren't,
        check if Pencil supports a reusable flag — if so, mark them via `batch_design`
        with the appropriate property. If not, document them manually.
      - Document each reusable component: name, purpose, variants, states

   b. **If code-based**:
      - Identify components that could be extracted into a shared library
      - Document: component name, props/API, usage context, states

   c. **Write component catalog** in `dev_docs/solutions/design-components.md` (create or update):
      - For each component: name, purpose, when to use, states, variants
      - Include reference to where it lives (node ID in .pen, file path in code)

4. **Extract design patterns**:

   Learnings about HOW to design well for this project:

   a. **What patterns were established?**
      - Layout patterns (grid systems, panel layouts, responsive breakpoints)
      - Navigation patterns (sidebar, top nav, command palette, tabs)
      - Interaction patterns (inline editing, modals, drawers, toasts)
      - Content patterns (empty states, error messages, loading approaches)
      - Motion patterns (duration range, easing, choreography)

   b. **What was harder than expected and why?**
      - Which screens required the most critique-loop iterations?
      - Which states were hardest to design well?
      - What constraints were discovered during design that weren't in the brief?

   c. **What worked well?**
      - Which design choices got the strongest positive response?
      - Which patterns from competitive research proved most useful?
      - What distinctive choices defined this design's character?

   d. **What mistakes were made?**
      - AI-slop patterns that crept in and had to be fixed
      - Token/consistency issues that should have been caught earlier
      - States that were forgotten until validation
      - Aesthetic directions that didn't work and why

5. **Update institutional memory**:

   a. **Project CLAUDE.md**: If a design learning applies broadly to the project,
      add it as a concise rule in a `## Design Conventions` section:
      - Design system references (font families, color palette name, spacing base)
      - Component patterns to follow
      - Anti-patterns to avoid
      Keep it short — only add what prevents mistakes.

   b. **dev_docs/solutions/**: Create or update solution docs for reusable design patterns:
      ```
      dev_docs/solutions/design-<pattern-name>.md
      ```
      Include: the pattern, when to use it, visual reference (screenshot path or description),
      token values, component references.

   c. **dev_docs/specs/**: Update the design spec to reflect what was actually built.
      Note any deviations from the original brief and why.

   d. **Auto memory**: Update the project-specific memory file at
      `~/.claude/projects/<project-key>/memory/MEMORY.md` with key design insights.
      To find the project key, check the current working directory — the project
      key is the absolute path with `/` replaced by `-` (e.g., `/Users/jdoe/my-app`
      becomes `-Users-jdoe-my-app`). If the memory directory doesn't exist,
      create it.

   e. **Design-spec-architect agent memory** (for standalone design-spec-architect use):
      If there are learnings about design process, visual language, or component
      patterns that would help when the design-spec-architect agent is used outside
      of DFG workflows (e.g., for quick design specs), update
      `~/.claude/agent-memory/design-spec-architect/MEMORY.md`.
      Only write general design learnings here, not project-specific details.

6. **Report what was captured**:
   - List each learning and where it was stored
   - Highlight token additions/changes
   - Note new reusable components
   - List patterns added to solutions/
   - Note CLAUDE.md additions

## Rules

- Keep CLAUDE.md additions to 1-2 lines each — only add what prevents mistakes
- Token documentation should be copy-pasteable for developers
- Don't document obvious things — focus on what surprised you or caused iteration
- If a previous design learning is now outdated, update or remove it
- Component catalogs should reference actual node IDs or file paths, not abstract descriptions
- If the design established a new visual language or significantly extended the design system,
  write a dedicated solution doc (not just a CLAUDE.md one-liner)
- Capture the "distinctive choices" explicitly — these define the product's visual identity
  and should be consistent across future designs
