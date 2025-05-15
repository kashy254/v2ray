#!/bin/bash

# V2Ray Setup Script for the HTTP Custom configuration
# Domain: trial.emmkashtech.online
# Email: emmkash20@gmail.com
# UUID: e4d14363-c410-4ccf-8973-1e6046350a56

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting V2Ray server setup...${NC}"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Please run as root (use sudo)${NC}"
  exit 1
fi

# Create temp dir
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

# Install required packages
echo -e "${YELLOW}Installing required packages...${NC}"
apt update
apt install -y curl wget unzip certbot ufw

# Configure firewall
echo -e "${YELLOW}Configuring firewall...${NC}"
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

# Install V2Ray
echo -e "${YELLOW}Installing V2Ray...${NC}"
bash <(curl -L https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh)

# Create log directory
mkdir -p /var/log/v2ray
chmod 755 /var/log/v2ray

# Set up SSL certificate
echo -e "${YELLOW}Setting up SSL certificate...${NC}"
certbot certonly --standalone --agree-tos --non-interactive --email emmkash20@gmail.com -d trial.emmkashtech.online

# Create V2Ray config
echo -e "${YELLOW}Creating V2Ray configuration...${NC}"
cat > /usr/local/etc/v2ray/config.json << 'EOF'
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
            "id": "e4d14363-c410-4ccf-8973-1e6046350a56",
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
              "certificateFile": "/etc/letsencrypt/live/trial.emmkashtech.online/fullchain.pem",
              "keyFile": "/etc/letsencrypt/live/trial.emmkashtech.online/privkey.pem"
            }
          ]
        },
        "wsSettings": {
          "path": "/",
          "headers": {
            "Host": "trial.emmkashtech.online"
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
systemctl restart v2ray
systemctl enable v2ray

# Create client config file
echo -e "${YELLOW}Creating client configuration file...${NC}"
mkdir -p /root/v2ray_client
cat > /root/v2ray_client/client_config.json << 'EOF'
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
            "address":"trial.emmkashtech.online",
            "port":443,
            "users":[
              {
                "alterId":0,
                "encryption":"",
                "id":"e4d14363-c410-4ccf-8973-1e6046350a56",
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
            "Host":"trial.emmkashtech.online"
          }
        },
        "tlsSettings":{
          "allowInsecure":false,
          "serverName":"trial.emmkashtech.online"
        }
      }
    }
  ]
}
EOF

# Create HTTP Custom guide
cat > /root/v2ray_client/http_custom_config.txt << 'EOF'
HTTP Custom Configuration:
--------------------------

CONNECT trial.emmkashtech.online:443 HTTP/1.1
host: trial.emmkashtech.online:443
proxy-connection: keep-alive
user-agent: Mozilla/5.0 (Linux; Android 15; 23106RN0DA Build/AP3A.240905.015.A2; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/135.0.7049.113 Mobile Safari/537.36 [FBAN/InternetOrgApp;FBAV/65.0.0.0.191;]
x-iorg-bsid: 89d6d316-0068-400f-8fb7-f87c0ce67155
x-iorg-service-id: null

PROXY: 157.240.195.32:8080
EOF

# Create V2Ray URI for easier import
UUID="e4d14363-c410-4ccf-8973-1e6046350a56"
DOMAIN="trial.emmkashtech.online"
SECURITY="chacha20-poly1305"
VMESS_JSON="{\"v\":\"2\",\"ps\":\"Emmkash Tech\",\"add\":\"$DOMAIN\",\"port\":\"443\",\"id\":\"$UUID\",\"aid\":\"0\",\"net\":\"ws\",\"type\":\"none\",\"host\":\"$DOMAIN\",\"path\":\"/\",\"tls\":\"tls\"}"
VMESS_URI="vmess://$(echo -n "$VMESS_JSON" | base64 -w 0)"
echo "$VMESS_URI" > /root/v2ray_client/vmess_uri.txt

# Set up auto renewal for SSL
echo -e "${YELLOW}Setting up SSL auto renewal...${NC}"
echo "0 0,12 * * * root python -c 'import random; import time; time.sleep(random.random() * 3600)' && certbot renew -q" > /etc/cron.d/certbot-renew

# Clean up
cd
rm -rf "$TEMP_DIR"

echo -e "${GREEN}Setup completed successfully!${NC}"
echo -e "${YELLOW}------------------------------------------------------${NC}"
echo -e "${GREEN}V2Ray is running with the following configuration:${NC}"
echo -e "${YELLOW}Domain:${NC} trial.emmkashtech.online"
echo -e "${YELLOW}UUID:${NC} e4d14363-c410-4ccf-8973-1e6046350a56"
echo -e "${YELLOW}Protocol:${NC} VMess over WebSocket with TLS"
echo -e "${YELLOW}------------------------------------------------------${NC}"
echo -e "${GREEN}Client configuration files created at:${NC}"
echo -e "${YELLOW}/root/v2ray_client/client_config.json${NC} - For V2Ray clients"
echo -e "${YELLOW}/root/v2ray_client/http_custom_config.txt${NC} - For HTTP Custom app"
echo -e "${YELLOW}/root/v2ray_client/vmess_uri.txt${NC} - VMess URI for easy import"
echo -e "${YELLOW}------------------------------------------------------${NC}"
echo -e "${GREEN}To check status:${NC} systemctl status v2ray"
echo -e "${GREEN}To view logs:${NC} tail -f /var/log/v2ray/access.log"
echo -e "${GREEN}To view errors:${NC} tail -f /var/log/v2ray/error.log"

ls -la /etc/letsencrypt/live/trial.emmkashtech.online/

ufw disable 