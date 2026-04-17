#!/usr/bin/env bash
# =============================================================================
# Ubiwhere Profile — Install
#
# Overlays the Ubiwhere profile on top of the generic team config.
# Replaces ~/.claude/skills/platform-stack/ with the Ubiwhere version and adds
# ~/.claude/skills/platform-grammar/.
#
# Run the base install.sh FIRST before installing this profile.
# =============================================================================
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROFILE_DIR="$REPO_DIR/profiles/ubiwhere"
CLAUDE_DIR="$HOME/.claude"
BACKUP_DIR="$CLAUDE_DIR/.backup/$(date +%Y%m%d-%H%M%S)-ubiwhere-install"

ok()   { echo "  ✓ $1"; }
warn() { echo "  ⚠ $1"; }
log()  { echo "  $1"; }

echo ""
echo "Ubiwhere Profile — Install"
echo "=========================="
echo "Repo:    $REPO_DIR"
echo "Profile: $PROFILE_DIR"
echo "Target:  $CLAUDE_DIR"
echo ""

# Sanity check — base config must be installed
if [ ! -d "$CLAUDE_DIR/skills" ]; then
    echo "ERROR: ~/.claude/skills/ not found. Run the base ./install.sh first."
    exit 1
fi

mkdir -p "$CLAUDE_DIR/skills"

backup_if_exists() {
    local path="$1"
    if [ -e "$path" ] || [ -L "$path" ]; then
        mkdir -p "$BACKUP_DIR"
        mv "$path" "$BACKUP_DIR/$(basename "$path").$(date +%s)"
        log "Backed up $path → $BACKUP_DIR/"
    fi
}

link_tree() {
    local src="$1"
    local dst="$2"
    backup_if_exists "$dst"
    ln -s "$src" "$dst"
    ok "$dst → $src"
}

# 1. Override platform-stack
echo "[Override: platform-stack]"
link_tree "$PROFILE_DIR/skills/platform-stack" "$CLAUDE_DIR/skills/platform-stack"

# 2. Add platform-grammar
echo ""
echo "[Add: platform-grammar]"
link_tree "$PROFILE_DIR/skills/platform-grammar" "$CLAUDE_DIR/skills/platform-grammar"

# 3. Mark profile active
echo ""
echo "[Profile marker]"
echo "ubiwhere" > "$CLAUDE_DIR/.active-profiles"
ok "$CLAUDE_DIR/.active-profiles → ubiwhere"

echo ""
echo "=========================="
echo "✓ Ubiwhere profile installed."
echo ""
echo "Verify:"
echo "  cat ~/.claude/.active-profiles"
echo "  ls -la ~/.claude/skills/platform-stack"
echo "  ls -la ~/.claude/skills/platform-grammar"
echo ""
echo "To revert:"
echo "  ./profiles/ubiwhere/uninstall.sh"
