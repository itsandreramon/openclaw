#!/bin/bash
# install node.js 22 and browser dependencies
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

log_step "Installing Node.js 22..."
apt-get update -qq >/dev/null 2>&1
curl -fsSL https://deb.nodesource.com/setup_22.x 2>/dev/null | bash - >/dev/null 2>&1 || log_fail "NodeSource setup failed"
apt-get install -y -qq nodejs xvfb jq ufw >/dev/null 2>&1 || log_fail "Node.js install failed"
NODE_VERSION=$(node --version 2>/dev/null)
log_ok "Node.js ${NODE_VERSION} installed"

log_step "Installing browser dependencies..."
apt-get install -y -qq \
    libnss3 libnspr4 libatk1.0-0 libatk-bridge2.0-0 libcups2 libdrm2 \
    libxkbcommon0 libxcomposite1 libxdamage1 libxfixes3 libxrandr2 libgbm1 \
    libasound2t64 libcairo2 libpango-1.0-0 libpangocairo-1.0-0 fonts-liberation \
    >/dev/null 2>&1 || log_fail "Browser dependencies install failed"
log_ok "Browser dependencies installed"
