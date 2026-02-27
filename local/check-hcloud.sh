#!/bin/bash
# check hcloud cli is installed and authenticated
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

if ! command -v hcloud &>/dev/null; then
    log_fail "hcloud CLI not found. Install with: brew install hcloud"
fi

log_step "Checking Hetzner CLI authentication..."
if ! hcloud context active &>/dev/null; then
    log_warn "No active hcloud context. Run: hcloud context create <name>"
    log_fail "hcloud not authenticated"
fi

HCLOUD_CONTEXT=$(hcloud context active)
log_ok "Using hcloud context: ${HCLOUD_CONTEXT}"
