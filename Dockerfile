FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends curl ca-certificates unzip python3 procps && rm -rf /var/lib/apt/lists/*
WORKDIR /app
RUN curl -fsSL https://github.com/XTLS/Xray-core/releases/download/v26.11.9/Xray-linux-64.zip -o /tmp/xray.zip && unzip /tmp/xray.zip -d /app && rm /tmp/xray.zip && chmod +x /app/xray
RUN curl -fsSL https://github.com/cloudflare/cloudflared/releases/download/2026.11.1/cloudflared-linux-amd64 -o /app/cloudflared && chmod +x /app/cloudflared
COPY start.sh health.py /app/
RUN chmod +x /app/start.sh
EXPOSE 8080
CMD ["/app/start.sh"]
