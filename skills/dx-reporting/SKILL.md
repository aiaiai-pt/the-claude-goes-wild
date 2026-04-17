---
name: dx-reporting
description: >
  Generates Developer Experience reports for senior architects and CTO.
  Produces architecture briefs, cycle readiness reports, and process summaries.
  Use after architecture work to communicate decisions and risks to leadership.
---

# DX Reporting Skill

## When to Use
- After completing `/architect` or `/shape` — generate Architecture Brief
- Before a build cycle — generate Cycle Readiness report
- After shipping — generate Process Summary
- Standalone DX audit of existing architecture

## Process

1. Read all artifacts from `docs/architect-process/`
2. Determine report type (brief | readiness | summary)
3. Load `references/report-templates.md` for templates
4. If a platform profile is active, load its `platform-stack` skill to check
   stack alignment (what's canonical vs what's a deviation)
5. Generate report with emphasis on:
   - **Decisions** (what was decided and why)
   - **Risks** (what could go wrong)
   - **Stack alignment** (how well this fits the canonical stack)
   - **Dependencies** (what blocks what)
   - **Open questions** (what needs leadership input)
6. Save to `docs/architect-process/dx-reports/`

## Report Principles

### Lead with the Conclusion
Every report starts with the most important information. Busy leaders read the first paragraph and the tables. Structure accordingly.

### Quantify Where Possible
- "5 modules, 23 features (18 must-have, 5 nice-to-have)"
- "3 ADRs deviate from standard stack"
- "Critical path: M-01 → M-03 → M-05 (estimated 4 weeks)"

### Flag Deviations Prominently
Any deviation from the active platform profile's standard stack gets a ⚠ marker
in the Stack Alignment table.

### Keep It Under 2 Pages
If a report exceeds 2 pages of content (excluding diagrams), it's too long. Move details to appendices or link to the full specs.

## Gotchas
- Don't duplicate the full architecture doc — summarize and link
- Risk register should be honest — don't bury bad news
- Open questions should have proposed answers or options, not just questions
- Include a "recommended next steps" section with owners and deadlines
