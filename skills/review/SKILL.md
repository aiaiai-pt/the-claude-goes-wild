---
name: review
description: Review code changes for quality, security, and correctness
---

# Code Review

Review the current changes using a fresh perspective. $ARGUMENTS

## Process

1. **Gather context**: Run `git diff` to see all uncommitted changes. If an argument
   was provided (branch name, PR number, or file path), scope the review to that.

2. **Analyze each changed file** for:
   - Logic errors and edge cases
   - Security vulnerabilities (injection, XSS, credential exposure, OWASP top 10)
   - Missing error handling at system boundaries
   - Tests that are facades (pass with no-op, mock internals, assert on return
     values instead of observable outcomes, or mock infrastructure that could be real)
   - Breaking changes to public APIs
   - Performance issues (N+1 queries, unbounded loops, missing indexes)

3. **Check for gaps**:
   - Changed code without corresponding test updates
   - New public functions/endpoints without tests
   - Related components that should have been updated but weren't

4. **Produce a structured report**:

```
## Review Summary
**Files reviewed**: N
**Severity**: Clean | Minor | Major | Critical

## Findings
### [Critical/Major/Minor] Finding title
- **File**: path/to/file:line
- **Issue**: What's wrong
- **Fix**: Suggested resolution

## Missing Coverage
- [ ] List of untested paths or edge cases

## Overall Assessment
One paragraph: is this ready to commit?
```

## Rules

- Be specific - cite file paths and line numbers
- Distinguish between must-fix (blocking) and nice-to-have (non-blocking)
- Don't flag style issues that a linter/formatter would catch
- Focus on logic, security, and correctness over cosmetics
- If everything looks good, say so concisely
