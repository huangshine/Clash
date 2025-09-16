#!/bin/sh

set -e

echo ">>> 安装依赖..."
apk add --no-cache curl wget tar bash uuidgen openssl socat

echo ">>> 下载 TUIC x86_64-musl 最新稳定版本..."
TUIC_VERSION="1.0.0"
DOWNLOAD_URL="https://github.com/tuic-protocol/tuic/releases/download/${TUIC_VERSION}/tuic-server-${TUIC_VERSION}-x86_64-unknown-linux-musl"

wget -O tuic-server "$DOWNLOAD_URL"
chmod +x tuic-server
mv tuic-server /usr/local/bin/tuic-server

echo ">>> 创建配置目录..."
mkdir -p /etc/tuic

UUID=$(uuidgen)
PASSWORD=$(openssl rand -base64 16)

echo ">>> 生成自签证书..."
openssl req -x509 -newkey rsa:2048 -nodes \
  -keyout /etc/tuic/key.pem \
  -out /etc/tuic/cert.pem \
  -subj "/CN=tuic" -days 3650

echo ">>> 写入配置文件..."
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

echo ">>> 写入 systemd 服务..."
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

IP=$(curl -s https://v4.ident.me || echo "YOUR_IP")

echo "=============================="
echo " TUIC 节点部署完成"
echo " IP: $IP"
echo " UUID: $UUID"
echo " 密码: $PASSWORD"
echo " 配置文件: /etc/tuic/config.json"
echo "------------------------------"
echo " 客户端连接链接:"
echo " tuic://$UUID:$PASSWORD@$IP:443?congestion_control=bbr&alpn=h3&insecure=1"
echo "=============================="
