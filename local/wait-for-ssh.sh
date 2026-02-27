#!/bin/bash
# wait for server ssh to become available
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"
# shellcheck source=common.sh
source ./common.sh

VPS_HOST="${1:?VPS host required}"
MAX_ATTEMPTS="${2:-30}"

log_step "Waiting for SSH"
ATTEMPT=0
while [[ $ATTEMPT -lt $MAX_ATTEMPTS ]]; do
    if ssh -o ConnectTimeout=5 -o BatchMode=yes -o StrictHostKeyChecking=accept-new "root@${VPS_HOST}" "echo ok" &>/dev/null; then
        break
    fi
    ATTEMPT=$((ATTEMPT + 1))
    sleep 5
done

if [[ $ATTEMPT -ge $MAX_ATTEMPTS ]]; then
    log_fail "Server not accessible after ${MAX_ATTEMPTS} attempts"
fi
log_ok "SSH connected (${VPS_HOST})"
