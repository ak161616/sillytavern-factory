#!/bin/sh
# 最终版启动脚本 (V13 - 结合所有修复)
set -e

echo "--- [Launcher V13] Starting..."

# 1. (来自 V11 的修复) 从中转站复制配置文件，避免 BadRequest 错误
CONFIG_SOURCE="/config_mount/config.yaml"
CONFIG_DEST="/app/config.yaml"

if [ -f "$CONFIG_SOURCE" ]; then
    echo "--- [Launcher V13] Found config file at mount point. Copying to destination..."
    cp "$CONFIG_SOURCE" "$CONFIG_DEST"
    echo "--- [Launcher V13] Config file successfully copied."
else
    echo "CRITICAL: Config file not found at the source mount point ($CONFIG_SOURCE)! Please check your ConfigMap mount path in ClawCloud. It must be exactly '/config_mount/config.yaml'."
    exit 1
fi

# 切换到主工作目录
cd /app

# 2. (来自 V12 的修复) 配置云存档，使用精确的 URL
if [ -n "$REPO_URL" ] && [ -n "$GITHUB_TOKEN" ]; then
    echo "--- [Cloud Save] Initializing..."
    DATA_DIR="/app/data"
    rm -rf "$DATA_DIR" # 强制清理，确保每次都是干净的克隆

    # 使用精确的、无协议头的 REPO_URL
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

# 3. 启动 SillyTavern
echo "--- [Launcher V13] All setup complete. Starting SillyTavern server..."
exec node server.js
