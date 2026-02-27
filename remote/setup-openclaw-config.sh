#!/bin/bash
# configure openclaw via cli
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
    log_ok "OpenClaw config skipped (no telegram token)"
    exit 0
fi

log_step "Configuring OpenClaw"

# initialize config
openclaw setup >/dev/null 2>&1 || true

# set model
openclaw config set agents.defaults.model.primary "${OPENCLAW_MODEL}" >/dev/null 2>&1

# configure telegram
openclaw config set channels.telegram.enabled true >/dev/null 2>&1
openclaw config set channels.telegram.botToken "${TELEGRAM_BOT_TOKEN}" >/dev/null 2>&1
openclaw config set channels.telegram.dmPolicy "allowlist" >/dev/null 2>&1
openclaw config set channels.telegram.allowFrom "[\"tg:${TELEGRAM_USER_ID}\"]" >/dev/null 2>&1

# configure web search if api key provided
if [[ -n "$BRAVE_SEARCH_API_KEY" ]]; then
    openclaw config set tools.web.search.provider "brave" >/dev/null 2>&1
    openclaw config set tools.web.search.apiKey "${BRAVE_SEARCH_API_KEY}" >/dev/null 2>&1
fi

log_ok "OpenClaw configured"
