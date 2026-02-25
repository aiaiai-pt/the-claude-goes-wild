#!/usr/bin/env bash
# =============================================================================
# COMMIT GUARD — PreToolUse Hook for git commit commands
# Ensures basic hygiene before any commit: no secrets, no .env files staged.
# Lighter than the full Stop hook — runs only on commit attempts.
# =============================================================================
set -euo pipefail

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""')

# Only activate on git commit commands
if ! echo "$COMMAND" | grep -qE 'git\s+commit'; then
  exit 0
fi

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
ERRORS=""

# Check for .env files in staging area
STAGED_ENV=$(cd "$PROJECT_DIR" && git diff --cached --name-only 2>/dev/null | grep -E '\.env($|\.)' || true)
if [ -n "$STAGED_ENV" ]; then
  ERRORS="${ERRORS}Staged .env file(s) detected: $STAGED_ENV. Remove from staging.\n"
fi

# Check for common credential file patterns in staging
STAGED_CREDS=$(cd "$PROJECT_DIR" && git diff --cached --name-only 2>/dev/null | grep -iE '(credentials|secrets|\.pem|\.key|\.p12|\.pfx|id_rsa)' || true)
if [ -n "$STAGED_CREDS" ]; then
  ERRORS="${ERRORS}Staged credential file(s) detected: $STAGED_CREDS. Verify this is intentional.\n"
fi

# Quick secret pattern check on staged diff
STAGED_DIFF=$(cd "$PROJECT_DIR" && git diff --cached 2>/dev/null || true)
if echo "$STAGED_DIFF" | grep -qE 'AKIA[0-9A-Z]{16}'; then
  ERRORS="${ERRORS}AWS Access Key pattern found in staged changes.\n"
fi
if echo "$STAGED_DIFF" | grep -qE 'sk-[a-zA-Z0-9]{20,}'; then
  ERRORS="${ERRORS}API secret key pattern (sk-*) found in staged changes.\n"
fi
if echo "$STAGED_DIFF" | grep -qE '-----BEGIN (RSA |EC )?PRIVATE KEY-----'; then
  ERRORS="${ERRORS}Private key found in staged changes.\n"
fi

if [ -n "$ERRORS" ]; then
  cat <<EOF
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Commit blocked — security issue:\n${ERRORS}Remove sensitive data before committing."}}
EOF
  exit 0
fi

# Allow the commit
exit 0
