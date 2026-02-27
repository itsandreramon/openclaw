#!/bin/bash
# install and configure tailscale
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"
# shellcheck source=common.sh
source ./common.sh

TAILSCALE_AUTH_KEY="${TAILSCALE_AUTH_KEY:?TAILSCALE_AUTH_KEY required}"

if ! command -v tailscale &>/dev/null; then
    curl -fsSL https://tailscale.com/install.sh | sh >/dev/null 2>&1 || log_fail "install failed"
fi
tailscale up --authkey="${TAILSCALE_AUTH_KEY}" --ssh >/dev/null 2>&1 || log_fail "auth failed"
TAILSCALE_IP=$(tailscale ip -4 2>/dev/null) || log_fail "could not get IP"

echo "${TAILSCALE_IP}"
