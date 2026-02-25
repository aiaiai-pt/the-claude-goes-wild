#!/usr/bin/env bash
# =============================================================================
# QUALITY GATE — Mandatory Stop Hook
# Runs tests, lint, and typecheck before allowing Claude to stop.
# Exit 0 = allow stop, Exit 2 = block stop (stderr fed to Claude)
# =============================================================================
set -euo pipefail

INPUT=$(cat)

# Anti-loop: if stop hook already triggered a continuation, allow stop
if [ "$(echo "$INPUT" | jq -r '.stop_hook_active')" = "true" ]; then
  exit 0
fi

LAST_MSG=$(echo "$INPUT" | jq -r '.last_assistant_message // ""')

# Only run quality gates if Claude was writing code (not just researching/explaining)
# Check if the last message mentions commits, implementations, or code changes
if ! echo "$LAST_MSG" | grep -qiE '(commit|implement|created|modified|wrote|added|fixed|updated|refactor|edit|write).*\.(ts|js|py|rs|go|java|rb|svelte|vue|jsx|tsx|css|html)'; then
  exit 0
fi

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
ERRORS=""

# --- Detect project type and run appropriate checks ---

# Node.js projects
if [ -f "$PROJECT_DIR/package.json" ]; then
  # Test
  if jq -e '.scripts.test' "$PROJECT_DIR/package.json" > /dev/null 2>&1; then
    if ! npm test --prefix "$PROJECT_DIR" --silent 2>/dev/null; then
      ERRORS="${ERRORS}Tests are failing. Fix before stopping.\n"
    fi
  fi

  # Lint
  if jq -e '.scripts.lint' "$PROJECT_DIR/package.json" > /dev/null 2>&1; then
    if ! npm run lint --prefix "$PROJECT_DIR" --silent 2>/dev/null; then
      ERRORS="${ERRORS}Lint errors found. Fix before stopping.\n"
    fi
  fi

  # Typecheck
  if jq -e '.scripts.typecheck' "$PROJECT_DIR/package.json" > /dev/null 2>&1; then
    if ! npm run typecheck --prefix "$PROJECT_DIR" --silent 2>/dev/null; then
      ERRORS="${ERRORS}Type errors found. Fix before stopping.\n"
    fi
  elif [ -f "$PROJECT_DIR/tsconfig.json" ]; then
    if command -v npx > /dev/null 2>&1; then
      if ! npx tsc --noEmit --project "$PROJECT_DIR" 2>/dev/null; then
        ERRORS="${ERRORS}TypeScript errors found. Fix before stopping.\n"
      fi
    fi
  fi
fi

# Python projects
if [ -f "$PROJECT_DIR/pyproject.toml" ] || [ -f "$PROJECT_DIR/setup.py" ] || [ -f "$PROJECT_DIR/setup.cfg" ]; then
  # Test
  if command -v pytest > /dev/null 2>&1; then
    if ! pytest "$PROJECT_DIR" --tb=line -q 2>/dev/null; then
      ERRORS="${ERRORS}Tests are failing (pytest). Fix before stopping.\n"
    fi
  fi

  # Lint
  if command -v ruff > /dev/null 2>&1; then
    if ! ruff check "$PROJECT_DIR" --quiet 2>/dev/null; then
      ERRORS="${ERRORS}Lint errors found (ruff). Fix before stopping.\n"
    fi
  fi

  # Typecheck
  if command -v mypy > /dev/null 2>&1; then
    if ! mypy "$PROJECT_DIR" --no-error-summary 2>/dev/null; then
      ERRORS="${ERRORS}Type errors found (mypy). Fix before stopping.\n"
    fi
  fi
fi

# Rust projects
if [ -f "$PROJECT_DIR/Cargo.toml" ]; then
  if command -v cargo > /dev/null 2>&1; then
    if ! cargo test --manifest-path "$PROJECT_DIR/Cargo.toml" --quiet 2>/dev/null; then
      ERRORS="${ERRORS}Tests are failing (cargo test). Fix before stopping.\n"
    fi
    if ! cargo clippy --manifest-path "$PROJECT_DIR/Cargo.toml" --quiet 2>/dev/null; then
      ERRORS="${ERRORS}Clippy warnings found. Fix before stopping.\n"
    fi
  fi
fi

# Go projects
if [ -f "$PROJECT_DIR/go.mod" ]; then
  if command -v go > /dev/null 2>&1; then
    if ! (cd "$PROJECT_DIR" && go test ./... 2>/dev/null); then
      ERRORS="${ERRORS}Tests are failing (go test). Fix before stopping.\n"
    fi
    if ! (cd "$PROJECT_DIR" && go vet ./... 2>/dev/null); then
      ERRORS="${ERRORS}Go vet issues found. Fix before stopping.\n"
    fi
  fi
fi

# If any errors, block the stop
if [ -n "$ERRORS" ]; then
  echo -e "$ERRORS" >&2
  exit 2
fi

exit 0
