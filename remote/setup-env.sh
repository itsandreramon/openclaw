#!/bin/bash
# create environment file with api keys
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

OPENROUTER_API_KEY="${OPENROUTER_API_KEY:?OPENROUTER_API_KEY required}"
OPENAI_API_KEY="${OPENAI_API_KEY:-}"
ELEVENLABS_API_KEY="${ELEVENLABS_API_KEY:-}"

log_step "Creating environment file..."
cat > /etc/openclaw.env << EOF
OPENCLAW_CONFIG_DIR=/root/.openclaw
OPENROUTER_API_KEY=${OPENROUTER_API_KEY}
OPENAI_API_KEY=${OPENAI_API_KEY}
ELEVENLABS_API_KEY=${ELEVENLABS_API_KEY}
GOG_KEYRING_PASSWORD=openclaw
EOF
chmod 600 /etc/openclaw.env
log_ok "Environment file created"
