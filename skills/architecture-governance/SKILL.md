---
name: architecture-governance
description: >
  Architectural governance rules enforced by the architect agents and validated
  by the validate-architect-output script. Covers stack alignment, API
  contracts, multi-tenancy, versioning, testing, and issue quality. Use when
  writing specs, ADRs, or when reviewing architect output.
---

# Architecture Governance

These rules are enforced by the architect agents and validated by
`scripts/validate-architect-output.py`.

## Stack Alignment

- Every technology choice defaults to the active platform profile's canonical stack
- Deviations require an ADR with "Accepted" status before implementation begins
- The DX report flags all deviations with ⚠ markers

## API Contracts

- All REST APIs have an OpenAPI 3.1 spec
- All event topics have an AsyncAPI spec or JSON Schema
- API changes that break backward compatibility require a MAJOR version bump

## Multi-Tenancy

- Every data model includes the tenancy columns required by the active profile
  (e.g., `instance_id` + `tenant_id` for the Ubiwhere profile)
- Every API endpoint validates tenant access against the active authorization engine
- Analytical storage namespaces are scoped per the profile's convention

## Versioning

- Components follow SemVer 2.0.0
- All commits follow Conventional Commits specification
- semantic-release automates version bumps in CI
- Each Shape Up cycle has a product milestone in the issue tracker
- CHANGELOG.md is auto-generated per component

## Testing

- Solution type determines minimum test depth (see `test-strategy` skill)
- Data quality gates are non-negotiable for any module that touches analytical pipelines
- Performance baselines are established before first production deployment

## Issue Quality

- Every issue is self-contained (understandable without the architecture doc)
- Every feature issue has acceptance criteria (Given/When/Then)
- Every feature issue has a version label (`version:{component}:{bump}`)
- Every feature issue includes the conventional commit type for developers
- Nice-to-haves are marked with ~ and cut first during scope hammering

## Profile Additions

When a platform profile is active, it may add profile-specific governance rules
(e.g., canonical grammar enforcement, anti-pattern detection, gap references).
The validator and agents load these automatically when the profile is active.

See `references/generic-rules.md` for the stack-agnostic baseline.
