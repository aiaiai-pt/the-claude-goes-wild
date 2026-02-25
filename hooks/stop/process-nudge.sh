#!/usr/bin/env bash
# =============================================================================
# PROCESS NUDGE — Probabilistic Stop Hook (Steering Model Awareness)
# Context-aware nudges that remind Claude about Steering Model processes
# it could invoke. Different from general explorational nudges — these
# specifically suggest invoking /qfg, /sfg, /mfg, /xfg, /ofg, /pfg.
#
# Fires less often than explorational nudges (8%) but with more specific,
# actionable suggestions tied to the process architecture.
# =============================================================================
set -euo pipefail

INPUT=$(cat)

# Anti-loop: ALWAYS allow stop on continuation
if [ "$(echo "$INPUT" | jq -r '.stop_hook_active')" = "true" ]; then
  exit 0
fi

LAST_MSG=$(echo "$INPUT" | jq -r '.last_assistant_message // ""')

# --- Probability: 8% base chance ---
ROLL=$((RANDOM % 100))
if [ "$ROLL" -ge 8 ]; then
  exit 0
fi

# --- Context-specific process suggestions ---
# These fire based on what Claude was doing, suggesting relevant processes

NUDGE=""

# Writing code without running mutation tests
if echo "$LAST_MSG" | grep -qiE '(implement|refactor|fix|wrote.*function|added.*method)' && \
   ! echo "$LAST_MSG" | grep -qiE '(mutation|mutant|property.test|qfg)'; then
  NUDGE="Process suggestion: you wrote new code but didn't run /mutation-test. Mutation testing proves your tests actually catch bugs — coverage alone doesn't. Consider running /qfg mutate on the changed code."
fi

# Shipping without checking tracking
if [ -z "$NUDGE" ] && echo "$LAST_MSG" | grep -qiE '(commit|ship|deploy|merge|pr|pull.request)' && \
   ! echo "$LAST_MSG" | grep -qiE '(tracking|event|metric|instrument|mfg)'; then
  NUDGE="Process suggestion: you're about to ship but haven't verified tracking instrumentation. Run /tracking-plan audit to confirm success metric events are firing. You can't measure impact without tracking."
fi

# Adding API endpoints without contract tests
if [ -z "$NUDGE" ] && echo "$LAST_MSG" | grep -qiE '(endpoint|route|api|controller|handler)' && \
   ! echo "$LAST_MSG" | grep -qiE '(contract|pact|openapi|schema)'; then
  NUDGE="Process suggestion: new API endpoints detected but no contract tests. Run /contract-test to generate consumer contracts — they'll catch breaking changes before your consumers do."
fi

# Auth/security-sensitive code without security scan
if [ -z "$NUDGE" ] && echo "$LAST_MSG" | grep -qiE '(auth|password|token|permission|role|admin|encrypt|session|cookie)' && \
   ! echo "$LAST_MSG" | grep -qiE '(security|scan|semgrep|gitleaks|sfg|threat)'; then
  NUDGE="Process suggestion: you're working on security-sensitive code. Consider running /security-scan to catch vulnerabilities early. Auth and session handling code deserves extra scrutiny."
fi

# Performance-sensitive changes without load testing
if [ -z "$NUDGE" ] && echo "$LAST_MSG" | grep -qiE '(database|query|cache|index|batch|bulk|concurrent|parallel)' && \
   ! echo "$LAST_MSG" | grep -qiE '(load.test|performance|benchmark|k6|latency)'; then
  NUDGE="Process suggestion: these changes look performance-sensitive. Consider running /load-test to establish a baseline — you'll want to compare against it after shipping."
fi

# Complex logic without property tests
if [ -z "$NUDGE" ] && echo "$LAST_MSG" | grep -qiE '(algorithm|sort|filter|transform|parse|serialize|calculate|convert)' && \
   ! echo "$LAST_MSG" | grep -qiE '(property|invariant|hypothesis|fast.check|quickcheck)'; then
  NUDGE="Process suggestion: this looks like complex data transformation logic. What must ALWAYS be true about the output regardless of input? That invariant is a property test — run /property-test to find edge cases you'd miss manually."
fi

# Experiment-worthy feature without XFG
if [ -z "$NUDGE" ] && echo "$LAST_MSG" | grep -qiE '(feature|flow|conversion|onboarding|pricing|checkout|signup)' && \
   ! echo "$LAST_MSG" | grep -qiE '(experiment|ab.test|hypothesis|xfg|variant)'; then
  NUDGE="Process suggestion: this feature change could be measured with an experiment. Consider running /xfg hypothesize to frame a testable hypothesis — ship the change behind a feature flag and let data decide."
fi

# No matching context — no nudge
if [ -z "$NUDGE" ]; then
  exit 0
fi

# --- Deliver the nudge ---
echo "[Steering Model Process Nudge]" >&2
echo "" >&2
echo "$NUDGE" >&2
echo "" >&2
echo "This is a process awareness suggestion. Act on it if relevant, or note why it doesn't apply and continue." >&2

exit 2
