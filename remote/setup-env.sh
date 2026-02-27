#!/bin/bash
# create environment file with api keys
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"
# shellcheck source=common.sh
source ./common.sh

OPENROUTER_API_KEY="${OPENROUTER_API_KEY:?OPENROUTER_API_KEY required}"
OPENAI_API_KEY="${OPENAI_API_KEY:-}"
ELEVENLABS_API_KEY="${ELEVENLABS_API_KEY:-}"

log_step "Creating environment file"
cat > /opt/openclaw/.env << EOF
OPENROUTER_API_KEY=${OPENROUTER_API_KEY}
OPENAI_API_KEY=${OPENAI_API_KEY}
ELEVENLABS_API_KEY=${ELEVENLABS_API_KEY}
EOF
chmod 600 /opt/openclaw/.env
log_ok "Environment file created"
