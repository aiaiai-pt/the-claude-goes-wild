# Versioning, Milestones & Conventional Commits

## Component Versioning (SemVer)

Each architecture **module** maps to a deployable **component** with its own SemVer version.
When the architect process creates a module, it assigns an initial version based on its maturity.

### Initial Version Assignment

| Solution Type | Initial Version | Rationale |
|---------------|----------------|-----------|
| Dev/Spike | No version | Throwaway, not tracked |
| Prototype | `0.1.0` | Pre-release, anything can break |
| MVP | `0.1.0` | Pre-release, moving toward 1.0 |
| Production MVP | `0.1.0` or `1.0.0-rc.1` | Depends on API stability commitment |
| Real Production | `1.0.0` | Stable API contract, SemVer enforced |

### Version Bumping Rules (SemVer 2.0.0)

```
MAJOR.MINOR.PATCH[-prerelease][+build]

MAJOR: Breaking API change (removed endpoint, changed auth model, schema migration)
MINOR: New feature, backward-compatible (new endpoint, new field, new capability)
PATCH: Bug fix, backward-compatible (fix, performance improvement, doc update)
```

### Pre-release Labels

```
0.1.0-alpha.1    → Internal development
0.1.0-beta.1     → Internal testing / staging
0.1.0-rc.1       → Release candidate (feature-complete, stabilizing)
1.0.0            → First stable production release
```

### Component Version Tracking

Each module spec declares its target version:
```markdown
**Component**: my-service
**Current Version**: — (new component)
**Target Version**: 0.1.0
**Version Strategy**: Pre-release (0.x) until API stabilizes; 1.0.0 after first production cycle
```

For existing components being extended:
```markdown
**Component**: platform-api
**Current Version**: 2.3.1
**Target Version**: 2.4.0 (new endpoints, backward-compatible = MINOR bump)
```

## Product Milestones

A **milestone** represents a Shape Up cycle or a release target. It groups all issues
across all modules that ship together.

### Milestone Naming Convention

```
{product}-{version}[-{cycle-label}]

Examples:
  my-product-0.1.0                         → First release of a new product
  my-product-0.2.0-cycle-2                 → Second cycle iteration
  platform-2.4.0                           → Minor platform release
  platform-3.0.0-breaking                  → Major platform release
```

### Milestone ↔ Shape Up Mapping

| Shape Up Concept | Tracker Concept |
|-----------------|----------------|
| Cycle (6 weeks) | **Milestone** with due date |
| Pitch | **Epic** (or parent issue) |
| Module | **Component/Label** with version |
| Feature | **Issue** within milestone |
| Cooldown | No milestone (unscheduled work) |

### Milestone Structure in Issue Trackers

**Linear**:
- Milestone = Project with target date
- Component version = Label (`component:my-service@0.1.0`)
- Cycle = Linear Cycle

**GitLab**:
- Milestone = GitLab Milestone (with due date)
- Component version = Label (`component:my-service`, `version:0.1.0`)
- Group milestones span multiple projects

**GitHub**:
- Milestone = GitHub Milestone (with due date)
- Component version = Label (`component:my-service`, `version:0.1.0`)

## Conventional Commits

All commits follow the [Conventional Commits](https://www.conventionalcommits.org/) specification.
This enables automatic version bumping, changelog generation, and CI/CD gating.

### Commit Format

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

### Types and Their SemVer Impact

| Type | Description | SemVer Impact |
|------|------------|---------------|
| `feat` | New feature | MINOR bump |
| `fix` | Bug fix | PATCH bump |
| `docs` | Documentation only | No bump |
| `style` | Formatting, no logic change | No bump |
| `refactor` | Code change, no feature/fix | No bump |
| `perf` | Performance improvement | PATCH bump |
| `test` | Adding/fixing tests | No bump |
| `ci` | CI/CD configuration | No bump |
| `chore` | Maintenance, dependencies | No bump |
| `build` | Build system changes | No bump |
| **BREAKING CHANGE** | Any type with `!` or `BREAKING CHANGE:` footer | **MAJOR bump** |

### Scopes (map to modules/components)

```
feat(my-service): add threshold configuration API
fix(data-ingestion): handle API timeout gracefully
feat(dashboard): add risk map component
test(my-service): add integration test for gold layer
ci(project): add E2E to merge pipeline
feat(my-service)!: change threshold API to require severity field

BREAKING CHANGE: POST /api/v1/thresholds now requires `severity` field.
Existing thresholds without severity will default to "medium".
```

### Linking Commits to Issues

```
feat(my-service): add data processing pipeline

Implements the data flow with quality gates at each layer.

Refs: F-02.1
```

### Automation Tooling

| Tool | Purpose | Integration |
|------|---------|-------------|
| **commitlint** | Validates commit message format | Git hook (husky / lefthook) |
| **semantic-release** | Auto version bump + changelog | CI (GitLab CI / GitHub Actions) |
| **conventional-changelog** | Generate CHANGELOG.md | Part of release pipeline |
| **commitizen** | Interactive commit message builder | Developer convenience |

### GitLab CI Integration

```yaml
# .gitlab-ci.yml — release stage
release:
  stage: release
  image: node:22
  script:
    - npx semantic-release
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
  variables:
    GITLAB_TOKEN: $GITLAB_TOKEN
```

### .commitlintrc.yml

```yaml
extends:
  - '@commitlint/config-conventional'
rules:
  scope-enum:
    - 2
    - always
    - - my-service
      - data-ingestion
      - dashboard
      - platform-api
```

## Release Flow

```
Feature branch → Conventional commit → PR/MR → Merge to main
    → CI: commitlint validates message
    → CI: semantic-release reads commits since last tag
    → CI: determines bump type (patch/minor/major)
    → CI: updates version, generates changelog, creates git tag
    → CI: builds + signs container image with version tag
    → Deploy pipeline detects new image tag → deploys
```

## CHANGELOG.md (auto-generated)

```markdown
# Changelog

## [0.2.0] - 2026-07-15

### Features
- **my-service**: add threshold configuration API (F-02.2)
- **dashboard**: add risk map (F-03.1)

### Bug Fixes
- **data-ingestion**: handle API timeout (F-01.1)

### Breaking Changes
- None
```
