#!/bin/bash
# configure ufw firewall
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

MACBOOK_TAILSCALE_IP="${MACBOOK_TAILSCALE_IP:?MACBOOK_TAILSCALE_IP required}"

log_step "Configuring firewall..."
ufw --force reset >/dev/null 2>&1
ufw default deny incoming >/dev/null 2>&1
ufw default allow outgoing >/dev/null 2>&1

# allow ssh only from macbook tailscale ip
ufw allow from "${MACBOOK_TAILSCALE_IP}" to any port 22 proto tcp >/dev/null 2>&1

# allow all traffic on tailscale interface
ufw allow in on tailscale0 >/dev/null 2>&1

echo "y" | ufw enable >/dev/null 2>&1 || log_fail "UFW enable failed"
log_ok "Firewall configured (SSH restricted to ${MACBOOK_TAILSCALE_IP})"
