#!/bin/bash
# create openclaw configuration file
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"
# shellcheck source=common.sh
source ./common.sh

TELEGRAM_BOT_TOKEN="${TELEGRAM_BOT_TOKEN:-}"
TELEGRAM_USER_ID="${TELEGRAM_USER_ID:-}"
OPENCLAW_MODEL="${OPENCLAW_MODEL:-openrouter/minimax/MiniMax-M1}"
BRAVE_SEARCH_API_KEY="${BRAVE_SEARCH_API_KEY:-}"

# skip if no telegram config provided
if [[ -z "$TELEGRAM_BOT_TOKEN" ]]; then
    log_ok "OpenClaw config skipped (no telegram token)"
    exit 0
fi

log_step "Creating OpenClaw config"

mkdir -p /root/.openclaw

cat > /root/.openclaw/openclaw.json << EOF
{
  "agents": {
    "defaults": {
      "model": {
        "primary": "${OPENCLAW_MODEL}"
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
  },
  "tools": {
    "web": {
      "search": {
        "provider": "brave",
        "apiKey": "${BRAVE_SEARCH_API_KEY}"
      }
    }
  }
}
EOF

chmod 600 /root/.openclaw/openclaw.json
log_ok "OpenClaw config created"
