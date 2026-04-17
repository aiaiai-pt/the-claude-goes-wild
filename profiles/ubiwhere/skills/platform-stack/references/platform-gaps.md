# Platform Gaps (UBP)

From the platform assessment (2026-04-10). When your module addresses a gap,
reference the gap ID in the module spec and issue body. When your module
depends on a still-open gap, flag it prominently.

---

## Critical Gaps (blocking platform vision)

### G1 — No Unified API Gateway (Effort: M)
Frontends connect directly to 3+ backends. No rate limiting, composition, or
unified auth at the edge.

**Roadmap**: Phase 1.3 — implement API gateway (BFF or Kong/Traefik middleware).

**For new modules**: Route through the future gateway (when ready) rather than
exposing direct backend endpoints. Until then, document the endpoints your
module exposes so they can be front-ended later.

### G2 — No Standard Transformation Pipeline (Effort: L)
O(n) cost per new client. `data-library` repo empty for 2 months. Each
municipality needs custom Dagster code.

**Roadmap**: Phase 1.1 — build shared `data-library` with standard transforms,
NGSI-LD conversion helpers, medallion layer helpers.

**For new modules**: New data modules **MUST** contribute to the shared
`data-library` rather than building per-client custom Dagster code. This is
also documented in AP-2 and R3.

### G3 — FIWARE/Orion Disabled Everywhere (Effort: M)
Smart city platform with no NGSI-LD/ETSI compliance. Infra cost with zero
production value. Orion-LD deployed but `enabled: false` in all prod instances.

**Roadmap**: Phase 0.4 — ADR-001 must resolve: integrate or decommission.

**For new modules**: Do NOT propose new NGSI-LD publication until ADR-001
resolves (see AP-5). Flag as blocked if NGSI-LD compliance is required.

### G4 — No Data Compliance/Quality Service (Effort: L)
No anomaly detection, freshness monitoring, or data policy enforcement. Only 4
ingestion schemas validated.

**Roadmap**: Phase 3.1 — build Data Quality & Compliance service.

**For new modules**: Document the quality gates you need; when G4 lands, hook
into it. Until then, use Dagster asset checks inline.

---

## Significant Gaps

### G5 — No Workflow Management (standalone) (Effort: L)
Zeebe buried in `multivertical-django` monolith. No citizen-facing process
automation.

**Roadmap**: Phase 3.2 — extend Temporal or deploy n8n.

**For new modules**: Use Temporal (per AP-2). Do not propose new Zeebe.

### G6 — No Chatbot / AI Assistant (Effort: M)
Martha exists (AI backend) but no user-facing assistant.

**Roadmap**: Phase 3.3 — leverage Martha for natural-language queries.

### G7 — No Portal Publishing (Effort: M)
No CMS or publishing workflow for portal content.

**Roadmap**: Phase 1+ — TBD.

### G8 — No Centralized Config Management (Effort: S)
Each service manages its own config. No feature flags.

**Roadmap**: Phase 0+ — introduce a feature-flag service (OpenFeature or similar).

### G9 — No Audit Server (Effort: M)
No centralized audit trail for user actions or data changes.

**Roadmap**: Phase 3.5 — build Audit service.

**For new modules**: Log audit events as structured JSON with tenant_id +
subject_id + event_type. When G9 lands, it can ingest from logs.

### G10 — No IoT Discovery Service (Effort: M)
Every source manually configured. No auto-discovery.

**Roadmap**: TBD.

---

## Moderate Gaps

### G11 — Frontend Fragmentation (Effort: L)
5 different approaches (React 19 + TanStack Router, Turborepo + Vite,
TanStack Start, pnpm monorepo, Node.js + Drizzle + React canvas). No shared
component library consumed cross-project.

**Roadmap**: Phase 2.5 — publish `@ubiwhere/design-system-components` from
Nexus as NPM package; standardize on TanStack Start + schema-renderer.

**For new modules**: New frontends use **TanStack Start + Nitro + schema-renderer +
@ubiwhere/design-system-components** (per stack-reference). Do NOT start a 6th approach.

### G12 — No Miniapps Framework (Effort: L)
`app-builder` is nascent. No runtime for user-built applications.

### G13 — No Strategy Services (Effort: ?)
Referenced in architecture, not defined or implemented.

### G14 — No ODIN Modules (ODIN-X, ODIN-B) (Effort: ?)
Referenced in architecture, no implementation.

### G15 — No ML Infrastructure (Grid/ML) (Effort: L)
No MLflow, KubeFlow, feature store, or model registry.

**Roadmap**: Phase 4.3 — MLflow on GKE when concrete use cases emerge.

---

## Using gap IDs

### In module specs
When your module closes a gap, add to the module SPEC.md:
```markdown
## Addresses Platform Gaps
- **G2** — this module contributes to `data-library` with the `fire_risk` transform template
- **G4** — this module defines data quality rules consumable by future G4 service
```

### In issues
The issue-writer adds gap IDs as labels (`gap:G2`, `gap:G4`) and mentions them
in the epic body.

### In DX reports
The dx-reporter summarizes which gaps the project addresses vs. depends on.

### In `validate-architect-output.py`
The validator cross-references gap IDs mentioned in specs against this list —
unknown gap IDs are flagged as warnings.
