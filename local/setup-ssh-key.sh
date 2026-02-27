#!/bin/bash
# find local ssh key and upload to hetzner if needed
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

log_step "SSH Key Configuration"

# find local ssh public key
LOCAL_SSH_KEY=""
for keyfile in ~/.ssh/id_ed25519.pub ~/.ssh/id_rsa.pub; do
    if [[ -f "$keyfile" ]]; then
        LOCAL_SSH_KEY="$keyfile"
        break
    fi
done

if [[ -z "$LOCAL_SSH_KEY" ]]; then
    log_fail "No SSH public key found in ~/.ssh/. Generate one with: ssh-keygen -t ed25519"
fi
log_ok "Found local SSH key: ${LOCAL_SSH_KEY}"

# compute fingerprint (hetzner uses md5 hex format)
LOCAL_FINGERPRINT=$(ssh-keygen -E md5 -lf "${LOCAL_SSH_KEY}" | awk '{print $2}' | sed 's/^MD5://')

# check if key exists in hetzner
EXISTING_KEY=$(hcloud ssh-key list -o json | jq -r ".[] | select(.fingerprint == \"${LOCAL_FINGERPRINT}\") | .name" | head -1)

if [[ -n "$EXISTING_KEY" ]]; then
    SSH_KEY_NAME="$EXISTING_KEY"
    log_ok "SSH key already exists in Hetzner as '${SSH_KEY_NAME}'"
else
    SSH_KEY_NAME="$(hostname)-openclaw"
    log_step "Uploading SSH key to Hetzner as '${SSH_KEY_NAME}'..."
    hcloud ssh-key create --name "${SSH_KEY_NAME}" --public-key-from-file "${LOCAL_SSH_KEY}" || log_fail "Failed to upload SSH key"
    log_ok "SSH key uploaded"
fi

# export for parent script
echo "${SSH_KEY_NAME}"
