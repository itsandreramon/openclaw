#!/bin/bash
# install openclaw and puppeteer
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

log_step "Installing OpenClaw..."
npm install -g openclaw@latest puppeteer >/dev/null 2>&1 || log_fail "OpenClaw install failed"
OPENCLAW_VERSION=$(openclaw --version 2>/dev/null || echo "unknown")
log_ok "OpenClaw ${OPENCLAW_VERSION} installed"

log_step "Creating OpenClaw directories..."
mkdir -p /root/.openclaw/{workspace,identity,skills}
log_ok "Directories created"

log_step "Creating base config..."
CHROME_PATH=$(find /root/.cache/puppeteer -name "chrome" -type f 2>/dev/null | head -1 || true)
cat > /root/.openclaw/openclaw.json << EOF
{
  "browser": {
    "enabled": true,
    "evaluateEnabled": true,
    "headless": false,
    "noSandbox": true,
    "executablePath": "${CHROME_PATH:-}"
  }
}
EOF
log_ok "Base config created"
