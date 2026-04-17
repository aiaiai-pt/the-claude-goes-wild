#!/usr/bin/env bash
# github-publish.sh — Publish issues to GitHub via gh CLI
# Requires: gh auth login
# Input: docs/architect-process/issues/manifest.json

set -euo pipefail

MANIFEST="${1:-docs/architect-process/issues/manifest.json}"

if ! command -v gh &> /dev/null; then
    echo "ERROR: gh CLI not found. Install: https://cli.github.com/"
    exit 1
fi

if ! gh auth status &> /dev/null; then
    echo "ERROR: gh not authenticated. Run: gh auth login"
    exit 1
fi

if [ ! -f "$MANIFEST" ]; then
    echo "ERROR: Manifest not found at $MANIFEST"
    exit 1
fi

REPO=$(gh repo view --json nameWithOwner -q '.nameWithOwner' 2>/dev/null || echo "")
if [ -z "$REPO" ]; then
    echo "ERROR: Not in a GitHub repository. Run from repo root or set GH_REPO."
    exit 1
fi
echo "Publishing to: $REPO"

# Create labels
create_label() {
    local name="$1"
    local color="${2:-6B7280}"
    gh label create "$name" --color "$color" --force 2>/dev/null || true
}

echo "Creating labels..."
create_label "appetite:spike" "FDE68A"
create_label "appetite:small-batch" "86EFAC"
create_label "appetite:big-batch" "7DD3FC"
create_label "appetite:multi-cycle" "C4B5FD"
create_label "type:dev" "D1D5DB"
create_label "type:prototype" "FCA5A5"
create_label "type:mvp" "FBBF24"
create_label "type:prod-mvp" "34D399"
create_label "type:production" "10B981"
create_label "must-have" "EF4444"
create_label "nice-to-have" "9CA3AF"

# Create milestone for the project
PROJECT_NAME=$(jq -r '.project' "$MANIFEST")
echo "Creating milestone: $PROJECT_NAME"
MILESTONE_URL=$(gh api repos/$REPO/milestones -f title="$PROJECT_NAME" -f state=open 2>/dev/null | jq -r '.url // empty')
if [ -z "$MILESTONE_URL" ]; then
    MILESTONE_NUMBER=$(gh api repos/$REPO/milestones --method POST -f title="$PROJECT_NAME" | jq -r '.number')
else
    MILESTONE_NUMBER=$(gh api repos/$REPO/milestones --jq ".[] | select(.title==\"$PROJECT_NAME\") | .number" 2>/dev/null || echo "")
fi

echo "Publishing issues..."

EPIC_COUNT=$(jq '.epics | length' "$MANIFEST")
for i in $(seq 0 $((EPIC_COUNT - 1))); do
    EPIC_TITLE=$(jq -r ".epics[$i].title" "$MANIFEST")
    EPIC_DESC=$(jq -r ".epics[$i].description" "$MANIFEST")
    EPIC_LABELS=$(jq -r ".epics[$i].labels | join(\",\")" "$MANIFEST")

    echo "Creating epic: $EPIC_TITLE"
    EPIC_URL=$(gh issue create --title "$EPIC_TITLE" --body "$EPIC_DESC" \
        --label "$EPIC_LABELS" \
        ${MILESTONE_NUMBER:+--milestone "$MILESTONE_NUMBER"} 2>&1 | tail -1)
    EPIC_NUM=$(echo "$EPIC_URL" | grep -oP '\d+$')
    echo "  → $EPIC_URL"

    FEATURE_COUNT=$(jq ".epics[$i].features | length" "$MANIFEST")
    for j in $(seq 0 $((FEATURE_COUNT - 1))); do
        FEAT_TITLE=$(jq -r ".epics[$i].features[$j].title" "$MANIFEST")
        FEAT_DESC=$(jq -r ".epics[$i].features[$j].description" "$MANIFEST")
        FEAT_LABELS=$(jq -r ".epics[$i].features[$j].labels | join(\",\")" "$MANIFEST")

        # Prepend parent reference
        FEAT_DESC="Parent: #$EPIC_NUM\n\n$FEAT_DESC"

        echo "  Creating feature: $FEAT_TITLE"
        FEAT_URL=$(gh issue create --title "$FEAT_TITLE" --body "$(echo -e "$FEAT_DESC")" \
            --label "$FEAT_LABELS" \
            ${MILESTONE_NUMBER:+--milestone "$MILESTONE_NUMBER"} 2>&1 | tail -1)
        echo "    → $FEAT_URL"
    done
done

echo ""
echo "✓ Published $(jq '[.epics[].features | length] | add' "$MANIFEST") issues to GitHub ($REPO)"
