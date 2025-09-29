#!/bin/bash

# argument check
if [ -z "$1" ]; then
    echo "error: need vless/reality link"
    exit 1
fi

LINK="$1"

# check type: reality or just vless
if echo "$LINK" | grep -q "security=reality"; then
    TYPE="reality"
else
    TYPE="vless"
fi

# base params
UUID=$(echo "$LINK" | sed -E 's|vless://([^@]+)@.*|\1|')
HOST=$(echo "$LINK" | sed -E 's|vless://[^@]+@([^:/]+):.*|\1|')
PORT=$(echo "$LINK" | sed -E 's|vless://[^@]+@[^:]+:([0-9]+).*|\1|')

CONFIG_FILE="$HOME/vless_config.json"

if [ "$TYPE" = "reality" ]; then
    # specific reality params
    SNI=$(echo "$LINK" | grep -oP 'sni=[^&]+' | cut -d= -f2)
    FP=$(echo "$LINK" | grep -oP 'fp=[^&]+' | cut -d= -f2)
    PUBKEY=$(echo "$LINK" | grep -oP 'pbk=[^&]+' | cut -d= -f2)
    SHORTID=$(echo "$LINK" | grep -oP 'sid=[^&]+' | cut -d= -f2)
    SPX=$(echo "$LINK" | grep -oP 'spx=[^&]+' | cut -d= -f2 | sed 's/%2F/\//g')
    FLOW=$(echo "$LINK" | grep -oP 'flow=[^&]+' | cut -d= -f2)

cat > "$CONFIG_FILE" <<EOF
{
  "inbounds": [
    {
      "port": 1080,
      "listen": "127.0.0.1",
      "protocol": "socks",
      "settings": { "udp": true }
    }
  ],
  "outbounds": [
    {
      "protocol": "vless",
      "settings": {
        "vnext": [
          {
            "address": "$HOST",
            "port": $PORT,
            "users": [
              {
                "id": "$UUID",
                "encryption": "none",
                "flow": "$FLOW"
              }
            ]
          }
        ]
      },
      "streamSettings": {
        "network": "tcp",
        "security": "reality",
        "realitySettings": {
          "serverName": "$SNI",
          "fingerprint": "$FP",
          "publicKey": "$PUBKEY",
          "shortId": "$SHORTID",
          "spiderX": "$SPX"
        }
      }
    }
  ]
}
EOF

else
# vless without reality
cat > "$CONFIG_FILE" <<EOF
{
  "inbounds": [
    {
      "port": 1080,
      "listen": "127.0.0.1",
      "protocol": "socks",
      "settings": { "udp": true }
    }
  ],
  "outbounds": [
    {
      "protocol": "vless",
      "settings": {
        "vnext": [
          {
            "address": "$HOST",
            "port": $PORT,
            "users": [
              {
                "id": "$UUID",
                "encryption": "none"
              }
            ]
          }
        ]
      },
      "streamSettings": {
        "network": "tcp",
        "security": "none"
      }
    }
  ]
}
EOF
fi

echo "Created config: $CONFIG_FILE"
