FROM node:18-alpine
RUN apk add --no-cache tini git
WORKDIR /app
COPY . .
RUN chmod +x /app/start.sh
RUN npm i --no-audit --no-fund --loglevel=error --no-progress --omit=dev --force --node-options=--max-old-space-size=400 && npm cache clean --force
RUN node docker/build-lib.js
EXPOSE 8000
ENTRYPOINT ["/sbin/tini", "--", "/app/start.sh"]
