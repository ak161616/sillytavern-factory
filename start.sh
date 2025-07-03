#!/bin/sh
# 最终版启动脚本 (V9 - Clone First)
set -e

echo "--- [Launcher V9] Starting..."
cd /app

# 验证 ConfigMap 是否已挂载
if [ ! -f "/app/config.yaml" ]; then
    echo "CRITICAL: config.yaml not found!"
    exit 1
fi

# 配置云存档
if [ -n "$REPO_URL" ] && [ -n "$GITHUB_TOKEN" ]; then
    echo "--- [Cloud Save] Initializing with robust Clone method..."
    DATA_DIR="/app/data"

    # 核心修正：不再 init，而是直接 clone
    # 这是一个更可靠的、原子性的操作
    REPO_HOSTNAME_AND_PATH=$(echo "$REPO_URL" | sed -e 's/https?:\/\///g')
    AUTH_REPO_URL="https://oauth2:${GITHUB_TOKEN}@${REPO_HOSTNAME_AND_PATH}"
    
    # 克隆远程仓库到数据目录
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

echo "--- [Launcher V9] All setup complete. Starting SillyTavern server..."
exec node server.js
