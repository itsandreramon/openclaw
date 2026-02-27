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
    # backup openclaw config before deleting
    # try tailscale hostname first (firewall blocks public IP), then fall back to public IP
    for BACKUP_IP in "${SERVER_NAME}" "$(hcloud server ip "${SERVER_NAME}")"; do
        if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no "root@${BACKUP_IP}" "test -f /root/.openclaw/openclaw.json" 2>/dev/null; then
            mkdir -p ../backups
            BACKUP_FILE="../backups/openclaw-$(date +%Y%m%d-%H%M%S).json"
            scp -o ConnectTimeout=5 -o StrictHostKeyChecking=no "root@${BACKUP_IP}:/root/.openclaw/openclaw.json" "${BACKUP_FILE}" 2>/dev/null
            log_ok "Config backed up to ${BACKUP_FILE}"
            break
        fi
    done
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
