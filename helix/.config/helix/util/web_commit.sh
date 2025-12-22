#!/usr/bin/env bash
# Opens the current file at the current line in GitHub on the current commit

FILE="$1"
LINE="$2"

GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
if [ $? -ne 0 ]; then
    echo "Error: Not in a git repository"
    exit 1
fi

REL_PATH=$(realpath --relative-to="$GIT_ROOT" "$FILE")

REMOTE_URL=$(git config --get remote.origin.url)
if [ -z "$REMOTE_URL" ]; then
    echo "Error: No remote origin found"
    exit 1
fi

if [[ "$REMOTE_URL" =~ ^git@ ]]; then
    REMOTE_URL=$(echo "$REMOTE_URL" | sed -e 's/:/\//' -e 's/^git@/https:\/\//' -e 's/\.git$//')
fi

REMOTE_URL="${REMOTE_URL%.git}"

BLAME_OUTPUT=$(git blame -L ${LINE},${LINE} --porcelain "$FILE")
COMMIT_SHA=$(echo "$BLAME_OUTPUT" | head -n 1 | awk '{print $1}')
ORIGINAL_LINE=$(echo "$BLAME_OUTPUT" | head -n 1 | awk '{print $2}')

GITHUB_URL="${REMOTE_URL}/blob/${COMMIT_SHA}/${REL_PATH}#L${ORIGINAL_LINE}"

xdg-open "$GITHUB_URL" >/dev/null || open "$GITHUB_URL" 2>/dev/null

# echo "Opening: $GITHUB_URL"
