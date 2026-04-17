#!/usr/bin/env bash
# gitlab-publish.sh — Publish issues to GitLab via glab CLI or API
# Requires: glab auth login OR GITLAB_TOKEN + GITLAB_PROJECT env vars
# Optional: GITLAB_HOST (default: https://gitlab.com)
# Input: docs/architect-process/issues/manifest.json

set -euo pipefail

MANIFEST="${1:-docs/architect-process/issues/manifest.json}"

if [ ! -f "$MANIFEST" ]; then
    echo "ERROR: Manifest not found at $MANIFEST"
    exit 1
fi

# Check for glab CLI
if command -v glab &> /dev/null; then
    USE_GLAB=true
    echo "Using glab CLI"
else
    USE_GLAB=false
    if [ -z "${GITLAB_TOKEN:-}" ] || [ -z "${GITLAB_PROJECT:-}" ]; then
        echo "ERROR: glab not found. Set GITLAB_TOKEN and GITLAB_PROJECT (e.g., 'group/project')"
        exit 1
    fi
    GITLAB_API="${GITLAB_HOST:-https://gitlab.com}/api/v4"
    PROJECT_ENCODED=$(echo "$GITLAB_PROJECT" | sed 's/\//%2F/g')
    echo "Using GitLab API: $GITLAB_API"
fi

# Create a label
create_label() {
    local name="$1"
    local color="${2:-#6B7280}"
    if $USE_GLAB; then
        glab label create "$name" --color "$color" 2>/dev/null || true
    else
        curl -s -X POST "$GITLAB_API/projects/$PROJECT_ENCODED/labels" \
            -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
            -d "name=$name&color=$color" 2>/dev/null || true
    fi
}

# Create issue
create_issue() {
    local title="$1"
    local description="$2"
    local labels="$3"

    if $USE_GLAB; then
        glab issue create --title "$title" --description "$description" --label "$labels" --no-editor 2>&1 | grep -oP 'https://\S+'
    else
        curl -s -X POST "$GITLAB_API/projects/$PROJECT_ENCODED/issues" \
            -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
            -H "Content-Type: application/json" \
            -d "{\"title\": \"$title\", \"description\": $(echo "$description" | jq -Rs .), \"labels\": \"$labels\"}" \
            | jq -r '.web_url'
    fi
}

# Relate two issues
relate_issues() {
    local source_iid="$1"
    local target_iid="$2"
    if $USE_GLAB; then
        glab issue note "$source_iid" --message "/relate #$target_iid" 2>/dev/null || true
    else
        curl -s -X POST "$GITLAB_API/projects/$PROJECT_ENCODED/issues/$source_iid/links" \
            -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
            -d "target_project_id=$PROJECT_ENCODED&target_issue_iid=$target_iid" 2>/dev/null || true
    fi
}

echo "Creating labels..."
for label in "appetite:spike" "appetite:small-batch" "appetite:big-batch" "appetite:multi-cycle" \
             "type:dev" "type:prototype" "type:mvp" "type:prod-mvp" "type:production" \
             "must-have" "nice-to-have"; do
    create_label "$label"
done

echo "Publishing issues from manifest..."

EPIC_COUNT=$(jq '.epics | length' "$MANIFEST")
ISSUE_URLS=""

for i in $(seq 0 $((EPIC_COUNT - 1))); do
    EPIC_TITLE=$(jq -r ".epics[$i].title" "$MANIFEST")
    EPIC_DESC=$(jq -r ".epics[$i].description" "$MANIFEST")
    EPIC_LABELS=$(jq -r ".epics[$i].labels | join(\",\")" "$MANIFEST")

    echo "Creating epic: $EPIC_TITLE"
    EPIC_URL=$(create_issue "$EPIC_TITLE" "$EPIC_DESC" "$EPIC_LABELS")
    echo "  → $EPIC_URL"

    FEATURE_COUNT=$(jq ".epics[$i].features | length" "$MANIFEST")
    for j in $(seq 0 $((FEATURE_COUNT - 1))); do
        FEAT_TITLE=$(jq -r ".epics[$i].features[$j].title" "$MANIFEST")
        FEAT_DESC=$(jq -r ".epics[$i].features[$j].description" "$MANIFEST")
        FEAT_LABELS=$(jq -r ".epics[$i].features[$j].labels | join(\",\")" "$MANIFEST")

        # Append parent epic reference to description
        FEAT_DESC="Parent: $EPIC_URL\n\n$FEAT_DESC"

        echo "  Creating feature: $FEAT_TITLE"
        FEAT_URL=$(create_issue "$FEAT_TITLE" "$FEAT_DESC" "$FEAT_LABELS")
        echo "    → $FEAT_URL"
    done
done

echo ""
echo "✓ Published $(jq '[.epics[].features | length] | add' "$MANIFEST") issues to GitLab"
