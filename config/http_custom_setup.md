# HTTP Custom + V2Ray Configuration Guide

This guide explains how to set up HTTP Custom app to work with V2Ray for the configuration you're interested in.

## What Makes This Setup Special

This setup uses a combination of techniques:
1. VMess protocol (secure encryption)
2. TLS encryption (for security)
3. WebSocket transport (helps bypass DPI)
4. HTTP headers that mimic legitimate traffic
5. A proxy server for additional obfuscation

## HTTP Custom Configuration

### Main Settings
1. Open HTTP Custom app
2. Create a new configuration
3. In the "Server" section, enter:
   ```
   CONNECT emmkashtechnologies.xyz:443 HTTP/1.1
   host: emmkashtechnologies.xyz:443
   proxy-connection: keep-alive
   user-agent: Mozilla/5.0 (Linux; Android 15; 23106RN0DA Build/AP3A.240905.015.A2; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/135.0.7049.113 Mobile Safari/537.36 [FBAN/InternetOrgApp;FBAV/65.0.0.0.191;]
   x-iorg-bsid: 89d6d316-0068-400f-8fb7-f87c0ce67155
   x-iorg-service-id: null
   
   PROXY: 157.240.195.32:8080
   ```

### V2Ray Settings
1. Enable V2Ray in the app settings
2. Enter the following V2Ray configuration (in JSON format or through the UI depending on your app version):
   ```json
   {
     "v": "2",
     "ps": "Emmkash Tech",
     "add": "emmkashtechnologies.xyz",
     "port": "443",
     "id": "e4d14363-c410-4ccf-8973-1e6046350a56",
     "aid": "0",
     "net": "ws",
     "type": "none",
     "host": "emmkashtechnologies.xyz",
     "path": "/",
     "tls": "tls"
   }
   ```

### Important Settings
1. Make sure "Payload" is enabled/ticked
2. Make sure "V2Ray" is enabled/ticked
3. Set connection type to "Direct Connection" 
4. If asked for SSH/SSL settings, select "SSH Direct" or "SSL Direct" depending on your app

## Key Components Explanation

### Headers
The headers mimic Facebook's Internet.org app traffic. This helps disguise your connection as legitimate traffic.

### Proxy Setting
The proxy (157.240.195.32:8080) appears to be a Facebook-owned server, which helps route initial traffic through a seemingly legitimate service.

### User Agent
The user agent identifies as a mobile browser on Android, which is common and doesn't raise suspicion.

## Troubleshooting
If connection fails:
1. Check server is running and accessible
2. Verify all settings match between client and server
3. Try different proxy servers
4. Check if your ISP is blocking the proxy server IP 