#!/bin/sh
# 最终版启动脚本 (V11 - Mount and Copy)
set -e

echo "--- [Launcher V11] Starting..."
cd /app

# 核心修正：从中转站复制配置文件到工作目录
CONFIG_SOURCE="/config_mount/config.yaml"
CONFIG_DEST="/app/config.yaml"

if [ -f "$CONFIG_SOURCE" ]; then
    echo "--- [Launcher V11] Found config file at mount point. Copying to destination..."
    cp "$CONFIG_SOURCE" "$CONFIG_DEST"
    echo "--- [Launcher V11] Config file successfully copied."
else
    echo "CRITICAL: Config file not found at the source mount point ($CONFIG_SOURCE)! Please check your ConfigMap settings."
    exit 1
fi

# 配置云存档 (这部分逻辑不变)
if [ -n "$REPO_URL" ] && [ -n "$GITHUB_TOKEN" ]; then
    echo "--- [Cloud Save] Initializing..."
    DATA_DIR="/app/data"
    rm -rf "$DATA_DIR" # 强制清理，确保每次都是干净的克隆
    REPO_HOSTNAME_AND_PATH=$(echo "$REPO_URL" | sed -e 's/https?:\/\///g')
    AUTH_REPO_URL="https://oauth2:${GITHUB_TOKEN}@${REPO_HOSTNAME_AND_PATH}"
    git clone "$AUTH_REPO_URL" "$DATA_DIR"
    echo "--- [Cloud Save] Repository successfully cloned."
    cd "$DATA_DIR"
    git config --global user.name "SillyTavern Backup"
    git config --global user.email "backup@claw.cloud"
    (
        while true; do
            sleep "$((${AUTOSAVE_INTERVAL:-30} * 60))"
            cd "$DATA_DIR" && git add . > /dev/null
            if ! git diff --cached --quiet; then
                git commit -m "Cloud Backup: $(date)" && git push -f origin HEAD:main
            fi
        done
    ) &
    echo "--- [Cloud Save] Auto-save process is now running in the background."
    cd /app
fi

echo "--- [Launcher V11] All setup complete. Starting SillyTavern server..."
exec node server.js
