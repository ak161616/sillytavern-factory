#!/bin/sh
# 全功能启动脚本 V6 (最终修正版)
set -e
echo "--- [Launcher V6] Starting..."

# 切换到主工作目录
cd /app

# 检查由 ConfigMap 提供的配置文件是否存在
if [ ! -f "/app/config.yaml" ]; then
    echo "CRITICAL: config.yaml not found! Check your ConfigMap settings in ClawCloud."
    exit 1
fi

# 如果提供了云存档的密钥，则进行配置
if [ -n "$REPO_URL" ] && [ -n "$GITHUB_TOKEN" ]; then
    echo "--- [Cloud Save] Initializing..."
    DATA_DIR="/app/data"
    mkdir -p "$DATA_DIR"
    cd "$DATA_DIR"

    # 初始化 Git 仓库 (如果它不存在的话)
    if [ ! -d ".git" ]; then git init; fi

    # 设置 Git 用户信息
    git config --global user.name "SillyTavern Backup"
    git config --global user.email "backup@claw.cloud"

    # 核心修正：正确地添加或更新远程仓库地址
    # 这是一个更可靠的做法，无论重启多少次都不会出错
    if git config remote.origin.url > /dev/null; then
        echo "--- [Cloud Save] Remote 'origin' already exists. Updating URL... ---"
        git remote set-url origin "https://oauth2:${GITHUB_TOKEN}@$(echo $REPO_URL | sed -e 's/https?:\/\///')"
    else
        echo "--- [Cloud Save] No remote 'origin' found. Adding new remote... ---"
        git remote add origin "https://oauth2:${GITHUB_TOKEN}@$(echo $REPO_URL | sed -e 's/https?:\/\///')"
    fi

    # 拉取现有的云端数据
    if git ls-remote --exit-code --heads origin main > /dev/null 2>&1; then
        echo "--- [Cloud Save] Pulling existing data from GitHub... ---"
        git fetch origin main && git reset --hard origin/main
        echo "--- [Cloud Save] Data loaded successfully. ---"
    fi

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

    # 返回主目录
    cd /app
fi

echo "--- [Launcher V6] All setup complete. Starting SillyTavern server... ---"
exec node server.js
