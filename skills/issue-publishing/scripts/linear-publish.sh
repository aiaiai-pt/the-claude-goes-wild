#!/usr/bin/env bash
# linear-publish.sh — Publish issues to Linear via GraphQL API
# Requires: LINEAR_API_KEY environment variable
# Input: docs/architect-process/issues/manifest.json

set -euo pipefail

MANIFEST="${1:-docs/architect-process/issues/manifest.json}"
API_URL="https://api.linear.app/graphql"

if [ -z "${LINEAR_API_KEY:-}" ]; then
    echo "ERROR: LINEAR_API_KEY not set. Get one from Linear Settings > API."
    exit 1
fi

if [ ! -f "$MANIFEST" ]; then
    echo "ERROR: Manifest not found at $MANIFEST"
    exit 1
fi

# Helper: GraphQL query
gql() {
    curl -s -X POST "$API_URL" \
        -H "Content-Type: application/json" \
        -H "Authorization: $LINEAR_API_KEY" \
        -d "$1"
}

# Get team ID (first team by default)
echo "Fetching Linear team..."
TEAM_ID=$(gql '{"query":"{ teams { nodes { id name } } }"}' | jq -r '.data.teams.nodes[0].id')
echo "Using team: $TEAM_ID"

# Create labels if they don't exist
create_label() {
    local name="$1"
    local color="${2:-#6B7280}"
    gql "{\"query\":\"mutation { issueLabelCreate(input: { name: \\\"$name\\\", teamId: \\\"$TEAM_ID\\\", color: \\\"$color\\\" }) { success issueLabel { id } } }\"}" | jq -r '.data.issueLabelCreate.issueLabel.id // empty'
}

# Create issue
create_issue() {
    local title="$1"
    local description="$2"
    local parent_id="${3:-}"

    local parent_clause=""
    if [ -n "$parent_id" ]; then
        parent_clause=", parentId: \\\"$parent_id\\\""
    fi

    local query="{\"query\":\"mutation { issueCreate(input: { title: \\\"$title\\\", description: \\\"$(echo "$description" | sed 's/"/\\"/g' | tr '\n' ' ')\\\", teamId: \\\"$TEAM_ID\\\"$parent_clause }) { success issue { id identifier url } } }\"}"

    gql "$query"
}

echo "Publishing issues from manifest..."

# Process epics
EPIC_COUNT=$(jq '.epics | length' "$MANIFEST")
for i in $(seq 0 $((EPIC_COUNT - 1))); do
    EPIC_TITLE=$(jq -r ".epics[$i].title" "$MANIFEST")
    EPIC_DESC=$(jq -r ".epics[$i].description" "$MANIFEST")

    echo "Creating epic: $EPIC_TITLE"
    EPIC_RESULT=$(create_issue "$EPIC_TITLE" "$EPIC_DESC")
    EPIC_ID=$(echo "$EPIC_RESULT" | jq -r '.data.issueCreate.issue.id')
    EPIC_URL=$(echo "$EPIC_RESULT" | jq -r '.data.issueCreate.issue.url')
    echo "  → $EPIC_URL"

    # Process features within epic
    FEATURE_COUNT=$(jq ".epics[$i].features | length" "$MANIFEST")
    for j in $(seq 0 $((FEATURE_COUNT - 1))); do
        FEAT_TITLE=$(jq -r ".epics[$i].features[$j].title" "$MANIFEST")
        FEAT_DESC=$(jq -r ".epics[$i].features[$j].description" "$MANIFEST")

        echo "  Creating feature: $FEAT_TITLE"
        FEAT_RESULT=$(create_issue "$FEAT_TITLE" "$FEAT_DESC" "$EPIC_ID")
        FEAT_URL=$(echo "$FEAT_RESULT" | jq -r '.data.issueCreate.issue.url')
        echo "    → $FEAT_URL"
    done
done

echo ""
echo "✓ Published $(jq '[.epics[].features | length] | add' "$MANIFEST") issues to Linear"
