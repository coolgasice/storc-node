#!/bin/sh
set -e
cat > /tmp/config.json <<JSON
{
  "log": {"loglevel": "warning"},
  "inbounds": [
    {
      "listen": "127.0.0.1",
      "port": 10000,
      "protocol": "vless",
      "settings": {
        "clients": [{"id": "$XRAY_UUID", "flow": ""}],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {"path": "/goo"}
      }
    }
  ],
  "outbounds": [{"protocol": "freedom", "tag": "direct"}]
}
JSON
python3 /app/health.py &
/app/xray run -config /tmp/config.json &
exec /app/cloudflared tunnel --no-autoupdate run --token "$TUNNEL_TOKEN"
