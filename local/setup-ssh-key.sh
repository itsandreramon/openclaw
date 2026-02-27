#!/bin/bash
# find local ssh key and upload to hetzner if needed
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"
# shellcheck source=common.sh
source ./common.sh

LOCAL_SSH_KEY=""
for keyfile in ~/.ssh/id_ed25519.pub ~/.ssh/id_rsa.pub; do
    if [[ -f "$keyfile" ]]; then
        LOCAL_SSH_KEY="$keyfile"
        break
    fi
done

if [[ -z "$LOCAL_SSH_KEY" ]]; then
    log_fail "No SSH key found. Generate with: ssh-keygen -t ed25519"
fi

LOCAL_FINGERPRINT=$(ssh-keygen -E md5 -lf "${LOCAL_SSH_KEY}" | awk '{print $2}' | sed 's/^MD5://')
EXISTING_KEY=$(hcloud ssh-key list -o json | jq -r ".[] | select(.fingerprint == \"${LOCAL_FINGERPRINT}\") | .name" | head -1)

if [[ -n "$EXISTING_KEY" ]]; then
    SSH_KEY_NAME="$EXISTING_KEY"
else
    SSH_KEY_NAME="$(hostname)-openclaw"
    hcloud ssh-key create --name "${SSH_KEY_NAME}" --public-key-from-file "${LOCAL_SSH_KEY}" >/dev/null || log_fail "Failed to upload SSH key"
fi

log_ok "SSH key ready (${SSH_KEY_NAME})"
echo "${SSH_KEY_NAME}"
