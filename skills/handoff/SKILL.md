---
name: handoff
description: Finalize current work, commit, save memory, and produce a follow-up prompt for the next session. Use at any milestone when you want to cleanly hand off to a fresh context.
---

# Handoff

Finalize the current work session: commit changes, update memory, and produce a
self-contained follow-up prompt that a fresh Claude context can pick up without
losing anything.
$ARGUMENTS

## Process

### 1. Commit pending work

If there are uncommitted changes, run `/commit` first. If there's nothing to
commit, note that and continue.

### 2. Update project memory

Check auto-memory at `~/.claude/projects/.../memory/MEMORY.md` and the project's
memory files. Create or update a memory file for the current work:

- **What was done** (with commit hashes)
- **What's remaining** (concrete next steps, not vague descriptions)
- **Key decisions made** (so the next context doesn't re-litigate them)
- **Gotchas discovered** (things that broke or surprised you)

Add a pointer to the new memory file in `MEMORY.md` if it doesn't exist.

### 3. Extract learnings

Review the conversation for things the next session should know:

- **Patterns established** — code patterns, file conventions, naming
- **Mistakes made and fixed** — review findings, bugs caught, wrong assumptions
- **Codebase discoveries** — files/APIs/patterns that were non-obvious
- **User preferences revealed** — feedback corrections, style preferences

If any learnings are broadly applicable (not just this task), save them as
feedback memories.

### 4. Produce the follow-up prompt

Write a complete, actionable prompt the user can paste after `/clear`. It must:

a. **State what's done** — branch, commit, what shipped
b. **State what's next** — ordered list of remaining work with enough detail
   that a fresh context can start immediately (file paths, function names,
   design decisions already made)
c. **Include learnings** — the mistakes and patterns from this session, stated
   as rules ("Use X, not Y" / "Always do Z before W")
d. **Reference the spec** — point to the spec file so the next context reads it
e. **Reference memory** — point to the memory file for full status
f. **Be self-contained** — a fresh context with no prior conversation should
   be able to pick this up and start working without asking questions

Format the prompt as a fenced code block so the user can copy it directly.

### 5. Present to the user

Show:
- Commit summary (files, test count)
- Memory files created/updated
- The follow-up prompt in a code block

## Rules

- NEVER skip the commit step — uncommitted work is lost work
- NEVER skip the memory step — unrecorded decisions get re-litigated
- The follow-up prompt must be SPECIFIC (file paths, function names, line numbers)
  not GENERIC ("continue implementing the feature")
- Include learnings as concrete rules, not narratives
- If the user provides arguments (e.g., `/handoff focus on 4B next`), incorporate
  that into the follow-up prompt's ordering
- Keep the follow-up prompt under 200 lines — enough context, not a novel
