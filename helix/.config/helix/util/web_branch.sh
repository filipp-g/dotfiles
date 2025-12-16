#!/usr/bin/env bash
# Opens the current file at the current line in GitHub on the default branch

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

DEFAULT_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
if [ -z "$DEFAULT_BRANCH" ]; then
    DEFAULT_BRANCH=$(git remote show origin 2>/dev/null | grep 'HEAD branch' | cut -d' ' -f5)
fi
if [ -z "$DEFAULT_BRANCH" ]; then
    if git show-ref --verify --quiet refs/remotes/origin/main; then
        DEFAULT_BRANCH="main"
    else
        DEFAULT_BRANCH="master"
    fi
fi

GITHUB_URL="${REMOTE_URL}/blob/${DEFAULT_BRANCH}/${REL_PATH}#L${LINE}"

xdg-open "$GITHUB_URL" >/dev/null || open "$GITHUB_URL" 2>/dev/null

# echo "Opening: $GITHUB_URL"
