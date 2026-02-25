#!/usr/bin/env bash
# =============================================================================
# EXPLORATIONAL NUDGE — Probabilistic Stop Hook
# Occasionally prompts Claude with a contextual nudge to consider something
# it might have missed. NOT a quality gate — a creative catalyst.
#
# Design principles:
#   - Never blocks critical work (checks stop_hook_active)
#   - Probability-based: doesn't fire every time (avoids annoyance)
#   - Context-aware: different nudges for different activities
#   - Escalating probability: more likely in long sessions
#   - All nudges are SUGGESTIONS, not requirements
# =============================================================================
set -euo pipefail

INPUT=$(cat)

# Anti-loop: ALWAYS allow stop on continuation — nudges are one-shot
if [ "$(echo "$INPUT" | jq -r '.stop_hook_active')" = "true" ]; then
  exit 0
fi

LAST_MSG=$(echo "$INPUT" | jq -r '.last_assistant_message // ""')

# --- Configuration ---
BASE_PROBABILITY=12  # 12% base chance of firing (1 in ~8 stops)

# --- Probability roll ---
ROLL=$((RANDOM % 100))
if [ "$ROLL" -ge "$BASE_PROBABILITY" ]; then
  exit 0  # No nudge this time
fi

# --- Context detection ---
# Classify what Claude was doing based on the last message
ACTIVITY="general"

if echo "$LAST_MSG" | grep -qiE '(implement|code|function|class|component|module|refactor|fix|bug)'; then
  ACTIVITY="coding"
elif echo "$LAST_MSG" | grep -qiE '(test|spec|assert|expect|describe|it\()'; then
  ACTIVITY="testing"
elif echo "$LAST_MSG" | grep -qiE '(design|layout|screen|ui|ux|component|style|token|font|color)'; then
  ACTIVITY="design"
elif echo "$LAST_MSG" | grep -qiE '(plan|spec|architecture|approach|strategy|trade.?off)'; then
  ACTIVITY="planning"
elif echo "$LAST_MSG" | grep -qiE '(deploy|ship|release|rollout|canary|production)'; then
  ACTIVITY="shipping"
elif echo "$LAST_MSG" | grep -qiE '(debug|error|fail|broken|issue|investigate|trace)'; then
  ACTIVITY="debugging"
elif echo "$LAST_MSG" | grep -qiE '(research|explore|search|read|understand|analyze)'; then
  ACTIVITY="researching"
fi

# --- Nudge pools by activity ---
# Each pool has nudges relevant to the current activity.
# Nudges are constructive questions, not commands.

declare -a CODING_NUDGES=(
  "Before finishing: is there a simpler way to express this? The best code is the code you don't write."
  "Quick check: if someone broke this function tomorrow, would any test notice? If not, consider what assertion would catch the most likely bug."
  "Pause — does a similar pattern already exist in this codebase? Check solution docs and existing code before adding new abstractions."
  "Consider: what invariant must always be true here, regardless of input? That's a property test waiting to be written."
  "One more thought: what happens at the boundaries? Empty input, null, maximum size, concurrent access. Pick the scariest one and add a test."
  "Reflection: you've been building — but is the approach still the simplest? Sometimes a step back reveals a shortcut."
  "Quick thought: could this code be understood by someone seeing it for the first time, without your context? If not, a comment on the WHY (not the what) might help."
  "Consider the failure mode: when this code fails (and it will), what does the error message tell the person debugging it at 2am?"
)

declare -a TESTING_NUDGES=(
  "Challenge: would this test still pass if the implementation was a no-op? If yes, it's testing nothing real."
  "Think about it: you're testing the happy path. What's the most likely way a future developer will accidentally break this?"
  "Consider: is this test asserting on observable outcomes (data state, API response, side effects), or just checking return values? The former catches real bugs."
  "Quick audit: are you mocking too much? Every mock is a lie about the system. Could this test use a real implementation instead?"
  "Nudge: what's the strangest valid input for this function? Feed it in and see what happens — that's where bugs hide."
)

