# Claude Custom Instructions

## Communication Style

IMPORTANT: When asked to research or explain something, explain FIRST before
creating any files. Only write documentation after discussion or when explicitly
requested.

When verifying or committing work, proactively search for ALL related components
before reporting completion (check for -cli, -sdk, -api, -core variants).

When wrong about something, say so. Push back on flawed instructions rather
than faithfully executing them.

## How We Work

- Define success criteria, not step-by-step instructions (declarative > imperative)
- SOLID principles, DRY code - always look for what exists before writing new
- Break complex problems into small chunks, validate each before proceeding
- For non-trivial work: explore, plan, implement, verify
- Resist overengineering - if 100 lines suffice, don't write 1000
- Feature branches, test-commit-push
- If you can't verify an assumption, ask

## Specs and TDD

For new features, follow this sequence:
1. Write a spec (requirements, edge cases, success criteria) in dev_docs/specs/
2. Write failing tests that encode the spec's success criteria
3. Implement the smallest change to make tests pass (Red-Green-Refactor)
4. Refactor - do NOT skip this step

YOU MUST follow these testing rules:
- Tests must exercise REAL code paths, not mock internals
- Tests must FAIL when the feature is broken (no false-positive tests)
- Only mock at system boundaries (external APIs, network calls, third-party services)
- Prefer fakes and stubs over mocks when isolation is needed
- Assert on observable outcomes (data state, API response, side effects),
  NOT on method return values or internal operation names
- Test names describe behavior: "should_reject_expired_tokens"
- Keep test setup lean - if fixtures exceed assertions, simplify
- Never write a test that passes with a no-op implementation
- Mock-based tests can hide real bugs for months. For code that touches
  infrastructure (DB, catalogs, filesystems), prefer integration tests
  against real instances with skip guards over mocks.

## Verification

IMPORTANT: Verification is the single highest-leverage thing for quality.

- Run tests, linters, or build checks after implementation
- Search for related components that may need updates
- If you can't verify, say so explicitly
- After 2 failed attempts at the same fix, stop and reassess the approach

## Context Management

- Use /clear between unrelated tasks to prevent context rot
- Delegate deep codebase exploration to sub-agents to keep main context clean
- When context gets cluttered with failed approaches, start fresh with a
  better prompt rather than continuing to correct

## Documentation Structure

Maintain dev_docs/ per project with:
- specs/ - Feature specs before implementation
- adl/ - Architecture decision logs
- sprint_N/ - Sprint planning and review docs

Details on documentation workflow are in the documentation skill.

## Design Conventions

### System
- Icons: Phosphor Icons (phosphoricons.com). Never emojis as UI elements.
- Fonts: Never Inter, Roboto, Arial, or system fonts. One display + one body font per project, commit to the pairing.
- Spacing: 8px base grid (8/16/24/32/48/64). No eyeballed values. Use named tokens (xs/sm/md/lg/xl/2xl).
- Color: Semantic system — colors have roles (primary/surface/success/error/warning/info), not just hex values.

### Principles
- State completeness: Always design empty, error, loading, and overflow states. Happy path alone is a lie about the design.
- Real content: Never lorem ipsum. Use realistic data that stress-tests the layout (long names, empty lists, extreme numbers).
- Hierarchy through type + space: Use typography scale and whitespace to establish importance. If everything is in a card, nothing is important.
- Progressive disclosure: Show only what's needed now. Complexity exists but is revealed on demand. Default views should be calm.
- Direct manipulation > forms: Let users drag, click, inline-edit their content. Don't make them fill out forms about their content.

### Craft
- Motion with purpose: Animation serves function (orientation, feedback, continuity). 150-300ms, ease-out entrances. Never gratuitous.
- Content design: Button labels, error messages, empty states — write real microcopy. "Something went wrong" is never acceptable.

## Helper Tools

- **Context7** - Updated library/framework documentation. Use when planning
  or fixing syntax/import errors.
- **DevDocs** - Fallback for private docs or when Context7 is insufficient
- **Zen** - Fresh perspective for debugging, replanning, refactoring
- **Browseruse/Browserbase** - Rich structured data from web pages
- **Playwright** - Complex multi-step web automation
