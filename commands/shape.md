---
description: >
  Run just the discovery and shaping phases (Problem Interview → Architecture Design).
  Use when you want to shape work without publishing issues yet.
argument-hint: "<problem description>"
---

# /shape — Discover + Shape

Run Phases 1-2 of the architect pipeline only:

1. Use `@agent-problem-analyst` to interview and produce a pitch
2. Use `@agent-system-designer` to create architecture and module map
3. Stop after presenting the architecture summary for review

This is useful when:
- You want to shape before a betting table discussion
- You need architecture review before committing to specification
- You're exploring multiple approaches and want to compare pitches

Pass `$ARGUMENTS` as the problem description to kickstart discovery.
