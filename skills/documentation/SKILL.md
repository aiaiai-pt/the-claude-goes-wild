---
name: documentation
description: Documentation workflow for managing dev_docs structure across projects
---

# Documentation Management Workflow

When instructed to "follow your custom instructions" or starting structured work,
read project docs in this order:
1. dev_docs/productRoadmap.md (high-level goals and progress)
2. dev_docs/currentTask.md (current objectives and next steps)
3. dev_docs/codebaseSummary.md (project structure overview)

## dev_docs/ Structure

### productRoadmap.md
- High-level goals, features, completion criteria, progress tracker
- Use checkboxes (- [ ] / - [x]) for tasks
- Include a "completed tasks" section for history
- Update when goals change or tasks complete

### currentTask.md
- Current objectives, context, and next steps
- Reference tasks from productRoadmap.md
- Update after completing each task or subtask

### specs/
- Feature specs written BEFORE implementation
- Include: requirements, edge cases, success criteria, API contracts
- Specs become living documentation

### adl/decision_log_NNN_description.md
- Architecture decision logs
- Include: context, decision, rationale, consequences
- Update when significant technology decisions are made

### codebaseSummary.md
- Key components and their interactions
- Data flow
- External dependencies
- Recent significant changes

### keyLearnings.md
- Lessons that should influence future code, docs, or designs
- Outdated syntax, wrong assumptions, surprising features
- Update when learnings become outdated
- Review often

### sprint_N/
- planning/ - Sprint plans, spikes, architecture reviews
- review/ - Mid-sprint check-ins, retrospectives

### other_refs/
- Reference documents (styleAesthetic.md, wireframes.md, etc.)
- Link from codebaseSummary.md for discoverability

## Rules
- Update docs on significant changes, not minor steps
- If conflicting info between documents, ask for clarification
- Create userInstructions/ files for tasks requiring user action
