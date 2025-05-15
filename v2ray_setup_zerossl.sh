#!/bin/bash

# V2Ray Setup Script with ZeroSSL certificate
# Domain: edgee.emmkashtech.online
# Email: emmkash20@gmail.com
# UUID: e4d14363-c410-4ccf-8973-1e6046350a56

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting V2Ray server setup with ZeroSSL certificate...${NC}"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Please run as root (use sudo)${NC}"
  exit 1
fi

# Create temp dir
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

# Define variables
DOMAIN="edgee.emmkashtech.online"
UUID="e4d14363-c410-4ccf-8973-1e6046350a56"
EMAIL="emmkash20@gmail.com"
CERT_DIR="/etc/v2ray/cert"

# Install required packages
echo -e "${YELLOW}Installing required packages...${NC}"
apt update
apt install -y curl wget unzip openssl ufw jq python3 python3-pip

# Install acme.sh client for ZeroSSL
echo -e "${YELLOW}Installing acme.sh client...${NC}"
if [ ! -f "/root/.acme.sh/acme.sh" ]; then
  curl https://get.acme.sh | sh -s email=$EMAIL
  source ~/.bashrc
fi

# Configure firewall
echo -e "${YELLOW}Configuring firewall...${NC}"
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

# Install V2Ray
echo -e "${YELLOW}Installing V2Ray...${NC}"
if [ ! -f "/usr/local/bin/v2ray" ]; then
  bash <(curl -L https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh)
fi

# Create log directory
mkdir -p /var/log/v2ray
chmod 755 /var/log/v2ray

# Create certificate directory
echo -e "${YELLOW}Creating certificate directory...${NC}"
mkdir -p $CERT_DIR
chmod 700 $CERT_DIR

# Issue ZeroSSL certificate (file auth)
echo -e "${YELLOW}Issuing ZeroSSL certificate...${NC}"
mkdir -p /var/www/html/.well-known/acme-challenge
chmod -R 755 /var/www/html

# Install simple HTTP server for validation
python3 -m pip install --upgrade pip
python3 -m pip install http.server

# Start a temporary web server for validation (in background)
echo -e "${YELLOW}Starting temporary web server for validation...${NC}"
cd /var/www/html
python3 -m http.server 80 &
HTTP_SERVER_PID=$!
sleep 2

# Register account with ZeroSSL through acme.sh
~/.acme.sh/acme.sh --register-account -m $EMAIL --server zerossl

# Issue certificate with ZeroSSL
~/.acme.sh/acme.sh --issue -d $DOMAIN --webroot /var/www/html --server zerossl

# Kill the temporary web server
if [ -n "$HTTP_SERVER_PID" ]; then
  kill $HTTP_SERVER_PID || true
fi

# Install certificate to the V2Ray directory
~/.acme.sh/acme.sh --install-cert -d $DOMAIN \
  --key-file $CERT_DIR/private.key \
  --fullchain-file $CERT_DIR/cert.crt \
  --reloadcmd "systemctl restart v2ray"

# Set proper permissions for certificates
chmod 600 "$CERT_DIR/private.key"
chmod 644 "$CERT_DIR/cert.crt"

# Create V2Ray config
echo -e "${YELLOW}Creating V2Ray configuration...${NC}"
cat > /usr/local/etc/v2ray/config.json << EOF
{
  "log": {
    "access": "/var/log/v2ray/access.log",
    "error": "/var/log/v2ray/error.log",
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "port": 443,
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
            "id": "$UUID",
            "alterId": 0,
            "security": "chacha20-poly1305",
            "level": 8
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "security": "tls",
        "tlsSettings": {
          "certificates": [
            {
              "certificateFile": "$CERT_DIR/cert.crt",
              "keyFile": "$CERT_DIR/private.key"
            }
          ]
        },
        "wsSettings": {
          "path": "/",
          "headers": {
            "Host": "$DOMAIN"
          }
        }
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {}
    }
  ]
}
EOF

# Set proper permissions
echo -e "${YELLOW}Setting permissions...${NC}"
chmod 644 /usr/local/etc/v2ray/config.json

# Start and enable V2Ray
echo -e "${YELLOW}Starting V2Ray service...${NC}"
systemctl daemon-reload
systemctl restart v2ray
systemctl enable v2ray

