---
name: design-critique
description: Multi-altitude structured design review using a fresh-context perspective
---

# Design Critique

Review the current design using a fresh perspective at multiple altitudes. $ARGUMENTS

## Process

1. **Gather context**: Locate the design to review:
   - If Pencil MCP: run `get_editor_state()`, then `get_screenshot` of each major screen
   - If code-based: identify the prototype files, render and capture screenshots
   - Read the design brief in dev_docs/specs/*-design.md for the JTBD, design principles,
     and success metrics
   - Read the state inventory to know what states should exist

2. **Launch a fresh-context design-critic agent** (use the design-critic agent):

   The critic has NOT seen the design process. They review only the artifacts.
   Pass them:
   - The screenshots of each screen
   - The design brief (JTBD, design principles, success metrics)
   - The state inventory
   - The design tokens / style foundation

3. **The critic reviews at three altitudes**:

   ### Strategic Altitude
   - Does this design solve the stated JTBD? Would a user "hire" this?
   - Does it respect the design principles from the brief?
   - Is the information architecture intuitive? Would a new user understand
     where things are and how to navigate?
   - Does the design support the success metrics?
   - Is there a clear content hierarchy? Can you identify what's most important?

   ### Structural Altitude
   - Is the state inventory complete? Are all states designed?
   - Are flows logical? Can users always go back / undo / escape?
   - Is progressive disclosure appropriate? (too much upfront? too hidden?)
   - Is the object model clear? Do users understand what they're looking at?
   - Are interaction patterns consistent across screens?
   - Are error states helpful? (what happened + why + what to do)
   - Are empty states useful? (not just "No data" — guidance, CTA)

   ### Craft Altitude
   - Typography: Is the type scale consistent? Are sizes justified by hierarchy?
     Is line height appropriate for each size? Is measure (line length) readable?
   - Color: Is usage purposeful (not decorative)? Does it support hierarchy?
     Are there contrast issues? Is the palette cohesive?
   - Spacing: On-grid? Consistent rhythm? Proper use of whitespace for grouping?
   - Layout: Does the composition guide the eye? Is there visual balance?
     Does the squint test pass (structure visible when blurred)?
   - Components: Are similar elements rendered consistently?
     Are interactive elements obviously interactive (affordance)?
   - Motion (if specified): Is it purposeful? Duration appropriate?
     Does it aid understanding or just decorate?

   ### Anti-"AI Slop" Check
   - Does this look like it could be ANY product, or does it feel specific to THIS product?
   - Are there at least 2 distinctive design choices that someone would notice?
   - Does it avoid the convergent-AI aesthetic? (generic fonts, purple gradients,
     card soup, decoration over function, hierarchy collapse)
   - Would a designer screenshot this for inspiration?
   - Is there a clear visual point of view, or does it feel like "default settings"?

4. **Produce a structured report**:

```
## Critique Summary
**Screens reviewed**: N
**Severity**: Clean | Minor | Major | Critical

## Strategic Findings
### [Critical/Major/Minor] Finding title
- **Screen**: name or reference
- **Issue**: What's wrong from a product design perspective
- **Fix**: Specific recommendation

## Structural Findings
### [Critical/Major/Minor] Finding title
- **Screen/State**: name and state
- **Issue**: What's missing or broken in the flow/states
- **Fix**: Specific recommendation

## Craft Findings
### [Critical/Major/Minor] Finding title
- **Screen**: name or reference
- **Element**: specific element or region
- **Issue**: What's wrong visually or interactionally
- **Fix**: Specific recommendation (with token names, sizes, or spacing values)

## Anti-Slop Assessment
- **Distinctiveness score**: [1-5] (1 = generic, 5 = would be shared as inspiration)
- **Distinctive choices identified**: [list]
- **Generic patterns to replace**: [list with specific alternatives]

## Missing States
- [ ] List of states from inventory that are not designed or are insufficient

## Overall Assessment
One paragraph: is this design ready for validation?
```

## Severity Definitions

- **Critical**: Design fails its JTBD — users would not understand what to do, or cannot
  accomplish their goal. Missing critical states (error with no recovery). Accessibility
  blocker (text unreadable, no keyboard path).
- **Major**: Design works but has significant gaps — missing states that real users would
  encounter, inconsistent patterns that would confuse, hierarchy issues that bury
  important information, generic aesthetic that undermines product identity.
- **Minor**: Polish issues — spacing inconsistencies, minor typography adjustments,
  color refinements, motion timing. Things that separate "good" from "excellent."

## Rules

- Be specific — reference screens and elements, not vague concerns
- Distinguish between must-fix (Critical/Major) and polish (Minor)
- Don't flag subjective aesthetic preferences unless they relate to distinctiveness or usability
- Always check completeness against the state inventory — this is where most designs fail
- If the design is genuinely excellent, say so. Don't manufacture findings.
- Focus on what users would experience, not what designers would debate
