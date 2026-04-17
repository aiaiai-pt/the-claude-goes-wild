# Ubiwhere Profile

Overlays the generic team config with Ubiwhere Urban Platform conventions.

## What this profile provides

- **`platform-stack`** (overrides generic shell) — canonical Ubiwhere stack:
  medallion (Iceberg + Polaris + Trino), Dagster + dlt, Kafka/Strimzi + Redpanda
  Connect, Keycloak + UMS v2 + SpiceDB, FastAPI + PostgreSQL+PostGIS+TimescaleDB,
  TanStack Start + Nitro + `@ubiwhere/schema-renderer` + `@ubiwhere/design-system-components`,
  GKE + ArgoCD + Crossplane + Terraform (GCP, Workload Identity, europe-west1),
  Harbor + Nexus, GitLab CI, LGTM + Alloy + OTel, Cosign + Trivy + Semgrep +
  SonarQube + Dependency-Track

- **`platform-grammar`** (new skill, profile-only) — normative canonical grammar
  from `ubp-spec/ontology`: identifier prefixes (`inst_`, `tnt_`, `scp_`, `usr_`,
  `evt_`, `req_`, …), context tuple, event envelope required keys, enumerated
  API paths, forbidden synonyms (`municipality_id`, `workspace`, `visibility_zone`,
  …), state vocabulary, naming conventions (tables `snake_case`, entity types
  `PascalCase`, events `PastTense`)

## What this profile enforces

When active, the architect agents:

- Default every technology choice to the Ubiwhere canonical stack (deviations require ADRs)
- Refuse to propose anti-patterns listed in `platform-stack/references/anti-patterns.md`
  (e.g., introducing a new async runtime when Temporal is canonical; a new Django
  backend when FastAPI is the direction; NGSI-LD publication while ADR-001 is unresolved)
- Reference open platform gaps (`platform-gaps.md`) when a module addresses one
- Use the canonical grammar in every spec, API, DB, and topic name
- Use the canonical GCS bucket layout for any data modules

`scripts/validate-architect-output.py` lints produced artifacts against these rules.

## Installing

```bash
# From the repo root
./profiles/ubiwhere/install.sh
```

This:
1. Replaces `~/.claude/skills/platform-stack/` with the Ubiwhere version
2. Adds `~/.claude/skills/platform-grammar/`
3. Writes `ubiwhere` to `~/.claude/.active-profiles`

## Uninstalling

```bash
./profiles/ubiwhere/uninstall.sh
```

Restores the generic `platform-stack` shell and removes `platform-grammar`.

## References (drill-down)

Inside `skills/platform-stack/references/`:
- `stack-reference.md` — full canonical stack
- `appetite-stack-map.md` — stack recommendations per Shape Up appetite
- `platform-topology.md` — actual deployed topology (GKE, GCS buckets, regions, envs)
- `bucket-layout.md` — canonical GCS lakehouse path layout
- `anti-patterns.md` — 7 APs architect must refuse (AP-1 through AP-7)
- `platform-gaps.md` — 15 open platform gaps (G1 through G15)
- `domain-verticals.md` — domain taxonomy
- `multi-tenancy.md` — Instance → Tenant at service layer (NOT DB RLS)

Inside `skills/platform-grammar/references/`:
- `canonical-grammar.md` — EBNF for identifiers and context tuple
- `event-envelope.md` — required keys for `/v1/events`
- `api-paths.md` — enumerated `/v1/...` paths
- `forbidden-synonyms.md` — never-use terms with replacements
- `state-vocabulary.md` — allowed status values
