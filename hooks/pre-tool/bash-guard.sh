#!/usr/bin/env bash
# =============================================================================
# BASH GUARD — PreToolUse Hook for Bash commands
# Prevents dangerous commands from executing without explicit user approval.
# Outputs JSON with permissionDecision to allow/deny/ask.
# =============================================================================
set -euo pipefail

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""')

# --- Always block: destructive commands that are almost never intentional ---

# Force push to main/master
if echo "$COMMAND" | grep -qE 'git\s+push\s+.*--force.*\s+(main|master)'; then
  echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Force push to main/master is blocked. This is almost certainly destructive."}}'
  exit 0
fi

# rm -rf on root-like paths
if echo "$COMMAND" | grep -qE 'rm\s+-rf\s+(/|~/|\$HOME|/usr|/etc|/var)'; then
  echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Recursive delete on system path is blocked."}}'
  exit 0
fi

# Drop database / schema / truncate — prompt for approval (not hard deny)
if echo "$COMMAND" | grep -qiE '(drop\s+database|drop\s+schema|truncate\s+)'; then
  echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"Database destructive command detected (DROP/TRUNCATE). Approve to proceed."}}'
  exit 0
fi

# --- Ask user: commands that might be intentional but are risky ---

# git reset --hard
if echo "$COMMAND" | grep -qE 'git\s+reset\s+--hard'; then
  echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"git reset --hard will discard uncommitted changes. Confirm this is intentional."}}'
  exit 0
fi

# git clean -f
if echo "$COMMAND" | grep -qE 'git\s+clean\s+-[a-zA-Z]*f'; then
  echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"git clean -f will delete untracked files permanently. Confirm this is intentional."}}'
  exit 0
fi

# Force push (non-main branches — less dangerous but still risky)
if echo "$COMMAND" | grep -qE 'git\s+push\s+.*--force'; then
  echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"Force push will overwrite remote history. Confirm this is intentional."}}'
  exit 0
fi

# Kill processes
if echo "$COMMAND" | grep -qE '(kill\s+-9|killall|pkill)'; then
  echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"Process kill command detected. Confirm this is intentional."}}'
  exit 0
fi

# Credential/env file operations
if echo "$COMMAND" | grep -qiE '(\.env|credentials|secrets|\.pem|\.key)\b' | grep -qiE '(cat|echo|cp|mv|rm)'; then
  echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"Operation on potential credential file detected. Confirm this is intentional."}}'
  exit 0
fi

# --- Allow everything else ---
exit 0
