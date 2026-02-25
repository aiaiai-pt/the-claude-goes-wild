---
name: visual-regression
description: Capture and compare visual snapshots for design regression testing
user_invocable: true
---

# Visual Regression Skill

Screenshot comparison tool for catching unintended visual changes during design work. Captures baseline screenshots of pages or components, then compares future states pixel-by-pixel to surface regressions.

## Setup (per-project, first use)

Install dependencies and browser:

```bash
npm install -D playwright pixelmatch pngjs
npx playwright install chromium
```

Add the baselines directory to `.gitignore`:

```
.visual-baselines/
```

## Usage

### Capture a baseline

```bash
node ~/.claude/tools/visual-regression.mjs --url http://localhost:5173/path --name page-name
```

This saves a baseline screenshot to `.visual-baselines/page-name.baseline.png`.

### Compare after changes

Run the same command again. If a baseline exists, the tool captures a new screenshot, runs pixel comparison, and reports the result.

### Screenshot a specific element

```bash
node ~/.claude/tools/visual-regression.mjs --url http://localhost:5173/path --name hero --selector ".hero-section"
```

### Custom viewport

```bash
node ~/.claude/tools/visual-regression.mjs --url http://localhost:5173/path --name mobile-nav --viewport 375x812
```

## Standard Viewports

| Device  | Viewport    | Notes          |
|---------|-------------|----------------|
| Mobile  | `375x812`   | iPhone-class   |
| Tablet  | `768x1024`  | iPad-class     |
| Desktop | `1440x900`  | Default        |

## Reading Results

The tool outputs one of three statuses:

- **IDENTICAL (0.00%)** — No pixel differences. Exit code 0.
- **MINOR CHANGE (X.XX%)** — Less than 0.5% of pixels changed. Exit code 0.
- **SIGNIFICANT CHANGE (X.XX%)** — 0.5% or more pixels changed. Exit code 1.

When a diff is generated, use the Read tool on the diff PNG file (`.visual-baselines/{name}.diff.png`). Claude can evaluate visual differences multimodally — pink/red highlighted regions in the diff image show exactly where pixels changed.

The current screenshot is also saved at `.visual-baselines/{name}.current.png` for direct inspection.

## DFG Integration

Visual regression fits naturally into the Design Flow Generator workflow:

1. **Before critique phase**: Capture baselines of the current approved state.
2. **After changes**: Compare against baselines to catch unintended regressions in other parts of the page.
3. **During validate phase**: Use comparison results as automated input — a SIGNIFICANT diff should trigger investigation.

## Updating Baselines

When a visual change is intentional and approved, update the baseline:

1. Delete the old baseline: remove `.visual-baselines/{name}.baseline.png`
2. Re-run the command to capture the new baseline

## When to Capture Baselines

- After design approval (lock in the accepted state)
- Before token-level changes (spacing, color, typography adjustments)
- Before refactors (component restructuring, CSS migrations)
- At sprint boundaries (snapshot the current state for future reference)
