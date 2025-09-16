#!/bin/sh

set -e

echo ">>> 安装依赖..."
apk add --no-cache curl wget tar jq bash uuidgen openssl socat

echo ">>> 获取 TUIC 最新版本..."
TUIC_VERSION=$(wget -qO- https://api.github.com/repos/tuic-protocol/tuic/releases/latest \
  | grep '"tag_name"' | head -n 1 | cut -d '"' -f 4)

if [ -z "$TUIC_VERSION" ]; then
    echo "获取 TUIC 版本失败，请检查网络或 GitHub API"
    exit 1
fi

echo ">>> 最新版本: $TUIC_VERSION"

echo ">>> 下载 TUIC $TUIC_VERSION ..."
DOWNLOAD_URL="https://github.com/tuic-protocol/tuic/releases/download/${TUIC_VERSION}/${TUIC_VERSION}-x86_64-unknown-linux-musl"
wget -O tuic.tar.gz "$DOWNLOAD_URL"

echo ">>> 解压并安装..."
tar -xzf tuic.tar.gz
mv tuic-server /usr/local/bin/tuic-server
chmod +x /usr/local/bin/tuic-server
rm -f tuic.tar.gz

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
