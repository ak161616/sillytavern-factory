#!/bin/sh
set -e
echo "--- [Launcher V5] Starting... ---"
cd /app
if [ ! -f "/app/config.yaml" ]; then
    echo "CRITICAL: config.yaml not found. Check ConfigMap!"
    exit 1
fi
if [ -n "$REPO_URL" ] && [ -n "$GITHUB_TOKEN" ]; then
    echo "--- [Cloud Save] Initializing... ---"
    DATA_DIR="/app/data"
    mkdir -p "$DATA_DIR"
    cd "$DATA_DIR"
    if [ ! -d ".git" ]; then git init; fi
    git config --global user.name "SillyTavern Backup"
    git config --global user.email "backup@claw.cloud"
    git remote set-url origin "https://oauth2:${GITHUB_TOKEN}@$(echo $REPO_URL | sed -e 's/https?:\/\///')"
    if git ls-remote --exit-code --heads origin main > /dev/null 2>&1; then
        git fetch origin main && git reset --hard origin/main
    fi
    (
        while true; do
            sleep "$((${AUTOSAVE_INTERVAL:-30} * 60))"
            cd "$DATA_DIR" && git add .
            if ! git diff --cached --quiet; then
                git commit -m "Cloud Backup: $(date)" && git push -f origin HEAD:main
            fi
        done
    ) &
    cd /app
fi
echo "--- [Launcher V5] Starting Server... ---"
exec node server.js
