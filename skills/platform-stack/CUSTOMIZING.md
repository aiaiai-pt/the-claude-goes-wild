# Customizing the Platform Stack

The `platform-stack` skill is designed to be team-swappable via **profiles**.

## How Profiles Work

A profile is a set of skill overrides that replace the generic `platform-stack`
with team-specific content. Profiles live under `profiles/{name}/` in this repo.

When you run a profile's `install.sh`, it:

1. Swaps the `~/.claude/skills/platform-stack/` symlink to point at the profile's version
2. Adds any profile-only skills (e.g., `platform-grammar` for the Ubiwhere profile)
3. Writes a marker file `~/.claude/.active-profiles` with the profile name

Agents then load the profile's skills instead of the generic shell.

## Using an Existing Profile

```bash
# Install a profile (overlays on top of the generic team config)
./profiles/ubiwhere/install.sh

# Check active profiles
cat ~/.claude/.active-profiles

# Uninstall (revert to generic)
./profiles/ubiwhere/uninstall.sh
```

Only one profile should be active at a time.

## Creating a New Profile

```bash
mkdir -p profiles/my-team/skills/platform-stack/references
cd profiles/my-team
```

Create the skill files:

```
profiles/my-team/
├── README.md                               # what this profile is for
├── install.sh                              # overlay installer
├── uninstall.sh                            # overlay uninstaller
└── skills/
    └── platform-stack/                     # overrides generic
        ├── SKILL.md                        # your canonical stack
        └── references/
            ├── stack-reference.md          # full stack reference
            ├── appetite-stack-map.md       # stack per appetite tier
            └── ...                         # other references
```

Optional: add additional skills your profile needs (like `platform-grammar` for
normative language constraints).

### Minimum `install.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROFILE_DIR="$REPO_DIR/profiles/my-team"
CLAUDE_DIR="$HOME/.claude"

# Swap platform-stack symlink
rm -f "$CLAUDE_DIR/skills/platform-stack"
ln -s "$PROFILE_DIR/skills/platform-stack" "$CLAUDE_DIR/skills/platform-stack"

# Mark profile active
echo "my-team" > "$CLAUDE_DIR/.active-profiles"

echo "✓ Profile 'my-team' installed"
```

## Project-Scoped Override

If a specific project needs a different stack than the team default, create:

```
{project}/.claude/skills/platform-stack/SKILL.md
```

Project-scoped skills win over user-scoped (symlinked) skills within that
project. No profile swap needed — it's an ambient override.

## What NOT to customize

Skills that are **not** stack-specific should stay generic:

- `problem-discovery` (interview framework, appetite calibration)
- `system-architecture` (C4 templates, ADR format)
- `module-specification` (module/feature templates)
- `test-strategy` (test pyramid, quality gate principles)
- `issue-publishing` (tracker scripts, manifest format)
- `dx-reporting` (report templates)
- `architecture-governance` (universal rules)

These live in `the-claude-goes-wild/skills/` and are shared across all profiles.
