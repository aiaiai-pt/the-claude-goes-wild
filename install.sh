#!/usr/bin/env bash
# =============================================================================
# Claude Team Config — Install Script
#
# Creates symlinks from this repo into ~/.claude/ so team members share
# agents, commands, skills, and hooks while keeping personal settings private.
#
# Usage:
#   ./install.sh          # Interactive — prompts before overwriting
#   ./install.sh --force  # Overwrite existing files without prompting
#
# What it does:
#   1. Symlinks CLAUDE.md → ~/.claude/CLAUDE.md
#   2. Symlinks agents/*.md → ~/.claude/agents/*.md
#   3. Symlinks commands/*.md → ~/.claude/commands/*.md
#   4. Symlinks skills/*/SKILL.md → ~/.claude/skills/*/SKILL.md
#   5. Symlinks hooks/{stop,pre-tool}/*.sh → ~/.claude/hooks/{stop,pre-tool}/*.sh
#
# What it does NOT do:
#   - Touch ~/.claude/settings.json (hooks config must be merged manually)
#   - Overwrite personal settings, history, sessions, or cache
#   - Delete anything — existing files are backed up to ~/.claude/.backup/
# =============================================================================
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
BACKUP_DIR="$CLAUDE_DIR/.backup/$(date +%Y%m%d-%H%M%S)"
FORCE="${1:-}"

log()  { echo "  $1"; }
ok()   { echo "  ✓ $1"; }
warn() { echo "  ⚠ $1"; }
skip() { echo "  - $1 (skipped, already linked)"; }

link_file() {
  local src="$1"
  local dst="$2"

  # Already correctly linked
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    skip "$dst"
    return 0
  fi

  # Existing file — back up first
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    if [ "$FORCE" != "--force" ]; then
      echo -n "  ? $dst exists. Overwrite? [y/N] "
      read -r answer
      if [ "$answer" != "y" ] && [ "$answer" != "Y" ]; then
        warn "Skipped $dst"
        return 0
      fi
    fi
    mkdir -p "$BACKUP_DIR"
    mv "$dst" "$BACKUP_DIR/$(basename "$dst").$(date +%s)"
    log "Backed up → $BACKUP_DIR/"
  fi

  # Create parent directory if needed
  mkdir -p "$(dirname "$dst")"

  ln -s "$src" "$dst"
  ok "$dst → $src"
}

echo ""
echo "Claude Team Config — Install"
echo "=============================="
echo "Repo:   $REPO_DIR"
echo "Target: $CLAUDE_DIR"
echo ""

# Ensure ~/.claude exists
mkdir -p "$CLAUDE_DIR"

# 1. CLAUDE.md
if [ -f "$REPO_DIR/CLAUDE.md" ]; then
  echo "[CLAUDE.md]"
  link_file "$REPO_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
  echo ""
fi

# 2. Agents
echo "[Agents]"
for f in "$REPO_DIR"/agents/*.md; do
  [ -f "$f" ] || continue
  link_file "$f" "$CLAUDE_DIR/agents/$(basename "$f")"
done
echo ""

# 3. Commands
echo "[Commands]"
for f in "$REPO_DIR"/commands/*.md; do
  [ -f "$f" ] || continue
  link_file "$f" "$CLAUDE_DIR/commands/$(basename "$f")"
done
echo ""

# 4. Skills
echo "[Skills]"
for f in "$REPO_DIR"/skills/*/SKILL.md; do
  [ -f "$f" ] || continue
  skill_name="$(basename "$(dirname "$f")")"
  link_file "$f" "$CLAUDE_DIR/skills/$skill_name/SKILL.md"
done
echo ""

# 5. Hooks
echo "[Hooks]"
for hook_type in stop pre-tool; do
  for f in "$REPO_DIR"/hooks/$hook_type/*.sh; do
    [ -f "$f" ] || continue
    link_file "$f" "$CLAUDE_DIR/hooks/$hook_type/$(basename "$f")"
  done
done
echo ""

# 6. Reminder about hooks config
echo "=============================="
echo ""
echo "Symlinks created. Two manual steps remain:"
echo ""
echo "  1. HOOKS CONFIG: Merge hooks-config.json into your"
echo "     ~/.claude/settings.json under the 'hooks' key."
echo "     (Don't replace the whole file — it has your personal settings.)"
echo ""
echo "  2. TOOL DEPENDENCIES: Install the tools the hooks expect:"
echo "     brew install gitleaks jq"
echo "     pip install ruff  (or: pipx install ruff)"
echo "     npm install -g prettier"
echo ""
echo "Done."
