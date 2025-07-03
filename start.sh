#!/bin/sh
# 最终版启动脚本 (V10 - Clean Slate)
set -e

echo "--- [Launcher V10] Starting..."
cd /app

# 验证 ConfigMap
if [ ! -f "/app/config.yaml" ]; then
    echo "CRITICAL: config.yaml not found!"
    exit 1
fi

# 配置云存档
if [ -n "$REPO_URL" ] && [ -n "$GITHUB_TOKEN" ]; then
    echo "--- [Cloud Save] Initializing with robust Clone method..."
    DATA_DIR="/app/data"

    # 核心修正：在克隆之前，强制删除任何可能存在的旧数据目录
    echo "--- [Cloud Save] Cleaning up old data directory (if any)..."
    rm -rf "$DATA_DIR"

    # 现在，在一个绝对干净的路径上进行克隆
    echo "--- [Cloud Save] Cloning repository into a clean path..."
    REPO_HOSTNAME_AND_PATH=$(echo "$REPO_URL" | sed -e 's/https?:\/\///g')
    AUTH_REPO_URL="https://oauth2:${GITHUB_TOKEN}@${REPO_HOSTNAME_AND_PATH}"
    
    git clone "$AUTH_REPO_URL" "$DATA_DIR"
    echo "--- [Cloud Save] Repository successfully cloned."
    
    cd "$DATA_DIR"
    git config --global user.name "SillyTavern Backup"
    git config --global user.email "backup@claw.cloud"

    # 启动后台自动保存
    (
        while true; do
            sleep "$((${AUTOSAVE_INTERVAL:-30} * 60))"
            cd "$DATA_DIR"
            git add . > /dev/null
            if ! git diff --cached --quiet; then
                echo "[Auto-Save] Pushing changes to GitHub..."
                git commit -m "Cloud Backup: $(date)" && git push -f origin HEAD:main
            fi
        done
    ) &
    echo "--- [Cloud Save] Auto-save process is now running in the background."
    cd /app
fi

echo "--- [Launcher V10] All setup complete. Starting SillyTavern server..."
exec node server.js
