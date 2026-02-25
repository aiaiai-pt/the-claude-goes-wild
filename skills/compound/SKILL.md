---
name: compound
description: Document learnings from completed work so future tasks get easier
---

# Compound Learning

After completing a feature or sprint, capture learnings that make future work easier.
$ARGUMENTS

## Process

1. **Gather what just happened**:
   - Run `git log --oneline -20` to see recent commits
   - Identify the feature/sprint that was just completed
   - Read any related spec from dev_docs/specs/

2. **Extract learnings** by answering:
   - What patterns were established that future features should follow?
   - What was harder than expected and why?
   - What existing code was discovered that saved time?
   - What mistakes were made that shouldn't be repeated?
   - What new conventions were adopted?

3. **Update institutional memory**:

   a. **Project CLAUDE.md**: If a learning applies broadly to the project,
      add it as a concise rule. Keep it short - only add what prevents mistakes.

   b. **dev_docs/solutions/**: Create or update a solution doc if a reusable
      pattern was established:
      ```
      dev_docs/solutions/<pattern-name>.md
      ```
      Include: problem, solution, code example, when to use it.

   c. **dev_docs/specs/**: If the spec had gaps vs what was actually built,
      update it to reflect reality for future reference.

   d. **Auto memory**: Update ~/.claude/projects/.../memory/MEMORY.md with
      key insights about this specific project.

   e. **User-facing docs** (`docs/`, served by MkDocs):
      - If `docs/` doesn't exist yet, scaffold it: create `docs/index.md`,
        `docs/guides/`, `docs/reference/`, `docs/architecture/overview.md`,
        and a `mkdocs.yml` with Material theme. Install mkdocs-material
        if needed (`pip install mkdocs-material`).
      - If the feature adds or changes user-visible behavior (new tools,
        new API endpoints, new admin UI capabilities, config options),
        update or create guides in `docs/guides/`.
      - If the feature adds a new subsystem or changes architecture,
        update `docs/architecture/overview.md`.
      - Add new pages to the `nav:` section in `mkdocs.yml`.
      - Cross-link from existing guides where relevant (e.g., document
        tools guide links to ingestion guide).
      - Update `docs/index.md` feature list and guide links if applicable.
      - Run `mkdocs build --strict` to verify no broken links or warnings.
      - Keep docs user-facing: explain WHAT and HOW, not internal
        implementation details. Include example API requests/responses,
        config tables, and admin UI instructions.

4. **Report what was captured**:
   - List each learning and where it was stored
   - Highlight any CLAUDE.md additions
   - Note patterns added to solutions/
   - List user-facing docs created or updated (with mkdocs build status)

## Rules

- Keep CLAUDE.md additions to 1-2 lines each - if Claude already does it right, don't add it
- Solution docs should be copy-pasteable - include real code examples
- Don't document obvious things - focus on what surprised you or caused errors
- If a previous learning in CLAUDE.md is now outdated, update or remove it
