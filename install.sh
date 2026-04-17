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
#   4. Symlinks each skills/<name>/ directory as-is → ~/.claude/skills/<name>/
#      (preserves SKILL.md + references/ + scripts/ subdirectories)
#   5. Symlinks hooks/{stop,pre-tool}/*.sh → ~/.claude/hooks/{stop,pre-tool}/*.sh
#   6. Symlinks scripts/*.py and scripts/*.sh → ~/.claude/scripts/, chmod +x
#   7. Symlinks templates/ tree → ~/.claude/templates/ preserving structure
#
# What it does NOT do:
#   - Touch ~/.claude/settings.json (hooks config must be merged manually)
#   - Install any profile (use ./profiles/<name>/install.sh after)
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

link_dir() {
  # Symlink an entire directory as-is (preserves internal structure).
  local src="$1"
  local dst="$2"

  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    skip "$dst"
    return 0
  fi

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

# 4. Skills (entire directory per skill — preserves references/ and scripts/)
echo "[Skills]"
for skill_path in "$REPO_DIR"/skills/*/; do
  [ -d "$skill_path" ] || continue
  skill_name="$(basename "$skill_path")"
  # Skip if no SKILL.md inside
  [ -f "$skill_path/SKILL.md" ] || continue
  link_dir "$REPO_DIR/skills/$skill_name" "$CLAUDE_DIR/skills/$skill_name"
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

# 6. Scripts
echo "[Scripts]"
mkdir -p "$CLAUDE_DIR/scripts"
for f in "$REPO_DIR"/scripts/*.py "$REPO_DIR"/scripts/*.sh; do
  [ -f "$f" ] || continue
  link_file "$f" "$CLAUDE_DIR/scripts/$(basename "$f")"
done
# Ensure scripts are executable
for f in "$CLAUDE_DIR"/scripts/*.py "$CLAUDE_DIR"/scripts/*.sh; do
  [ -f "$f" ] && chmod +x "$f" 2>/dev/null || true
done
echo ""

# 7. Templates
echo "[Templates]"
if [ -d "$REPO_DIR/templates" ]; then
  while IFS= read -r -d '' f; do
    rel="${f#"$REPO_DIR/templates/"}"
    link_file "$f" "$CLAUDE_DIR/templates/$rel"
  done < <(find "$REPO_DIR/templates" -type f -print0)
fi
echo ""

# 8. Reminders
echo "=============================="
echo ""
echo "Base symlinks created. Manual steps remain:"
echo ""
echo "  1. HOOKS CONFIG: Merge hooks-config.json into your"
echo "     ~/.claude/settings.json under the 'hooks' key."
echo ""
echo "  2. TOOL DEPENDENCIES:"
echo "     brew install gitleaks jq"
echo "     pip install ruff"
echo "     npm install -g prettier"
echo ""
echo "  3. SCAN TOOLS (optional — for /scan and /orchestrate):"
echo "     pip install semgrep"
echo "     brew install trivy"
echo ""
echo "  4. PROFILE (optional — for stack-specific conventions):"
echo "     ls profiles/                    # list available profiles"
echo "     ./profiles/<name>/install.sh    # overlay a profile"
echo ""
echo "Done."
