---
name: design-validate
description: Automated design validation - accessibility, responsiveness, compliance, content stress
---

# Design Validate

Run automated validation checks on the current design. $ARGUMENTS

## Process

1. **Identify the design artifacts**:
   - If Pencil MCP: `get_editor_state()` to identify active .pen file
   - If code-based: identify HTML/CSS/JSX prototype files
   - Read the design brief for target accessibility level, platform, design tokens

2. **Run validation checks in parallel** (spawn as sub-agents where beneficial):

   ### A. Accessibility Audit

   **If Pencil MCP** (.pen file):
   - Run `search_all_unique_properties` on the root for `fillColor`, `textColor` pairs
   - For each text-on-background combination, calculate contrast ratio:
     - WCAG AA: 4.5:1 for normal text (<18px or <14px bold), 3:1 for large text
     - WCAG AAA: 7:1 for normal text, 4.5:1 for large text
   - Check font sizes: minimum 14px for body text, 12px absolute minimum
   - Check touch/click targets: minimum 44x44px for interactive elements
     (use `snapshot_layout` to get element dimensions)
   - Verify color is not the ONLY way to convey information (check for icons,
     labels, patterns alongside color indicators)

   **If code-based** (HTML/CSS):
   - Render the prototype in a headless browser
   - Run axe-core programmatically if available, or check manually:
     - Semantic HTML structure (headings hierarchy, landmark regions, button vs div)
     - Alt text on images
     - Form labels and associations
     - Focus order and visible focus indicators
     - ARIA attributes where needed
     - Color contrast ratios
   - Check keyboard navigability: can every interactive element be reached with Tab?
   - Check that hover-only interactions have keyboard equivalents

   **Report format**:
   ```
   ## Accessibility Results
   **Target**: WCAG [AA|AAA]
   **Pass/Fail**: [count] pass, [count] fail, [count] warning

   ### Failures
   - [Screen/Element]: [Issue] — [WCAG criterion] — [Fix suggestion]

   ### Warnings
   - [Screen/Element]: [Issue] — [Recommendation]
   ```

   ### B. Responsive Validation

   **Only if platform includes web or responsive:**

   **If Pencil MCP**: Check if responsive variants exist on the canvas.
   If not, flag as a gap. If yes, screenshot each variant.

   **If code-based**:
   - Render at standard breakpoints: 320px, 768px, 1024px, 1440px
   - Screenshot each breakpoint
   - Check for:
     - Horizontal overflow (content wider than viewport)
     - Text truncation without ellipsis or expansion mechanism
     - Touch targets too small at mobile sizes (<44px)
     - Content reflow that breaks reading order
     - Images that don't scale or maintain aspect ratio
     - Navigation that doesn't adapt (desktop nav on mobile)

   **Report format**:
   ```
   ## Responsive Results
   **Breakpoints tested**: [list]

   ### Issues
   - [Breakpoint] [Screen]: [Issue] — [Fix suggestion]

   ### Screenshots
   [Reference to captured screenshots]
   ```

   ### C. Design System Compliance

   **If Pencil MCP**:
   - Run `get_variables` to get the canonical token set
   - Run `search_all_unique_properties` for all of:
     `fillColor`, `textColor`, `fontSize`, `fontFamily`, `fontWeight`,
     `gap`, `padding`, `cornerRadius`, `strokeColor`
   - Compare actual values against token set
   - Flag any hardcoded values that should be tokens
   - Flag any values that are close-but-not-matching tokens (e.g., #3B82F5 when
     the token is #3B82F6 — likely a typo)
   - Check for unused tokens (defined but never used)
   - Check for orphan fonts (fonts used but not in the type system)

   **If code-based**:
   - **Stylelint token audit** (primary — if a `lint:tokens` script exists):
     Run `npm run lint:tokens` to check all CSS/Svelte files for raw values where tokens
     exist, wrong-role token usage (e.g., spacing token in a color property), and raw
     `--raw-*` primitive token leakage. Report any violations as compliance failures.
   - **Raw value sweep** (fallback if no `lint:tokens`, or supplement):
     Grep ALL design files for raw `px` and `rem` values in CSS properties: `gap`, `padding`,
     `margin`, `border`, `border-width`, `font-size`, `border-radius`, `outline`,
     `outline-offset`, `text-underline-offset`, and `height`/`width` when used as spacing.
     Classify each as:
     - **MUST TOKENIZE**: has a direct token equivalent (e.g., `2px` → `var(--space-2xs)`)
     - **NEEDS NEW TOKEN**: recurring value with no token — flag for creation
     - **ACCEPTABLE**: icon dimensions, media queries, SVG attributes, doc text, WCAG minimums, position nudges
   - Search CSS/Tailwind for hardcoded color values that should be variables/tokens
   - Check for consistent use of CSS custom properties
   - Verify spacing follows the defined scale (no arbitrary px values)
   - Check for font families outside the defined type system
   - **Visual regression check**: If `.visual-baselines/` exists with prior baselines,
     run `/visual-regression` on each baselined screen. SIGNIFICANT changes should be
     flagged as compliance issues — they indicate unintended visual side effects.

   **Report format**:
   ```
   ## Compliance Results
   **Token coverage**: [X]% of values use tokens, [Y]% hardcoded

   ### Off-System Values
   - [Element]: [Property] = [Actual value] — should be [Token name] ([Token value])

   ### Near-Miss Values (likely typos)
   - [Element]: [Actual] → [Nearest token]

   ### Orphan Fonts
   - [Font family] used but not in type system
   ```

   ### D. Content Stress Test

   - Review the content model from the design brief
   - For each screen, check:
     - **Long content**: What happens with maximum-length strings?
       (200-char name, 5-paragraph description, 100-item list)
     - **Empty content**: What happens with zero/null values?
     - **Special characters**: Unicode, emoji, RTL text if applicable
     - **Numeric extremes**: $0.01 vs $999,999,999.99, dates in different formats
     - **Image fallbacks**: What shows when images fail to load?

   **If Pencil MCP**: Use `batch_design` to temporarily insert extreme content,
   `get_screenshot` to verify, then revert.

   **If code-based**: Modify sample data to test extremes, render, capture.

   **Report format**:
   ```
   ## Content Stress Results

   ### Breaking Content
   - [Screen]: [Scenario] — [What breaks] — [Fix suggestion]

   ### Graceful Handling
   - [Screen]: [Scenario] — handles correctly via [mechanism]
   ```

3. **Produce unified validation report**:

   ```
   ## Design Validation Report

   **Overall**: PASS | FAIL (fail if any Critical accessibility or breakage issues)

   [Include all four section reports above]

   ## Action Items
   ### Must Fix (blocks approval)
   1. [Item] — [Which check found it]

   ### Should Fix (before handoff)
   1. [Item] — [Which check found it]

   ### Nice to Have
   1. [Item] — [Which check found it]
   ```

4. Present the validation report to the user.

## Severity Mapping

The validation report uses "Must Fix / Should Fix / Nice to Have" categories. These map to
the critique severity vocabulary used elsewhere in the DFG workflow:
- **Must Fix** = Critical (blocks approval)
- **Should Fix** = Major (should be fixed before handoff)
- **Nice to Have** = Minor (polish, separates good from excellent)

## Rules

- Accessibility failures at the target WCAG level are ALWAYS Critical severity (Must Fix)
- Design system compliance issues are Major if they affect visual consistency, Minor if isolated
- Content stress failures that break layout are Major; truncation without mechanism is Minor
- Responsive failures that hide content or break interaction are Critical
- Do NOT fail validation for aesthetic opinions — this check is objective
- If Pencil MCP `search_all_unique_properties` reveals massive inconsistency, the design has a systemic
  problem — flag it as Critical with a recommendation to use `replace_all_matching_properties` for bulk fix
- Run all four checks even if the first one fails badly — the full picture helps prioritize fixes
