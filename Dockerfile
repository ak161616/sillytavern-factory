# 使用官方 Node.js 18 Alpine 镜像
FROM node:18-alpine

# 安装 tini, git, 和 dos2unix (或 sed) 所需的工具
RUN apk add --no-cache tini git sed

# 设置工作目录
WORKDIR /app

# 克隆 SillyTavern
RUN git clone -b staging --depth 1 https://github.com/SillyTavern/SillyTavern.git .

# 安装依赖
RUN npm i --no-audit --no-fund --loglevel=error --no-progress --omit=dev --force --node-options=--max-old-space-size=1024 && \
    npm cache clean --force

# 运行前端构建
RUN node docker/build-lib.js

# 复制我们的启动脚本
COPY start.sh /app/start.sh

# 赋予执行权限
RUN chmod +x /app/start.sh

# 关键修复：强制转换换行符为 Unix 格式
RUN sed -i 's/\r$//' /app/start.sh

# 暴露端口并设置入口点
EXPOSE 8000
ENTRYPOINT ["/sbin/tini", "--", "/app/start.sh"]
