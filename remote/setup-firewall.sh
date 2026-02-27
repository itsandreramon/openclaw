#!/bin/bash
# configure ufw firewall
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"
# shellcheck source=common.sh
source ./common.sh

MACBOOK_TAILSCALE_IP="${MACBOOK_TAILSCALE_IP:?MACBOOK_TAILSCALE_IP required}"

ufw --force reset >/dev/null 2>&1
ufw default deny incoming >/dev/null 2>&1
ufw default allow outgoing >/dev/null 2>&1
ufw allow from "${MACBOOK_TAILSCALE_IP}" to any port 22 proto tcp >/dev/null 2>&1
ufw allow in on tailscale0 >/dev/null 2>&1
echo "y" | ufw enable >/dev/null 2>&1 || log_fail "ufw enable failed"
