#!/bin/bash
# check hcloud cli is installed and authenticated
set -euo pipefail

_ORIG_DIR="$PWD"
cd "$(dirname "${BASH_SOURCE[0]}")"
# shellcheck source=common.sh
source ./common.sh
cd "$_ORIG_DIR"

if ! command -v hcloud &>/dev/null; then
    log_fail "hcloud CLI not found. Install with: brew install hcloud"
fi

if ! hcloud context active &>/dev/null; then
    log_fail "hcloud not authenticated. Run: hcloud context create <name>"
fi

HCLOUD_CONTEXT=$(hcloud context active)
log_ok "Hetzner CLI authenticated (${HCLOUD_CONTEXT})"
