#!/bin/bash
# OpenClaw Local Setup Script
# Run this on your Mac to provision a fresh Hetzner VPS and configure OpenClaw
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

# shellcheck source=local/common.sh
source ./local/common.sh

# === Load .env file if present ===
if [[ -f ./.env ]]; then
    set -a
    # shellcheck source=/dev/null
    source ./.env
    set +a
fi

echo ""
echo "=============================================="
echo -e "${CYAN}OpenClaw VPS Setup${NC}"
echo "=============================================="
echo ""

# === Check hcloud ===
# shellcheck source=local/check-hcloud.sh
source ./local/check-hcloud.sh

# === Server configuration ===
echo ""
log_step "Server Configuration"

echo -ne "${YELLOW}[INPUT]${NC} Server name (default: openclaw): "
read -r SERVER_NAME
SERVER_NAME="${SERVER_NAME:-openclaw}"

echo ""
echo "Available server types (recommended for OpenClaw):"
echo "  cpx12  - 1 vCPU, 2GB RAM  (~€4/mo) - minimum"
echo "  cpx22  - 2 vCPU, 4GB RAM  (~€8/mo) - recommended"
echo "  cpx32  - 4 vCPU, 8GB RAM  (~€15/mo) - comfortable"
echo ""
echo -ne "${YELLOW}[INPUT]${NC} Server type (default: cpx22): "
read -r SERVER_TYPE
SERVER_TYPE="${SERVER_TYPE:-cpx22}"

echo ""
echo "Available locations:"
echo "  fsn1 - Falkenstein, DE"
echo "  nbg1 - Nuremberg, DE"
echo "  hel1 - Helsinki, FI"
echo "  ash  - Ashburn, US"
echo "  hil  - Hillsboro, US"
echo ""
echo -ne "${YELLOW}[INPUT]${NC} Location (default: nbg1): "
read -r SERVER_LOCATION
SERVER_LOCATION="${SERVER_LOCATION:-nbg1}"

# === SSH Key ===
SSH_KEY_NAME=$(./local/setup-ssh-key.sh | tail -1)

# === Gather API keys ===
echo ""
log_step "API Keys Configuration"
echo "Leave blank to use value from .env or skip optional keys."
echo ""

if [[ -n "${TAILSCALE_AUTH_KEY:-}" ]]; then
    log_ok "Tailscale auth key loaded from .env"
else
    echo -ne "${YELLOW}[INPUT]${NC} Tailscale auth key (from admin.tailscale.com): "
    read -r TAILSCALE_AUTH_KEY
    [[ -z "$TAILSCALE_AUTH_KEY" ]] && log_fail "Tailscale auth key is required"
fi

if [[ -n "${OPENROUTER_API_KEY:-}" ]]; then
    log_ok "OpenRouter API key loaded from .env"
else
    echo -ne "${YELLOW}[INPUT]${NC} OpenRouter API key: "
    read -r OPENROUTER_API_KEY
    [[ -z "$OPENROUTER_API_KEY" ]] && log_fail "OpenRouter API key is required"
fi

# get local tailscale ip for firewall config
log_step "Detecting your Mac's Tailscale IP..."
MACBOOK_TAILSCALE_IP=""
if command -v tailscale &>/dev/null; then
    MACBOOK_TAILSCALE_IP=$(tailscale ip -4 2>/dev/null || true)
fi

if [[ -z "${MACBOOK_TAILSCALE_IP}" ]]; then
    echo -ne "${YELLOW}[INPUT]${NC} Your Mac's Tailscale IP (for SSH access): "
    read -r MACBOOK_TAILSCALE_IP
    [[ -z "$MACBOOK_TAILSCALE_IP" ]] && log_fail "Mac Tailscale IP is required"
else
    log_ok "Detected: ${MACBOOK_TAILSCALE_IP}"
fi

if [[ -n "${OPENAI_API_KEY:-}" ]]; then
    log_ok "OpenAI API key loaded from .env"
else
    echo -ne "${YELLOW}[INPUT]${NC} OpenAI API key (optional): "
    read -r OPENAI_API_KEY
fi

if [[ -n "${ELEVENLABS_API_KEY:-}" ]]; then
    log_ok "ElevenLabs API key loaded from .env"
else
    echo -ne "${YELLOW}[INPUT]${NC} ElevenLabs API key (optional): "
    read -r ELEVENLABS_API_KEY
fi

# === Confirmation ===
echo ""
echo "=============================================="
echo -e "${YELLOW}Review Configuration${NC}"
echo "=============================================="
echo "Server name:     ${SERVER_NAME}"
echo "Server type:     ${SERVER_TYPE}"
echo "Location:        ${SERVER_LOCATION}"
echo "SSH key:         ${SSH_KEY_NAME}"
echo "Mac Tailscale:   ${MACBOOK_TAILSCALE_IP}"
echo "=============================================="
echo ""
echo -ne "${YELLOW}[INPUT]${NC} Proceed with server creation? (y/N): "
read -r CONFIRM
[[ ! "$CONFIRM" =~ ^[Yy]$ ]] && log_fail "Aborted by user"

# === Create server ===
VPS_HOST=$(./local/create-server.sh "${SERVER_NAME}" "${SERVER_TYPE}" "${SERVER_LOCATION}" "${SSH_KEY_NAME}" | tail -1)

# === Wait for SSH ===
./local/wait-for-ssh.sh "${VPS_HOST}"

# === Upload and run setup script ===
log_step "Uploading remote scripts to VPS..."
scp -o StrictHostKeyChecking=accept-new -r ./remote "root@${VPS_HOST}:/tmp/" || log_fail "Failed to upload scripts"
log_ok "Scripts uploaded"

log_step "Running setup on VPS (this may take a few minutes)..."
echo "=============================================="
echo ""

# run the init script with environment variables
ssh -t "root@${VPS_HOST}" "
    export TAILSCALE_AUTH_KEY='${TAILSCALE_AUTH_KEY}'
    export OPENROUTER_API_KEY='${OPENROUTER_API_KEY}'
    export MACBOOK_TAILSCALE_IP='${MACBOOK_TAILSCALE_IP}'
    export OPENAI_API_KEY='${OPENAI_API_KEY:-}'
    export ELEVENLABS_API_KEY='${ELEVENLABS_API_KEY:-}'
    chmod +x /tmp/remote/*.sh
    /tmp/remote/init.sh
"

SSH_EXIT_CODE=$?

echo ""
if [[ $SSH_EXIT_CODE -eq 0 ]]; then
    echo "=============================================="
    echo -e "${GREEN}SETUP COMPLETE${NC}"
    echo "=============================================="
    echo ""
    echo "Server: ${SERVER_NAME}"
    echo "Public IP: ${VPS_HOST}"
    echo ""
    echo "Once Tailscale is connected, you can access via:"
    echo "  ssh root@<tailscale-ip>"
    echo ""
    log_ok "VPS setup completed successfully!"
else
    log_fail "VPS setup failed with exit code ${SSH_EXIT_CODE}"
fi
