#!/bin/sh
# storc-node bootstrap for a fresh Ubuntu/Debian VM (run as root).
# Installs xray (VLESS+WS on 127.0.0.1:10000, path /goo) + cloudflared as systemd services.
# Usage: XRAY_UUID=<uuid> TUNNEL_TOKEN=<token> sh install.sh   (or: sh install.sh <uuid> <token>)
set -e
UUID="${XRAY_UUID:-$1}"
TOKEN="${TUNNEL_TOKEN:-$2}"
if [ -z "$UUID" ] || [ -z "$TOKEN" ]; then
  echo "need XRAY_UUID and TUNNEL_TOKEN" >&2
  exit 1
fi
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq curl unzip
mkdir -p /usr/local/xray
cd /tmp
curl -sL -o xray.zip https://github.com/XTLS/Xray-core/releases/download/v26.11.9/Xray-linux-64.zip
unzip -o -q xray.zip -d /usr/local/xray
curl -sL -o /usr/local/bin/cloudflared https://github.com/cloudflare/cloudflared/releases/download/2026.11.1/cloudflared-linux-amd64
chmod +x /usr/local/bin/cloudflared /usr/local/xray/xray
cat > /usr/local/xray/config.json <<JSON
{
  "log": {"loglevel": "warning"},
  "inbounds": [
    {
      "listen": "127.0.0.1",
      "port": 10000,
      "protocol": "vless",
      "settings": {
        "clients": [{"id": "$UUID", "flow": ""}],
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
printf 'TUNNEL_TOKEN=%s\n' "$TOKEN" > /etc/storc-node.env
chmod 600 /etc/storc-node.env
cat > /etc/systemd/system/xray.service <<'EOF'
[Unit]
Description=Xray
After=network.target

[Service]
ExecStart=/usr/local/xray/xray run -config /usr/local/xray/config.json
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
cat > /etc/systemd/system/cloudflared.service <<'EOF'
[Unit]
Description=cloudflared
After=network.target

[Service]
EnvironmentFile=/etc/storc-node.env
ExecStart=/usr/local/bin/cloudflared tunnel --no-autoupdate run
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable --now xray.service cloudflared.service
echo "storc-node installed"
