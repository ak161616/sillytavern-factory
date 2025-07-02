# 从一个包含所有工具的基础镜像开始
FROM node:18-alpine

# 设置工作目录
WORKDIR /app

# 安装 SillyTavern 和所有依赖
RUN apk add --no-cache git && \
    git clone -b staging --depth 1 https://github.com/SillyTavern/SillyTavern.git . && \
    npm i --no-audit --no-fund --loglevel=error --no-progress --omit=dev --force && \
    npm cache clean --force && \
    mkdir -p config && node docker/build-lib.js

# 暴露端口
EXPOSE 8000

# 设置默认启动命令
CMD ["node", "server.js"]
