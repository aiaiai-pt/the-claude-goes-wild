---
description: >
  Publish all specified modules as issues to your chosen tracker (Linear, GitLab,
  GitHub, or Markdown). Run after modules are specified.
---

# /publish-issues — Publish to Issue Tracker

1. Read all module specs from `docs/architect-process/architecture/modules/`
2. Check `.architect-state.json` for tracker preference. If not set, ask the user.
3. Use `@agent-issue-writer` to create epics and issues
4. Present summary with links

Can also re-publish after spec changes — the issue writer notes which issues are new vs updated.