declare -a DESIGN_NUDGES=(
  "State check: you've designed the happy path. But what does empty state look like? Error state? Loading? Overflow with 10,000 items?"
  "Accessibility pause: can this be navigated with a keyboard? Does the contrast pass WCAG AA? Are interactive elements at least 44x44px?"
  "Content stress test: what happens when the user's name is 'Bartholomew Featherstonehaugh III'? When the description is 3 paragraphs? When the list is empty?"
  "Hierarchy check: squint at this screen. Can you instantly tell what's most important? If everything looks the same weight, nothing has priority."
  "Motion question: does every animation serve a purpose (orientation, feedback, continuity)? Or is something moving just because it can?"
  "Distinctiveness check: if you screenshot this and post it, would anyone recognize which product it's from? Or does it look like every other SaaS?"
)

declare -a PLANNING_NUDGES=(
  "Scope check: you're planning a lot. What's the smallest version that would be useful? Ship that first."
  "Risk question: what's the one thing in this plan that you're least sure about? That's the spike worth running before committing."
  "Inversion: instead of planning what to build, ask what you should definitely NOT build. The out-of-scope list is as important as the scope."
  "Reality check: is this plan shaped by what's easy to build, or by what the user actually needs? Those aren't always the same thing."
  "Appetite guard: could this plan fit in half the time if you cut one scope? Which scope would you cut? That answer reveals priorities."
)

declare -a SHIPPING_NUDGES=(
  "Safety check: is there a rollback plan? What happens if this deploy goes wrong at 100% traffic?"
  "Measurement check: will you be able to tell if this change helped? Are the success metrics instrumented?"
  "Guardrail check: what should NOT change when this ships? Error rate, latency, conversion — pick one and set a threshold."
  "Feature flag check: is this behind a flag? Progressive delivery means being able to turn it off without a deploy."
)

declare -a DEBUGGING_NUDGES=(
  "Step back: you've been debugging for a while. Are you solving the right problem, or have you gone down a rabbit hole?"
  "Assumption check: what's one thing you're assuming is correct that you haven't actually verified? Start there."
  "Fresh eyes: explain the bug to yourself in one sentence. If you can't, you might not understand it yet."
  "Pattern recognition: have you seen this kind of bug before? Check incident reports and past fixes for similar symptoms."
)

declare -a RESEARCHING_NUDGES=(
  "Synthesis check: you've been reading a lot. Can you summarize the key finding in one sentence? If not, keep digging."
  "Action bias: research is valuable but can become procrastination. Do you have enough information to make a decision?"
  "Source quality: are you learning from the right sources? Official docs > blog posts > Stack Overflow > AI-generated content."
)

declare -a GENERAL_NUDGES=(
  "Meta-check: are you making progress or going in circles? If the same approach has failed twice, try a fundamentally different angle."
  "Simplicity audit: look at what you've built. Can you remove anything without losing functionality? Less is usually more."
  "Knowledge capture: did you learn something during this work that future-you would want to know? Consider updating solution docs or CLAUDE.md."
  "Second opinion: sometimes fresh eyes catch what familiarity misses. Consider if a /review or /design-critique would add value here."
)

# --- Select nudge pool based on activity ---
case "$ACTIVITY" in
  coding)      POOL=("${CODING_NUDGES[@]}") ;;
  testing)     POOL=("${TESTING_NUDGES[@]}") ;;
  design)      POOL=("${DESIGN_NUDGES[@]}") ;;
  planning)    POOL=("${PLANNING_NUDGES[@]}") ;;
  shipping)    POOL=("${SHIPPING_NUDGES[@]}") ;;
  debugging)   POOL=("${DEBUGGING_NUDGES[@]}") ;;
  researching) POOL=("${RESEARCHING_NUDGES[@]}") ;;
  *)           POOL=("${GENERAL_NUDGES[@]}") ;;
esac

# --- Pick a random nudge from the pool ---
INDEX=$((RANDOM % ${#POOL[@]}))
NUDGE="${POOL[$INDEX]}"

# --- Deliver the nudge ---
# Exit 2 forces Claude to consider the nudge before stopping.
# The nudge is a SUGGESTION — Claude should address it briefly or dismiss with reasoning.
echo "[Explorational Nudge — $ACTIVITY context]" >&2
echo "" >&2
echo "$NUDGE" >&2
echo "" >&2
echo "This is a suggestion, not a requirement. Address it briefly or explain why it doesn't apply, then continue." >&2

exit 2
