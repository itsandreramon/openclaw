#!/bin/bash
# OpenClaw Local Setup Script
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

# shellcheck source=local/common.sh
source ./local/common.sh

if [[ -f ./.env ]]; then
    set -a
    # shellcheck source=/dev/null
    source ./.env
    set +a
fi

# === Check hcloud ===
# shellcheck source=local/check-hcloud.sh
source ./local/check-hcloud.sh

# === Server name ===
echo ""
echo -ne "Server name (default: openclaw): "
read -r SERVER_NAME
SERVER_NAME="${SERVER_NAME:-openclaw}"

# === Fetch and display server types ===
log_step "Fetching server types"
SERVER_TYPES=$(hcloud server-type list -o json | jq -r '.[] | select(.name | startswith("cpx")) | "\(.name)|\(.cores)|\(.memory)|\(.prices[0].price_monthly.gross)"' | sort -t'|' -k4 -n)
log_ok "Server types loaded"

echo ""
echo "Available server types:"
echo ""
printf "  %-8s %-8s %-8s %s\n" "TYPE" "CPU" "RAM" "PRICE"
echo "$SERVER_TYPES" | while IFS='|' read -r name cores mem price; do
    price_fmt=$(printf "%.0f" "$price")
    printf "  %-8s %-8s %-8s ~€%s/mo\n" "$name" "${cores}vCPU" "${mem}GB" "$price_fmt"
done
echo ""
echo -ne "Server type (default: cpx22): "
read -r SERVER_TYPE
SERVER_TYPE="${SERVER_TYPE:-cpx22}"

# === Fetch and display locations ===
log_step "Fetching locations"
LOCATIONS=$(hcloud location list -o json | jq -r '.[] | "\(.name)|\(.city)|\(.country)"')
log_ok "Locations loaded"

echo ""
echo "Available locations:"
echo ""
echo "$LOCATIONS" | while IFS='|' read -r name city country; do
    printf "  %-8s %s, %s\n" "$name" "$city" "$country"
done
echo ""
echo -ne "Location (default: nbg1): "
read -r SERVER_LOCATION
SERVER_LOCATION="${SERVER_LOCATION:-nbg1}"

# === SSH Key ===
SSH_KEY_NAME=$(./local/setup-ssh-key.sh | tail -1)

# === API keys ===
if [[ -n "${TAILSCALE_AUTH_KEY:-}" ]]; then
    log_ok "Tailscale key from .env"
else
    echo -ne "Tailscale auth key: "
    read -r TAILSCALE_AUTH_KEY
    [[ -z "$TAILSCALE_AUTH_KEY" ]] && log_fail "Tailscale auth key required"
fi

if [[ -n "${OPENROUTER_API_KEY:-}" ]]; then
    log_ok "OpenRouter key from .env"
else
    echo -ne "OpenRouter API key: "
    read -r OPENROUTER_API_KEY
    [[ -z "$OPENROUTER_API_KEY" ]] && log_fail "OpenRouter API key required"
fi

MACBOOK_TAILSCALE_IP=""
if command -v tailscale &>/dev/null; then
    MACBOOK_TAILSCALE_IP=$(tailscale ip -4 2>/dev/null || true)
fi
if [[ -z "${MACBOOK_TAILSCALE_IP}" ]]; then
    echo -ne "Your Mac's Tailscale IP: "
    read -r MACBOOK_TAILSCALE_IP
    [[ -z "$MACBOOK_TAILSCALE_IP" ]] && log_fail "Mac Tailscale IP required"
else
    log_ok "Mac Tailscale IP detected (${MACBOOK_TAILSCALE_IP})"
fi

if [[ -n "${OPENAI_API_KEY:-}" ]]; then
    log_ok "OpenAI key from .env"
else
    echo -ne "OpenAI API key (optional): "
    read -r OPENAI_API_KEY
fi

if [[ -n "${ELEVENLABS_API_KEY:-}" ]]; then
    log_ok "ElevenLabs key from .env"
else
    echo -ne "ElevenLabs API key (optional): "
    read -r ELEVENLABS_API_KEY
fi

# === Confirmation ===
echo ""
echo "Server: ${SERVER_NAME} (${SERVER_TYPE}) in ${SERVER_LOCATION}"
echo ""
echo -ne "Proceed? (y/N): "
read -r CONFIRM
[[ ! "$CONFIRM" =~ ^[Yy]$ ]] && log_fail "Aborted"

# === Create server ===
VPS_HOST=$(./local/create-server.sh "${SERVER_NAME}" "${SERVER_TYPE}" "${SERVER_LOCATION}" "${SSH_KEY_NAME}" | tail -1)

# === Wait for SSH ===
./local/wait-for-ssh.sh "${VPS_HOST}"

# === Run remote setup ===
scp -q -o StrictHostKeyChecking=accept-new -r ./remote "root@${VPS_HOST}:/tmp/" || log_fail "Failed to upload scripts"

ssh "root@${VPS_HOST}" "
    export TAILSCALE_AUTH_KEY='${TAILSCALE_AUTH_KEY}'
    export OPENROUTER_API_KEY='${OPENROUTER_API_KEY}'
    export MACBOOK_TAILSCALE_IP='${MACBOOK_TAILSCALE_IP}'
    export OPENAI_API_KEY='${OPENAI_API_KEY:-}'
    export ELEVENLABS_API_KEY='${ELEVENLABS_API_KEY:-}'
    chmod +x /tmp/remote/*.sh
    /tmp/remote/init.sh
"

SSH_EXIT_CODE=$?

if [[ $SSH_EXIT_CODE -eq 0 ]]; then
    log_ok "Setup complete"
else
    log_fail "Setup failed (exit code ${SSH_EXIT_CODE})"
fi
