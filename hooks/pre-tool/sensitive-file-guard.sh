#!/usr/bin/env bash
# =============================================================================
# SENSITIVE FILE GUARD — PreToolUse Hook for Read tool
# Blocks reads of credential files, private keys, and secrets.
# Defense-in-depth: permissions.deny is unreliable, so this hook enforces it.
# =============================================================================
set -euo pipefail

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')

# Nothing to check if no file path
[ -z "$FILE_PATH" ] && exit 0

BASENAME=$(basename "$FILE_PATH")

# --- Block: sensitive file patterns ---

# .env files (.env, .env.local, .env.production, etc.)
if echo "$BASENAME" | grep -qE '^\.env($|\.)'; then
  echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Reading .env files is blocked — they may contain secrets."}}'
  exit 0
fi

# Private keys and certificates
if echo "$BASENAME" | grep -qE '\.(pem|key|p12|pfx)$'; then
  echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Reading private key/certificate files is blocked."}}'
  exit 0
fi

# Known credential filenames
if echo "$BASENAME" | grep -qE '^(credentials\.json|secrets\.json|id_rsa|id_ed25519)$'; then
  echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Reading known credential files is blocked."}}'
  exit 0
fi

# --- Allow everything else ---
exit 0
