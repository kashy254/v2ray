# V2Ray Server Setup Guide

## Prerequisites
- VPS with Ubuntu/Debian
- Domain name: emmkashtechnologies.xyz
- Port 443 open in firewall

## Step 1: Install V2Ray
```bash
# Install V2Ray
bash <(curl -L https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh)

# Create log directory
mkdir -p /var/log/v2ray
chmod 755 /var/log/v2ray
```

## Step 2: Set up SSL certificate
```bash
# Install certbot
apt update
apt install -y certbot

# Get SSL certificate
certbot certonly --standalone --agree-tos --email emmkash20@gmail.com -d emmkashtechnologies.xyz

# Certificate locations:
# Certificate: /etc/letsencrypt/live/emmkashtechnologies.xyz/fullchain.pem
# Private key: /etc/letsencrypt/live/emmkashtechnologies.xyz/privkey.pem
```

## Step 3: Configure V2Ray server
The server_config.json has been updated with your UUID and domain.

```bash
# Copy config to V2Ray directory
cp server_config.json /usr/local/etc/v2ray/config.json
```

## Step 4: Start and enable V2Ray
```bash
systemctl start v2ray
systemctl enable v2ray
systemctl status v2ray
```

## Step 5: Configure HTTP Custom for the client
For HTTP Custom app, use these settings:

```
CONNECT emmkashtechnologies.xyz:443 HTTP/1.1
host: emmkashtechnologies.xyz:443
proxy-connection: keep-alive
user-agent: Mozilla/5.0 (Linux; Android 15; 23106RN0DA Build/AP3A.240905.015.A2; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/135.0.7049.113 Mobile Safari/537.36 [FBAN/InternetOrgApp;FBAV/65.0.0.0.191;]
x-iorg-bsid: 89d6d316-0068-400f-8fb7-f87c0ce67155
x-iorg-service-id: null

PROXY: 157.240.195.32:8080
```

Make sure to:
1. Enable both Payload and V2Ray options
2. Use the correct UUID: e4d14363-c410-4ccf-8973-1e6046350a56

## Troubleshooting
- Check V2Ray logs: `tail -f /var/log/v2ray/error.log`
- Verify certificate is valid: `certbot certificates`
- Make sure port 443 is open: `ufw status`
- Check V2Ray is running: `systemctl status v2ray` 