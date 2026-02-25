---
name: dependency-patch
description: Manage dependency updates with supply chain safety via cooldown periods
---

# Dependency Patch

Check for and apply dependency updates with supply chain safety controls. $ARGUMENTS

## Process

1. **Inventory current dependencies**:
   - Detect all package managers in the project
   - List all direct dependencies with current versions
   - Identify lockfile(s) and their last update date
   - Note any pinned versions and why (check comments, CLAUDE.md, docs)

2. **Check for available updates**:
   - For each package manager, check available updates:
     - Node.js: `npm outdated --json` or `yarn outdated --json`
     - Python: `pip list --outdated --format=json`
     - Rust: `cargo outdated --format=json`
     - Go: `go list -u -m all`
   - For each update, gather:
     - Current version → available version
     - Change type: patch / minor / major
     - Published date of the new version
     - Whether it's a security fix (cross-reference with audit results)
     - Changelog summary (if accessible)

3. **Classify each update by risk and apply cooldown**:

   | Category | Criteria | Action |
   |----------|----------|--------|
   | **Auto-apply** | Patch/minor security fix, published > 3 days ago, tests pass | Apply immediately |
   | **Cooldown** | Patch/minor security fix, published < 3 days ago | Wait. Schedule re-check in 3 days. |
   | **Auto-apply** | Patch non-security, published > 3 days ago, tests pass | Apply if no breaking changes detected |
   | **Human review** | Major version bump (any) | Create PR with changelog analysis |
   | **Human review** | Any update where tests fail after apply | Revert, create issue |
   | **Human review** | Updates to security-critical packages (auth, crypto, TLS) | Always human review regardless of version bump |

   **Why 3-day cooldown**: Supply chain attacks often target new package versions.
   Waiting 3 days allows the community to detect and report compromised packages
   before they enter our dependency tree. This is standard practice (Renovate's
   `minimumReleaseAge`, Dependabot's `cooldown`).

4. **For each auto-apply update**:
   - Create a branch: `chore/deps-<package>-<version>`
   - Apply the update
   - Run the full test suite
   - **Signal**: test exit code 0/1
   - If tests pass: commit with message `chore(deps): update <package> to <version>`
     noting whether it's a security fix
   - If tests fail: revert, log the failure, flag for human review

5. **For each human-review update**:
   - Create a PR with:
     - Changelog summary (breaking changes highlighted)
     - Test results after applying
     - Security advisory details (if security fix)
     - Risk assessment: what could break?
   - Assign to appropriate human reviewer

6. **Produce report**:

```
## Dependency Patch Report
**Date**: YYYY-MM-DD

## Applied
| Package | From | To | Type | Security Fix | Tests |
|---------|------|----|------|-------------|-------|

## Waiting on Cooldown
| Package | From | To | Published | Available After | Security Fix |
|---------|------|----|-----------|----------------|-------------|

## Needs Human Review
| Package | From | To | Reason |
|---------|------|----|--------|

## Skipped (Pinned)
| Package | Version | Reason for Pin |
|---------|---------|---------------|

## Summary
- Auto-applied: N updates
- On cooldown: N updates (next check: date)
- Human review needed: N updates
- Total dependencies: N, up to date: N%
```

## Rules

- The 3-day cooldown is NON-NEGOTIABLE for automated patches. No override.
- Security-critical packages (anything touching auth, crypto, TLS, session management)
  ALWAYS require human review, even for patch updates
- Never apply an update if tests fail — revert immediately
- Pinned versions must have a documented reason. If no reason exists, treat as unpinned.
- Major version bumps are never auto-applied. Ever.
- After applying patches, run the FULL test suite, not just affected tests
- If a package has been compromised (known supply chain incident), add to a block list
  and alert human immediately
