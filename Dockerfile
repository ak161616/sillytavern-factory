# 使用官方 Node.js 18 Alpine 镜像，它包含了我们需要的一切
FROM node:18-alpine

# 安装 tini 和 git
RUN apk add --no-cache tini git

# 设置并创建工作目录
WORKDIR /app

# 核心修正：先克隆 SillyTavern，这样 package.json 就位了
RUN git clone -b staging --depth 1 https://github.com/SillyTavern/SillyTavern.git .

# 现在，在有 package.json 的情况下，安全地安装依赖
# 同时，我们为这一步分配更多内存，以防万一
RUN npm i --no-audit --no-fund --loglevel=error --no-progress --omit=dev --force --node-options=--max-old-space-size=1024 && \
    npm cache clean --force

# 运行前端构建脚本
RUN node docker/build-lib.js

# 复制我们的自定义启动脚本
COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

# 暴露端口并设置入口点
EXPOSE 8000
ENTRYPOINT ["/sbin/tini", "--", "/app/start.sh"]
