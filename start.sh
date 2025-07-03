#!/bin/sh
# 黄金最终版启动脚本 (V7)
set -e

echo "--- [Launcher V7] Starting... ---"
cd /app

# 验证 ConfigMap 是否已挂载
if [ ! -f "/app/config.yaml" ]; then
    echo "CRITICAL: config.yaml not found. Please check your ConfigMap settings in ClawCloud."
    exit 1
fi

# 如果提供了云存档密钥，则进行配置
if [ -n "$REPO_URL" ] && [ -n "$GITHUB_TOKEN" ]; then
    echo "--- [Cloud Save] Initializing... ---"
    DATA_DIR="/app/data"
    mkdir -p "$DATA_DIR"
    cd "$DATA_DIR"

    # 强制初始化并配置 Git
    if [ ! -d ".git" ]; then git init; fi
    git config --global user.name "SillyTavern Backup"
    git config --global user.email "backup@claw.cloud"
    
    # 强制、可靠地设置远程仓库地址
    git remote rm origin > /dev/null 2>&1 || true # 先安静地删除旧的，忽略错误
    git remote add origin "https://oauth2:${GITHUB_TOKEN}@$(echo $REPO_URL | sed -e 's/https?:\/\///')"
    echo "--- [Cloud Save] Remote URL has been forcefully configured. ---"

    # 拉取现有的云端数据
    echo "--- [Cloud Save] Attempting to fetch and reset data from main branch... ---"
    git fetch origin main
    git reset --hard origin/main
    echo "--- [Cloud Save] Data sync process completed. ---"

    # 启动后台自动保存进程
    (
        while true; do
            sleep "$((${AUTOSAVE_INTERVAL:-30} * 60))"
            cd "$DATA_DIR" && git add . > /dev/null
            if ! git diff --cached --quiet; then
                echo "[Auto-Save] Changes detected. Pushing to GitHub..."
                git commit -m "Cloud Backup: $(date)" && git push -f origin HEAD:main
            fi
        done
    ) &
    echo "--- [Cloud Save] Auto-save process is now running in the background. ---"

    cd /app
fi

echo "--- [Launcher V7] All setup complete. Starting SillyTavern server... ---"
exec node server.js
