# Profiles

Profiles layer **team-specific stack conventions** on top of the generic
`the-claude-goes-wild` config. Only install one at a time.

## Purpose

The generic team config ships stack-agnostic skills (`problem-discovery`,
`system-architecture`, `module-specification`, `test-strategy`,
`issue-publishing`, `dx-reporting`, `architecture-governance`) and a
`platform-stack` **shell**. Profiles override the shell with real
technology choices and can add profile-only skills (like a normative
grammar skill).

## How a profile works

A profile lives under `profiles/{name}/` and ships:

```
profiles/{name}/
├── README.md          # what this profile is for
├── install.sh         # overlay installer
├── uninstall.sh       # overlay uninstaller
└── skills/            # skill overrides + additions
    ├── platform-stack/          # OVERRIDES generic shell
    └── {profile-only-skill}/    # e.g., platform-grammar for the Ubiwhere profile
```

When installed, the profile:
1. Swaps `~/.claude/skills/platform-stack/` symlink to point at the profile version
2. Symlinks additional profile-only skills into `~/.claude/skills/`
3. Writes a marker file `~/.claude/.active-profiles` listing the active profile

Agents detect the marker and load profile-specific references.

## Installing a profile

```bash
# From this repo root
./profiles/{name}/install.sh

# Check what's active
cat ~/.claude/.active-profiles

# Revert to generic
./profiles/{name}/uninstall.sh
```

## Available profiles

- **ubiwhere/** — Ubiwhere Urban Platform (GKE + Iceberg/Trino/Dagster + Keycloak/SpiceDB + TanStack Start + schema-renderer)

See each profile's README for detail.
