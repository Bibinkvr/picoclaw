#!/bin/sh
set -e

mkdir -p /home/picoclaw/.picoclaw

cat > /home/picoclaw/.picoclaw/config.json << EOF
{
  "agents": {
    "defaults": {
      "model_name": "mymodel",
      "workspace": "/home/picoclaw/.picoclaw/workspace",
      "max_tokens": 8192,
      "temperature": 0.7,
      "max_tool_iterations": 20
    }
  },
  "model_list": [
    {
      "model_name": "mymodel",
      "model": "${LLM_MODEL}",
      "api_key": "${LLM_API_KEY}"
    }
  ],
  "channels": {
    "telegram": {
      "enabled": true,
      "token": "${TELEGRAM_TOKEN}",
      "allow_from": [${TELEGRAM_ALLOW_FROM}]
    }
  },
  "tools": {
    "web": {
      "duckduckgo": { "enabled": true, "max_results": 5 }
    }
  }
}
EOF

exec picoclaw gateway
