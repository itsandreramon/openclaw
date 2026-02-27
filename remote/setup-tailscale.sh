#!/bin/bash
# install and configure tailscale
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

TAILSCALE_AUTH_KEY="${TAILSCALE_AUTH_KEY:?TAILSCALE_AUTH_KEY required}"

log_step "Installing Tailscale..."
if ! command -v tailscale &>/dev/null; then
    curl -fsSL https://tailscale.com/install.sh | sh >/dev/null 2>&1 || log_fail "Tailscale install failed"
fi
tailscale up --authkey="${TAILSCALE_AUTH_KEY}" --ssh >/dev/null 2>&1 || log_fail "Tailscale authentication failed"
TAILSCALE_IP=$(tailscale ip -4 2>/dev/null) || log_fail "Could not get Tailscale IP"
log_ok "Tailscale connected (IP: ${TAILSCALE_IP})"

echo "${TAILSCALE_IP}"
