#!/bin/sh

set -e

apk add --no-cache curl wget tar jq uuidgen bash socat

# 下载最新 TUIC
TUIC_VERSION=$(curl -s https://api.github.com/repos/EAimTY/tuic/releases/latest | jq -r .tag_name)
wget https://github.com/EAimTY/tuic/releases/download/${TUIC_VERSION}/tuic-server-${TUIC_VERSION}-x86_64-unknown-linux-musl.tar.gz
tar -xzf tuic-server-${TUIC_VERSION}-x86_64-unknown-linux-musl.tar.gz
mv tuic-server /usr/local/bin/tuic-server
chmod +x /usr/local/bin/tuic-server

# 创建配置目录
mkdir -p /etc/tuic

UUID=$(uuidgen)
PASSWORD=$(openssl rand -base64 16)

# 获取证书（用 acme.sh，你的 hy2.sh 已经有逻辑，可以直接复用）
# 这里假设你已经有 /etc/tuic/cert.pem 和 /etc/tuic/key.pem

cat > /etc/tuic/config.json <<EOF
{
  "server": "[::]:443",
  "users": {
    "$UUID": "$PASSWORD"
  },
  "certificate": "/etc/tuic/cert.pem",
  "private_key": "/etc/tuic/key.pem",
  "congestion_control": "bbr",
  "alpn": ["h3"]
}
EOF

# Systemd service
cat > /etc/systemd/system/tuic.service <<EOF
[Unit]
Description=TUIC Server
After=network.target

[Service]
ExecStart=/usr/local/bin/tuic-server -c /etc/tuic/config.json
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now tuic

IP=$(curl -s https://v4.ident.me)

echo "=============================="
echo " TUIC 节点部署成功"
echo " 地址: $IP"
echo " UUID: $UUID"
echo " 密码: $PASSWORD"
echo " 链接: tuic://$UUID:$PASSWORD@$IP:443?congestion_control=bbr&alpn=h3"
echo "=============================="
