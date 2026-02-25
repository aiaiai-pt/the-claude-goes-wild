#!/usr/bin/env bash
# =============================================================================
# SECRET SCAN — Mandatory Stop Hook
# Scans for secrets before allowing Claude to stop after code changes.
# Zero tolerance — any secret found blocks the stop.
# =============================================================================
set -euo pipefail

INPUT=$(cat)

# Anti-loop: if stop hook already triggered a continuation, allow stop
if [ "$(echo "$INPUT" | jq -r '.stop_hook_active')" = "true" ]; then
  exit 0
fi

LAST_MSG=$(echo "$INPUT" | jq -r '.last_assistant_message // ""')

# Only scan if Claude was writing code
if ! echo "$LAST_MSG" | grep -qiE '(created|modified|wrote|edit|write|commit)'; then
  exit 0
fi

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"

# Prefer gitleaks, fall back to grep patterns
if command -v gitleaks > /dev/null 2>&1; then
  REPORT=$(mktemp)
  if ! gitleaks detect --source="$PROJECT_DIR" --report-format=json --report-path="$REPORT" --no-git 2>/dev/null; then
    COUNT=$(jq length "$REPORT" 2>/dev/null || echo "unknown")
    FINDINGS=$(jq -r '.[] | "  - \(.File):\(.StartLine) [\(.RuleID)]"' "$REPORT" 2>/dev/null | head -10)
    rm -f "$REPORT"
    echo "SECRETS DETECTED ($COUNT findings). This is Critical severity — zero tolerance." >&2
    echo "$FINDINGS" >&2
    echo "Remove all secrets from code before stopping." >&2
    exit 2
  fi
  rm -f "$REPORT"
else
  # Fallback: simple pattern matching for common secret formats
  # This is less thorough than gitleaks but catches the obvious cases
  PATTERNS=(
    'AKIA[0-9A-Z]{16}'                           # AWS Access Key
    'sk-[a-zA-Z0-9]{20,}'                         # OpenAI/Stripe secret key
    'ghp_[a-zA-Z0-9]{36}'                         # GitHub PAT
    'gho_[a-zA-Z0-9]{36}'                         # GitHub OAuth
    'xox[bps]-[0-9a-zA-Z\-]{10,}'                 # Slack token
    'sk_live_[a-zA-Z0-9]{24,}'                     # Stripe live key
    'pk_live_[a-zA-Z0-9]{24,}'                     # Stripe publishable live
    'AIza[0-9A-Za-z_\-]{35}'                       # Google API key
    '-----BEGIN (RSA |EC )?PRIVATE KEY-----'       # Private key
    'password\s*[:=]\s*["\x27][^\s]{8,}["\x27]'   # Hardcoded password
  )

  FOUND=""
  for PATTERN in "${PATTERNS[@]}"; do
    MATCHES=$(grep -rnE "$PATTERN" "$PROJECT_DIR" \
      --include="*.ts" --include="*.js" --include="*.py" --include="*.go" \
      --include="*.rs" --include="*.java" --include="*.rb" --include="*.env" \
      --include="*.yml" --include="*.yaml" --include="*.json" --include="*.toml" \
      --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=__pycache__ \
      --exclude-dir=target --exclude-dir=dist --exclude-dir=build \
      2>/dev/null | head -5)
    if [ -n "$MATCHES" ]; then
      FOUND="${FOUND}${MATCHES}\n"
    fi
  done

  if [ -n "$FOUND" ]; then
    echo "POTENTIAL SECRETS DETECTED (fallback scan — install gitleaks for thorough scanning):" >&2
    echo -e "$FOUND" >&2
    echo "Remove all secrets from code before stopping. Use environment variables instead." >&2
    exit 2
  fi
fi

exit 0
