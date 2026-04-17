#!/usr/bin/env bash
# =============================================================================
# Ubiwhere Profile — Uninstall
#
# Restores the generic platform-stack shell and removes platform-grammar.
# =============================================================================
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CLAUDE_DIR="$HOME/.claude"

ok()   { echo "  ✓ $1"; }

echo ""
echo "Ubiwhere Profile — Uninstall"
echo "============================"
echo ""

# 1. Remove platform-grammar
if [ -L "$CLAUDE_DIR/skills/platform-grammar" ] || [ -d "$CLAUDE_DIR/skills/platform-grammar" ]; then
    rm -rf "$CLAUDE_DIR/skills/platform-grammar"
    ok "Removed ~/.claude/skills/platform-grammar"
fi

# 2. Restore generic platform-stack
if [ -L "$CLAUDE_DIR/skills/platform-stack" ] || [ -e "$CLAUDE_DIR/skills/platform-stack" ]; then
    rm -rf "$CLAUDE_DIR/skills/platform-stack"
fi
if [ -d "$REPO_DIR/skills/platform-stack" ]; then
    ln -s "$REPO_DIR/skills/platform-stack" "$CLAUDE_DIR/skills/platform-stack"
    ok "Restored generic ~/.claude/skills/platform-stack"
else
    echo "  ⚠ Generic skills/platform-stack not found at $REPO_DIR/skills/platform-stack"
    echo "     Run ./install.sh from repo root to restore."
fi

# 3. Clear profile marker
if [ -f "$CLAUDE_DIR/.active-profiles" ]; then
    rm -f "$CLAUDE_DIR/.active-profiles"
    ok "Cleared ~/.claude/.active-profiles"
fi

echo ""
echo "✓ Ubiwhere profile uninstalled."
