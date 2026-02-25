---
name: commit
description: Verify and commit changes with component discovery and quality checks
---

# Commit Workflow

When committing changes, follow this sequence strictly. Do NOT skip steps.

## 1. Discovery

Search for ALL related components that may have been affected:
- Use grep/glob to find files importing or referencing changed modules
- Check for `-cli`, `-sdk`, `-api`, `-core`, `-ui` variants of changed packages
- Check for related test files, config files, and documentation
- List any related components found that were NOT modified (potential gaps)

## 2. Verify

Run verification checks appropriate to the changed files:
- **Python**: `ruff check` and `pytest` for changed modules
- **JavaScript/TypeScript**: `npm run test` and `npm run build` for affected packages
- **Svelte**: `npm run check` in the relevant project
- If tests fail, fix them before committing. Do NOT commit failing tests.

## 3. Stage

Review what will be committed:
- Run `git status` to see all changes (never use `-uall` flag)
- Run `git diff --staged` and `git diff` to review changes
- Stage specific files by name - avoid `git add -A` or `git add .`
- NEVER commit `.env`, credentials, or secrets files
- Flag any untracked files that look like they should be included

## 4. Commit

- Read recent `git log --oneline -10` to match existing commit message style
- Write a concise commit message focusing on WHY, not WHAT
- Use conventional commit format: `feat:`, `fix:`, `refactor:`, `docs:`, `test:`
- Use a HEREDOC for the commit message
- End with `Co-Authored-By: Claude <noreply@anthropic.com>`

## 5. Summary

After committing, report:
- Files committed (count and list)
- Tests that passed
- Related components found (and whether they needed changes)
- Any gaps or follow-up work identified

## Rules

- NEVER force push, reset --hard, or skip hooks unless explicitly asked
- NEVER amend a previous commit unless explicitly asked
- If a pre-commit hook fails, fix the issue and create a NEW commit
- If there are no changes to commit, say so - do NOT create empty commits
