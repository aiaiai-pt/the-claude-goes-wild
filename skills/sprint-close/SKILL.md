---
name: sprint-close
description: Verify and close a sprint by reviewing all changes against goals
disable-model-invocation: true
---

# Sprint Closure Verification

Close the current sprint: $ARGUMENTS

## Process

1. **Identify sprint scope**:
   - Read the sprint plan from dev_docs/sprint_N/planning/
   - List all goals and exit criteria from the plan
   - Determine the sprint start commit (find the branch point or sprint start date)

2. **Inventory all changes**:
   - Run `git log --oneline` from sprint start to HEAD
   - Categorize commits by sprint goal (feature, fix, docs, infra, test)
   - Flag any commits that don't map to a sprint goal (orphaned changes)

3. **Verify exit criteria**:
   For each task in the sprint plan:
   - Check: Is the code committed and pushed?
   - Check: Do tests exist and pass?
   - Check: Is documentation updated?
   - Mark as: Complete / Partial / Not Started

4. **Run final verification**:
   - Execute the project's test suite
   - Run linters on all changed files
   - Check for uncommitted work (`git status`)
   - Check for TODO/FIXME comments in changed files

5. **Generate sprint review document**:

   Create `dev_docs/sprint_N/review/SPRINT_N_REVIEW.md`:

   ```markdown
   # Sprint N Review

   ## Summary
   - **Planned**: X tasks
   - **Completed**: Y tasks
   - **Partial**: Z tasks
   - **Not started**: W tasks

   ## Completed Work
   | Task | Commits | Tests | Notes |
   |------|---------|-------|-------|
   | ... | ... | Pass/Fail | ... |

   ## Gaps and Carryover
   - [ ] Tasks to carry to next sprint

   ## Test Results
   - Backend: X passed, Y failed
   - Frontend: X passed, Y failed

   ## Key Learnings
   - What went well
   - What to improve

   ## Metrics
   - Commits: N
   - Files changed: N
   - Lines added/removed: +N/-N
   ```

6. **Report to user**:
   - Present the review summary
   - List any blocking issues
   - Recommend: Ready to close / Needs work on [items]
