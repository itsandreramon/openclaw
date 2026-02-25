#!/bin/bash
# OpenClaw Local Setup Script
# Run this on your Mac to provision a fresh Hetzner VPS and configure OpenClaw
set -euo pipefail

# === Colors ===
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log_step() { echo -e "\n${CYAN}[LOCAL]${NC} $1"; }
log_ok() { echo -e "${GREEN}[OK]${NC} $1"; }
log_fail() { echo -e "${RED}[FAIL]${NC} $1"; exit 1; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

# === Get script directory ===
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# === Load .env file if present ===
if [[ -f "${SCRIPT_DIR}/.env" ]]; then
    set -a
    # shellcheck source=/dev/null
    source "${SCRIPT_DIR}/.env"
    set +a
fi

echo ""
echo "=============================================="
echo -e "${CYAN}OpenClaw VPS Setup${NC}"
echo "=============================================="
echo ""

# === Check for hcloud CLI ===
if ! command -v hcloud &>/dev/null; then
    log_fail "hcloud CLI not found. Install with: brew install hcloud"
fi

# === Check hcloud context ===
log_step "Checking Hetzner CLI authentication..."
if ! hcloud context active &>/dev/null; then
    log_warn "No active hcloud context. Run: hcloud context create <name>"
    log_fail "hcloud not authenticated"
fi
HCLOUD_CONTEXT=$(hcloud context active)
log_ok "Using hcloud context: ${HCLOUD_CONTEXT}"

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

# compute fingerprint of local key (hetzner uses md5 hex format)
LOCAL_FINGERPRINT=$(ssh-keygen -E md5 -lf "${LOCAL_SSH_KEY}" | awk '{print $2}' | sed 's/^MD5://')

# check if this key already exists in hetzner by fingerprint
EXISTING_KEY=$(hcloud ssh-key list -o json | jq -r ".[] | select(.fingerprint == \"${LOCAL_FINGERPRINT}\") | .name" | head -1)

if [[ -n "$EXISTING_KEY" ]]; then
    SSH_KEY_NAME="$EXISTING_KEY"
    log_ok "SSH key already exists in Hetzner as '${SSH_KEY_NAME}'"
else
    # upload with hostname-based name
    SSH_KEY_NAME="$(hostname)-openclaw"
    log_step "Uploading SSH key to Hetzner as '${SSH_KEY_NAME}'..."
    hcloud ssh-key create --name "${SSH_KEY_NAME}" --public-key-from-file "${LOCAL_SSH_KEY}" || log_fail "Failed to upload SSH key"
    log_ok "SSH key uploaded"
fi

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
log_step "Creating Hetzner server '${SERVER_NAME}'..."

# check if server already exists
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

# create the server
hcloud server create \
    --name "${SERVER_NAME}" \
    --type "${SERVER_TYPE}" \
    --location "${SERVER_LOCATION}" \
    --image ubuntu-24.04 \
    --ssh-key "${SSH_KEY_NAME}" \
    || log_fail "Failed to create server"

log_ok "Server created"

# get server IP
VPS_HOST=$(hcloud server ip "${SERVER_NAME}")
log_ok "Server IP: ${VPS_HOST}"

# === Wait for SSH ===
log_step "Waiting for server to become accessible..."
MAX_ATTEMPTS=30
ATTEMPT=0
while [[ $ATTEMPT -lt $MAX_ATTEMPTS ]]; do
    if ssh -o ConnectTimeout=5 -o BatchMode=yes -o StrictHostKeyChecking=accept-new "root@${VPS_HOST}" "echo 'SSH OK'" &>/dev/null; then
        break
    fi
    ATTEMPT=$((ATTEMPT + 1))
    echo -n "."
    sleep 5
done
echo ""

if [[ $ATTEMPT -ge $MAX_ATTEMPTS ]]; then
    log_fail "Server not accessible after ${MAX_ATTEMPTS} attempts"
fi
log_ok "SSH connection established"

# === Upload and run setup script ===
log_step "Uploading cloud-init script to VPS..."
scp -o StrictHostKeyChecking=accept-new "${SCRIPT_DIR}/cloud-init.sh" "root@${VPS_HOST}:/tmp/cloud-init.sh" || log_fail "Failed to upload script"
log_ok "Script uploaded"

log_step "Running setup on VPS (this may take a few minutes)..."
echo "=============================================="
echo ""

# run the script with environment variables set
ssh -t "root@${VPS_HOST}" "
    export TAILSCALE_AUTH_KEY='${TAILSCALE_AUTH_KEY}'
    export OPENROUTER_API_KEY='${OPENROUTER_API_KEY}'
    export MACBOOK_TAILSCALE_IP='${MACBOOK_TAILSCALE_IP}'
    export OPENAI_API_KEY='${OPENAI_API_KEY:-}'
    export ELEVENLABS_API_KEY='${ELEVENLABS_API_KEY:-}'
    chmod +x /tmp/cloud-init.sh
    /tmp/cloud-init.sh
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
