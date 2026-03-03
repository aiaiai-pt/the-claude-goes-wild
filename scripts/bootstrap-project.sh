#!/usr/bin/env bash
# =============================================================================
# bootstrap-project.sh
# --------------------
# One-time per-project scaffolding for the multi-agent orchestration system.
# Creates .agent-memory/, .agent-handoffs/, spec/, and .env.example.
#
# Usage:
#   bash ~/.claude/scripts/bootstrap-project.sh
#   bash scripts/bootstrap-project.sh
#
# Safe to re-run — will not overwrite existing files.
# =============================================================================
set -euo pipefail

TEMPLATES_DIR="${CLAUDE_TEMPLATES_DIR:-$HOME/.claude/templates/agent-memory}"

echo ""
echo "Agent Orchestration — Project Bootstrap"
echo "========================================"
echo ""

# ── Directories ──────────────────────────────────────────────────────────────
echo "[Directories]"
for dir in \
  .agent-memory/security \
  .agent-memory/engineering \
  .agent-memory/product \
  .agent-memory/meta \
  .agent-handoffs \
  spec; do
  mkdir -p "$dir"
  echo "  + $dir/"
done
echo ""

# ── Memory files from templates ──────────────────────────────────────────────
echo "[Memory Files]"
if [ -d "$TEMPLATES_DIR" ]; then
  # Copy from templates, preserving directory structure
  while IFS= read -r -d '' src; do
    rel="${src#"$TEMPLATES_DIR"/}"
    dst=".agent-memory/$rel"
    if [ ! -f "$dst" ]; then
      mkdir -p "$(dirname "$dst")"
      cp "$src" "$dst"
      echo "  created $dst (from template)"
    else
      echo "  skipped $dst (exists)"
    fi
  done < <(find "$TEMPLATES_DIR" -type f -name '*.md' -print0)
else
  echo "  Templates not found at $TEMPLATES_DIR"
  echo "  Creating memory files with defaults..."
  for f in \
    .agent-memory/security/cves.md \
    .agent-memory/security/patterns.md \
    .agent-memory/security/suppressions.md \
    .agent-memory/engineering/bugs.md \
    .agent-memory/engineering/patterns.md \
    .agent-memory/engineering/dependencies.md \
    .agent-memory/product/spec-gaps.md \
    .agent-memory/product/scope-creep.md \
    .agent-memory/meta/index.md \
    .agent-memory/meta/consolidation-log.md; do
    if [ ! -f "$f" ]; then
      title=$(basename "$f" .md | tr '-' ' ' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2); print}')
      printf "# %s\n\n<!-- Entries appended by agents. See README.md for format. -->\n" "$title" > "$f"
      echo "  created $f"
    else
      echo "  skipped $f (exists)"
    fi
  done
fi
echo ""

# ── .gitignore ───────────────────────────────────────────────────────────────
echo "[.gitignore]"
touch .gitignore
for entry in ".agent-handoffs/" ".env"; do
  if ! grep -qxF "$entry" .gitignore 2>/dev/null; then
    echo "$entry" >> .gitignore
    echo "  added $entry"
  else
    echo "  skipped $entry (already present)"
  fi
done
echo ""

# ── spec placeholder ─────────────────────────────────────────────────────────
echo "[Spec]"
if [ ! -f spec/requirements.md ]; then
  cat > spec/requirements.md << 'SPEC'
# Requirements

<!-- Define acceptance criteria here. The orchestration pipeline uses this
     file as the source of truth for the spec review gate. -->
SPEC
  echo "  created spec/requirements.md"
else
  echo "  skipped spec/requirements.md (exists)"
fi
echo ""

# ── .env.example ─────────────────────────────────────────────────────────────
echo "[.env.example]"
if [ ! -f .env.example ]; then
  cat > .env.example << 'ENV'
# Copy to .env and fill in values. Never commit .env.

# SonarQube (optional — only needed for --sonar flag)
SONAR_TOKEN=sqp_xxxxxxxxxxxxxxxxxxxx
SONAR_PROJECT_KEY=your-project-key
SONAR_HOST=https://your-sonarqube-instance.example.com
ENV
  echo "  created .env.example"
else
  echo "  skipped .env.example (exists)"
fi

echo ""
echo "========================================"
echo "Done. Next steps:"
echo "  1. cp .env.example .env && fill in your tokens (if using SonarQube)"
echo "  2. Populate spec/requirements.md with acceptance criteria"
echo "  3. Run /scan to verify scanning tools work"
echo "  4. Run /orchestrate to start a full pipeline"
echo ""