# Create client config file (standard client)
echo -e "${YELLOW}Creating client configuration files...${NC}"
mkdir -p /root/v2ray_client
cat > /root/v2ray_client/client_config.json << EOF
{
  "inbounds":[
    {
      "listen":"127.0.0.1",
      "port":3080,
      "protocol":"socks",
      "settings":{
        "auth":"noauth",
        "udp":true,
        "userLevel":8
      }
    },
    {
      "listen":"127.0.0.1",
      "port":8880,
      "protocol":"http",
      "settings":{
        "userLevel":8
      }
    }
  ],
  "log":{
    "loglevel":"none"
  },
  "outbounds":[
    {
      "mux":{
        "concurrency":8,
        "enabled":false
      },
      "protocol":"vmess",
      "settings":{
        "vnext":[
          {
            "address":"$DOMAIN",
            "port":443,
            "users":[
              {
                "alterId":0,
                "encryption":"",
                "id":"$UUID",
                "flow":"",
                "level":8,
                "security":"chacha20-poly1305"
              }
            ]
          }
        ]
      },
      "streamSettings":{
        "network":"ws",
        "security":"tls",
        "wsSettings":{
          "path":"/",
          "headers":{
            "Host":"$DOMAIN"
          }
        },
        "tlsSettings":{
          "allowInsecure":false,
          "serverName":"$DOMAIN"
        }
      }
    }
  ]
}
EOF

# Create HTTP Custom config
cat > /root/v2ray_client/http_custom_config.txt << EOF
HTTP Custom Configuration:
--------------------------

CONNECT $DOMAIN:443 HTTP/1.1
host: $DOMAIN:443
proxy-connection: keep-alive
user-agent: Mozilla/5.0 (Linux; Android 15; 23106RN0DA Build/AP3A.240905.015.A2; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/135.0.7049.113 Mobile Safari/537.36 [FBAN/InternetOrgApp;FBAV/65.0.0.0.191;]
x-iorg-bsid: 89d6d316-0068-400f-8fb7-f87c0ce67155
x-iorg-service-id: null

PROXY: 157.240.195.32:8080
EOF

# Create V2Ray URI for easier import
VMESS_JSON="{\"v\":\"2\",\"ps\":\"Emmkash Tech\",\"add\":\"$DOMAIN\",\"port\":\"443\",\"id\":\"$UUID\",\"aid\":\"0\",\"net\":\"ws\",\"type\":\"none\",\"host\":\"$DOMAIN\",\"path\":\"/\",\"tls\":\"tls\"}"
VMESS_URI="vmess://$(echo -n "$VMESS_JSON" | base64 -w 0)"
echo "$VMESS_URI" > /root/v2ray_client/vmess_uri.txt

# Set up auto renewal cron job
echo -e "${YELLOW}Setting up certificate auto renewal...${NC}"
echo "0 0 * * * root ~/.acme.sh/acme.sh --cron --home ~/.acme.sh > /dev/null" > /etc/cron.d/acme-cron

# Clean up
cd
rm -rf "$TEMP_DIR"

# Check if V2Ray is running
V2RAY_STATUS=$(systemctl is-active v2ray)
if [ "$V2RAY_STATUS" = "active" ]; then
  echo -e "${GREEN}V2Ray is running successfully!${NC}"
else
  echo -e "${RED}V2Ray failed to start. Check logs with: journalctl -u v2ray -n 50${NC}"
  systemctl status v2ray
fi

echo -e "${GREEN}Setup completed successfully!${NC}"
echo -e "${YELLOW}------------------------------------------------------${NC}"
echo -e "${GREEN}V2Ray is running with the following configuration:${NC}"
echo -e "${YELLOW}Domain:${NC} $DOMAIN"
echo -e "${YELLOW}UUID:${NC} $UUID"
echo -e "${YELLOW}Protocol:${NC} VMess over WebSocket with TLS"
echo -e "${YELLOW}------------------------------------------------------${NC}"
echo -e "${GREEN}Client configuration files created at:${NC}"
echo -e "${YELLOW}/root/v2ray_client/client_config.json${NC} - For V2Ray clients"
echo -e "${YELLOW}/root/v2ray_client/http_custom_config.txt${NC} - For HTTP Custom app"
echo -e "${YELLOW}/root/v2ray_client/vmess_uri.txt${NC} - VMess URI for easy import"
echo -e "${YELLOW}------------------------------------------------------${NC}"
echo -e "${GREEN}Certificate Information:${NC}"
echo -e "${YELLOW}Provider:${NC} ZeroSSL"
echo -e "${YELLOW}Auto-renewal:${NC} Enabled (daily check)"
echo -e "${YELLOW}Certificate path:${NC} $CERT_DIR/cert.crt"
echo -e "${YELLOW}------------------------------------------------------${NC}"
echo -e "${GREEN}To check status:${NC} systemctl status v2ray"
echo -e "${GREEN}To view logs:${NC} tail -f /var/log/v2ray/access.log"
echo -e "${GREEN}To view errors:${NC} tail -f /var/log/v2ray/error.log"

# Display server IP for reference
SERVER_IP=$(curl -s ifconfig.me)
echo -e "${YELLOW}------------------------------------------------------${NC}"
echo -e "${GREEN}Server IP:${NC} $SERVER_IP"
echo -e "${GREEN}Make sure your domain ($DOMAIN) points to this IP.${NC}" 