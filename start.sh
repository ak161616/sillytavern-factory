#!/bin/sh
# 黄金最终版启动脚本 (V8 - URL 修正版)
set -e

echo "--- [Launcher V8] Starting..."
cd /app

# 验证 ConfigMap
if [ ! -f "/app/config.yaml" ]; then
    echo "CRITICAL: config.yaml not found!"
    exit 1
fi

# 配置云存档
if [ -n "$REPO_URL" ] && [ -n "$GITHUB_TOKEN" ]; then
    echo "--- [Cloud Save] Initializing..."
    DATA_DIR="/app/data"
    mkdir -p "$DATA_DIR"
    cd "$DATA_DIR"

    if [ ! -d ".git" ]; then git init; fi
    git config --global user.name "SillyTavern Backup"
    git config --global user.email "backup@claw.cloud"
    
    # 关键修正：使用更可靠的方式来处理 URL，移除所有协议头
    REPO_HOSTNAME_AND_PATH=$(echo "$REPO_URL" | sed -e 's/https?:\/\///g')
    AUTH_REPO_URL="https://oauth2:${GITHUB_TOKEN}@${REPO_HOSTNAME_AND_PATH}"
    
    echo "--- [Cloud Save] Configuring remote with sanitized URL..."
    git remote rm origin > /dev/null 2>&1 || true
    git remote add origin "$AUTH_REPO_URL"
    
    # 拉取数据
    echo "--- [Cloud Save] Attempting to fetch from main branch..."
    if git fetch origin main > /dev/null 2>&1; then
        git reset --hard origin/main
        echo "--- [Cloud Save] Data successfully fetched and updated."
    else
        echo "--- [Cloud Save] Could not fetch from main branch. It might be empty. Starting fresh."
    fi

    # 启动后台自动保存
    (
        while true; do
            sleep "$((${AUTOSAVE_INTERVAL:-30} * 60))"
            cd "$DATA_DIR" && git add . > /dev/null
            if ! git diff --cached --quiet; then
                echo "[Auto-Save] Pushing changes..."
                git commit -m "Cloud Backup: $(date)" && git push -f origin HEAD:main
            fi
        done
    ) &
    echo "--- [Cloud Save] Auto-save process running."
    cd /app
fi

echo "--- [Launcher V8] Starting SillyTavern server..."
exec node server.js
