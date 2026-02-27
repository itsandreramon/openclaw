#!/bin/bash
# create hetzner server
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"
# shellcheck source=common.sh
source ./common.sh

SERVER_NAME="${1:?Server name required}"
SERVER_TYPE="${2:?Server type required}"
SERVER_LOCATION="${3:?Server location required}"
SSH_KEY_NAME="${4:?SSH key name required}"

log_step "Creating server"

if hcloud server describe "${SERVER_NAME}" &>/dev/null; then
    hcloud server delete "${SERVER_NAME}" >/dev/null || log_fail "Failed to delete existing server"
    sleep 2
fi

hcloud server create \
    --name "${SERVER_NAME}" \
    --type "${SERVER_TYPE}" \
    --location "${SERVER_LOCATION}" \
    --image ubuntu-24.04 \
    --ssh-key "${SSH_KEY_NAME}" \
    >/dev/null 2>&1 || log_fail "Failed to create server"

VPS_HOST=$(hcloud server ip "${SERVER_NAME}")
ssh-keygen -R "${VPS_HOST}" 2>/dev/null || true

log_ok "Server created (${VPS_HOST})"
echo "${VPS_HOST}"
