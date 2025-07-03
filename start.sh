#!/bin/sh
# 最终版启动脚本 (V14 - Localized Config)
set -e

echo "--- [Launcher V14] Starting..."

# 1. (来自 V11 的修复) 从中转站复制配置文件
CONFIG_SOURCE="/config_mount/config.yaml"
CONFIG_DEST="/app/config.yaml"
if [ -f "$CONFIG_SOURCE" ]; then
    cp "$CONFIG_SOURCE" "$CONFIG_DEST"
else
    echo "CRITICAL: Config file not found at $CONFIG_SOURCE!"
    exit 1
fi

cd /app

# 2. (来自 V13 的修复) 配置云存档
if [ -n "$REPO_URL" ] && [ -n "$GITHUB_TOKEN" ]; then
    echo "--- [Cloud Save] Initializing..."
    DATA_DIR="/app/data"
    rm -rf "$DATA_DIR"
    AUTH_REPO_URL="https://oauth2:${GITHUB_TOKEN}@${REPO_URL}"
    
    echo "--- [Cloud Save] Cloning with precise URL: ${REPO_URL}..."
    git clone "$AUTH_REPO_URL" "$DATA_DIR"
    echo "--- [Cloud Save] Repository successfully cloned."
    
    cd "$DATA_DIR"
    
    # 核心修正：使用本地配置，而非全局配置。这不会触发权限问题。
    git config user.name "SillyTavern Backup"
    git config user.email "backup@claw.cloud"
    echo "--- [Cloud Save] Git user configured locally."

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
echo "--- [Launcher V14] All setup complete. Starting SillyTavern server..."
exec node server.js
