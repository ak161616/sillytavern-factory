#!/bin/sh
# 最终版启动脚本 (V12 - Precise URL)
set -e

echo "--- [Launcher V12] Starting..."
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
    rm -rf "$DATA_DIR"

    # 核心修正：不再处理URL，直接使用您提供的地址
    # 假设 REPO_URL 的格式为 "github.com/user/repo"
    AUTH_REPO_URL="https://oauth2:${GITHUB_TOKEN}@${REPO_URL}"
    
    echo "--- [Cloud Save] Cloning with precise URL: ${REPO_URL}..."
    git clone "$AUTH_REPO_URL" "$DATA_DIR"
    echo "--- [Cloud Save] Repository successfully cloned."
    
    cd "$DATA_DIR"
    git config --global user.name "SillyTavern Backup"
    git config --global user.email "backup@claw.cloud"

    # 启动后台自动保存
    (
        while true; do
            sleep "$((${AUTOSAVE_INTERVAL:-30} * 60))"
            cd "$DATA_DIR" && git add . > /dev/null
            if ! git diff --cached --quiet; then
                git commit -m "Cloud Backup: $(date)" && git push -f origin HEAD:main
            fi
        done
    ) &
    echo "--- [Cloud Save] Auto-save process is now running."
    cd /app
fi

echo "--- [Launcher V12] All setup complete. Starting server..."
exec node server.js
