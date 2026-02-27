#!/bin/bash
# create hetzner server
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

SERVER_NAME="${1:?Server name required}"
SERVER_TYPE="${2:?Server type required}"
SERVER_LOCATION="${3:?Server location required}"
SSH_KEY_NAME="${4:?SSH key name required}"

log_step "Creating Hetzner server '${SERVER_NAME}'..."

# check if server exists
if hcloud server describe "${SERVER_NAME}" &>/dev/null; then
    log_warn "Server '${SERVER_NAME}' already exists"
    echo -ne "${YELLOW}[INPUT]${NC} Delete and recreate? (y/N): "
    read -r DELETE_CONFIRM
    if [[ "$DELETE_CONFIRM" =~ ^[Yy]$ ]]; then
        log_step "Deleting existing server..."
        hcloud server delete "${SERVER_NAME}" || log_fail "Failed to delete server"
        log_ok "Server deleted"
        sleep 2
    else
        log_fail "Server already exists. Use a different name or delete manually."
    fi
fi

hcloud server create \
    --name "${SERVER_NAME}" \
    --type "${SERVER_TYPE}" \
    --location "${SERVER_LOCATION}" \
    --image ubuntu-24.04 \
    --ssh-key "${SSH_KEY_NAME}" \
    || log_fail "Failed to create server"

log_ok "Server created"

VPS_HOST=$(hcloud server ip "${SERVER_NAME}")
log_ok "Server IP: ${VPS_HOST}"

echo "${VPS_HOST}"
