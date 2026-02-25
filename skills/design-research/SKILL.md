---
name: design-research
description: Enhance a design brief using parallel research agents before visual design begins
---

# Design Research

Enhance the current design brief by running parallel research. $ARGUMENTS

## Process

1. **Locate the brief**: Find the most recent design brief in:
   - dev_docs/specs/*-design.md
   - dev_docs/specs/ (look for JTBD or design-related specs)
   - Or the file specified in arguments

2. **Launch parallel research agents** (use sub-agents, not agent teams):

   Spawn these simultaneously:

   a. **Competitive scout**: Analyze 3-5 products that solve the same JTBD.
      For each product:
      - If browser automation available: navigate to the product, capture screenshots
        of the key flows that match our JTBD
      - If not: use web search to find UI screenshots, reviews, and teardowns
      - Extract: information architecture pattern, navigation model, visual language,
        interaction patterns, what they do well, what they do poorly
      - Note distinctive design choices that could inspire our approach
      Report: "Competitive insights: [structured comparison table + key takeaways]"

   b. **Pattern miner**: Search the existing codebase and design artifacts for
      reusable patterns:
      - Search for existing .pen files: `glob **/*.pen`
      - If Pencil MCP available: `batch_get` with patterns to discover existing
        components, styles, tokens
      - If Figma MCP available: query component inventory and design tokens
      - Search codebase for existing UI components, CSS/Tailwind classes, design tokens
      - Search for existing style definitions (CSS variables, theme files, token files)
      - Check for design system documentation or component libraries (Storybook, etc.)
      Report: "Existing patterns: [list with file references, token values, component names]"

   c. **Content modeler**: Determine what real content will populate the design:
      - What data objects appear on each screen? (from the JTBD and breadboard)
      - For each data field: realistic character count ranges (min, typical, max)
      - What are the edge cases? (empty arrays, null fields, very long strings,
        special characters, RTL text if relevant)
      - What's the realistic data volume? (5 items? 50? 5000?)
      - Are there images/media? What aspect ratios, sizes, and fallbacks?
      - What content needs to be written? (labels, help text, empty states, errors)
      Report: "Content model: [structured data dictionary with realistic sample data]"

   d. **Constraint validator**: Verify feasibility and identify limitations:
      - Platform constraints: what's possible on target platform(s)?
      - Performance implications of design choices (custom fonts, animations,
        large images, complex layouts)
      - Accessibility requirements: WCAG level target, screen reader support,
        keyboard navigation patterns needed
      - Technical constraints from the codebase (available component libraries,
        CSS framework, rendering approach)
      - If relevant: API constraints that affect what data is available
      Report: "Constraints: [list with severity and design implications]"

3. **Synthesize findings**: Merge all agent reports into the design brief:

   - Add a "## Competitive Landscape" section with comparison table and key insights
   - Add a "## Existing Patterns to Reuse" section (tokens, components, visual language)
   - Add a "## Content Model" section with data dictionary and sample data
   - Add a "## Constraints & Feasibility" section
   - Add a "## Design Inspiration" section — specific visual or interaction ideas
     inspired by research (not generic "use cards" — specific like "Linear's
     keyboard-first issue list with inline editing")
   - Add a "## Hill Chart" section:
     ```
     | Scope | Position | Why |
     |-------|----------|-----|
     ```
     Classify each scope as:
     - **Uphill** — IA unclear, no good reference pattern found → needs exploration before design
     - **Hilltop** — structure clear, good references exist, ready for visual design
     - **Downhill** — existing component/pattern covers this, just apply it
   - Flag any scope still "Uphill" as a risk
   - Update the design principles if research reveals new considerations

4. **Present the enriched brief** to the user for approval before proceeding.

## Rules

- Do NOT create visual designs during this phase — this is research only
- Do NOT create new design files except updating the brief itself and saving reference materials
- If competitive analysis reveals that our JTBD framing is wrong, flag it prominently — better to reframe now than design the wrong thing
- If existing patterns cover >50% of a planned design, recommend extending them rather than designing from scratch
- Every scope must reach at least Hilltop before visual design begins
- Save reference screenshots in `dev_docs/specs/<feature>-research/` if captured
- Include real sample data in the content model — "Lorem ipsum" in a design is a lie about the design's quality
