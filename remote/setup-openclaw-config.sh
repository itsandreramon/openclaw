#!/bin/bash
# configure openclaw via config file
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"
# shellcheck source=common.sh
source ./common.sh

TELEGRAM_BOT_TOKEN="${TELEGRAM_BOT_TOKEN:-}"
TELEGRAM_USER_ID="${TELEGRAM_USER_ID:-}"
OPENCLAW_MODEL="${OPENCLAW_MODEL:-openrouter/minimax/minimax-m2.5}"
BRAVE_SEARCH_API_KEY="${BRAVE_SEARCH_API_KEY:-}"

# skip if no telegram config provided
if [[ -z "$TELEGRAM_BOT_TOKEN" ]]; then
    exit 0
fi

mkdir -p /root/.openclaw

# build web search config if api key provided
WEB_SEARCH_CONFIG=""
if [[ -n "$BRAVE_SEARCH_API_KEY" ]]; then
    WEB_SEARCH_CONFIG=',
  "tools": {
    "web": {
      "search": {
        "provider": "brave",
        "apiKey": "'"${BRAVE_SEARCH_API_KEY}"'"
      }
    }
  }'
fi

cat > /root/.openclaw/openclaw.json << EOF
{
  "agents": {
    "defaults": {
      "model": {
        "primary": "${OPENCLAW_MODEL}",
        "fallbacks": ["meta-llama/llama-3.3-70b-instruct:free"]
      }
    }
  },
  "channels": {
    "telegram": {
      "enabled": true,
      "botToken": "${TELEGRAM_BOT_TOKEN}",
      "dmPolicy": "allowlist",
      "allowFrom": ["tg:${TELEGRAM_USER_ID}"]
    }
  }${WEB_SEARCH_CONFIG}
}
EOF

chmod 600 /root/.openclaw/openclaw.json
