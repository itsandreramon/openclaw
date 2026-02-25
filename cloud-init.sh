#!/bin/bash
# OpenClaw VPS Setup Script
# Minimal, secure infrastructure setup - config done manually via SSH
set -euo pipefail

# === Colors ===
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_step() { echo -e "\n${YELLOW}[STEP]${NC} $1"; }
log_ok() { echo -e "${GREEN}[OK]${NC} $1"; }
log_fail() { echo -e "${RED}[FAIL]${NC} $1"; exit 1; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

# === Prompt for input if not set ===
prompt_required() {
    local var_name="$1"
    local prompt_text="$2"
    local current_value="${!var_name:-}"

    if [[ -z "$current_value" ]]; then
        echo -ne "${YELLOW}[INPUT]${NC} ${prompt_text}: "
        read -r current_value
        [[ -z "$current_value" ]] && log_fail "${var_name} is required"
    fi
    eval "${var_name}='${current_value}'"
}

prompt_optional() {
    local var_name="$1"
    local prompt_text="$2"
    local current_value="${!var_name:-}"

    if [[ -z "$current_value" ]]; then
        echo -ne "${YELLOW}[INPUT]${NC} ${prompt_text} (optional, press Enter to skip): "
        read -r current_value
    fi
    eval "${var_name}='${current_value}'"
}

# === Configuration (from env or prompt) ===
TAILSCALE_AUTH_KEY="${TAILSCALE_AUTH_KEY:-}"
OPENROUTER_API_KEY="${OPENROUTER_API_KEY:-}"
OPENAI_API_KEY="${OPENAI_API_KEY:-}"
ELEVENLABS_API_KEY="${ELEVENLABS_API_KEY:-}"
MACBOOK_TAILSCALE_IP="${MACBOOK_TAILSCALE_IP:-}"

log_step "Gathering configuration..."
echo "Pre-set values via environment variables will be used automatically."
echo ""

prompt_required "TAILSCALE_AUTH_KEY" "Tailscale auth key (from admin.tailscale.com)"
prompt_required "OPENROUTER_API_KEY" "OpenRouter API key"
prompt_required "MACBOOK_TAILSCALE_IP" "Your MacBook's Tailscale IP (for SSH access)"
prompt_optional "OPENAI_API_KEY" "OpenAI API key"
prompt_optional "ELEVENLABS_API_KEY" "ElevenLabs API key"

log_ok "Configuration gathered"

# === Setup swap ===
log_step "Setting up 4GB swap..."
if [[ ! -f /swapfile ]]; then
    fallocate -l 4G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile >/dev/null
    swapon /swapfile
    echo '/swapfile none swap sw 0 0' >> /etc/fstab
    log_ok "Swap configured"
else
    log_ok "Swap already exists"
fi

# === Install Tailscale ===
log_step "Installing Tailscale..."
if ! command -v tailscale &>/dev/null; then
    curl -fsSL https://tailscale.com/install.sh | sh >/dev/null 2>&1 || log_fail "Tailscale install failed"
fi
tailscale up --authkey="${TAILSCALE_AUTH_KEY}" --ssh >/dev/null 2>&1 || log_fail "Tailscale authentication failed"
TAILSCALE_IP=$(tailscale ip -4 2>/dev/null) || log_fail "Could not get Tailscale IP"
log_ok "Tailscale connected (IP: ${TAILSCALE_IP})"

# === Install Node.js 22 ===
log_step "Installing Node.js 22..."
apt-get update -qq >/dev/null 2>&1
curl -fsSL https://deb.nodesource.com/setup_22.x 2>/dev/null | bash - >/dev/null 2>&1 || log_fail "NodeSource setup failed"
apt-get install -y -qq nodejs xvfb jq ufw >/dev/null 2>&1 || log_fail "Node.js install failed"
NODE_VERSION=$(node --version 2>/dev/null)
log_ok "Node.js ${NODE_VERSION} installed"

# === Install Chrome dependencies ===
log_step "Installing browser dependencies..."
apt-get install -y -qq \
    libnss3 libnspr4 libatk1.0-0 libatk-bridge2.0-0 libcups2 libdrm2 \
    libxkbcommon0 libxcomposite1 libxdamage1 libxfixes3 libxrandr2 libgbm1 \
    libasound2t64 libcairo2 libpango-1.0-0 libpangocairo-1.0-0 fonts-liberation \
    >/dev/null 2>&1 || log_fail "Browser dependencies install failed"
log_ok "Browser dependencies installed"

# === Configure UFW ===
log_step "Configuring firewall..."
ufw --force reset >/dev/null 2>&1
ufw default deny incoming >/dev/null 2>&1
ufw default allow outgoing >/dev/null 2>&1

# allow ssh only from macbook tailscale ip
ufw allow from "${MACBOOK_TAILSCALE_IP}" to any port 22 proto tcp >/dev/null 2>&1

# allow all traffic on tailscale interface (for openclaw gateway access)
ufw allow in on tailscale0 >/dev/null 2>&1

echo "y" | ufw enable >/dev/null 2>&1 || log_fail "UFW enable failed"
log_ok "Firewall configured (SSH restricted to ${MACBOOK_TAILSCALE_IP})"

# === Install OpenClaw ===
log_step "Installing OpenClaw..."
npm install -g openclaw@latest puppeteer >/dev/null 2>&1 || log_fail "OpenClaw install failed"
OPENCLAW_VERSION=$(openclaw --version 2>/dev/null || echo "unknown")
log_ok "OpenClaw ${OPENCLAW_VERSION} installed"

# === Create directories ===
log_step "Creating OpenClaw directories..."
mkdir -p /root/.openclaw/{workspace,identity,skills}
log_ok "Directories created"

# === Create base config ===
log_step "Creating base config..."
CHROME_PATH=$(find /root/.cache/puppeteer -name "chrome" -type f 2>/dev/null | head -1 || true)
cat > /root/.openclaw/openclaw.json << EOF
{
  "browser": {
    "enabled": true,
    "evaluateEnabled": true,
    "headless": false,
    "noSandbox": true,
    "executablePath": "${CHROME_PATH:-}"
  }
}
EOF
log_ok "Base config created"

# === Create environment file ===
log_step "Creating environment file..."
cat > /etc/openclaw.env << EOF
OPENCLAW_CONFIG_DIR=/root/.openclaw
OPENROUTER_API_KEY=${OPENROUTER_API_KEY}
OPENAI_API_KEY=${OPENAI_API_KEY}
ELEVENLABS_API_KEY=${ELEVENLABS_API_KEY}
GOG_KEYRING_PASSWORD=openclaw
EOF
chmod 600 /etc/openclaw.env
log_ok "Environment file created"

# === Create systemd service ===
log_step "Creating systemd service..."
cat > /etc/systemd/system/openclaw.service << 'EOF'
[Unit]
Description=OpenClaw Gateway
After=network.target tailscaled.service
Wants=tailscaled.service

[Service]
Type=simple
User=root
EnvironmentFile=/etc/openclaw.env
ExecStart=/usr/bin/xvfb-run -a /usr/bin/openclaw gateway
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload >/dev/null 2>&1
systemctl enable openclaw >/dev/null 2>&1
log_ok "Systemd service created and enabled"

# === Create update script ===
log_step "Creating auto-update script..."
cat > /usr/local/bin/openclaw-update.sh << 'EOF'
#!/bin/bash
set -euo pipefail
LOG="/var/log/openclaw-update.log"
echo "[$(date -Iseconds)] Starting update" >> "$LOG"
openclaw update --channel stable >> "$LOG" 2>&1 && systemctl restart openclaw
echo "[$(date -Iseconds)] Update complete" >> "$LOG"
EOF
chmod +x /usr/local/bin/openclaw-update.sh
log_ok "Update script created"

# === Setup cronjob ===
log_step "Setting up nightly update cronjob..."
(crontab -l 2>/dev/null | grep -v openclaw-update; echo "0 3 * * * /usr/local/bin/openclaw-update.sh") | crontab -
log_ok "Cronjob configured (daily 3am UTC)"

# === Summary ===
echo ""
echo "=============================================="
echo -e "${GREEN}SETUP COMPLETE${NC}"
echo "=============================================="
echo ""
echo "VPS Tailscale IP: ${TAILSCALE_IP}"
echo ""
echo "NEXT STEPS:"
echo "1. SSH into the VPS:"
echo "   ssh root@${TAILSCALE_IP}"
echo ""
echo "2. Run OpenClaw onboarding wizard:"
echo "   openclaw onboard"
echo ""
echo "3. When prompted, use these settings:"
echo "   - Gateway bind: lan"
echo "   - Gateway auth: token"
echo "   - Gateway token: (press Enter for auto-generated)"
echo "   - Tailscale exposure: Off"
echo "   - Install Gateway daemon: No"
echo "   - Model provider: openrouter"
echo ""
echo "4. Start the gateway:"
echo "   systemctl start openclaw"
echo ""
echo "5. Get your gateway token:"
echo "   cat /root/.openclaw/openclaw.json | jq -r '.gateway.token'"
echo ""
echo "6. Access dashboard:"
echo "   http://${TAILSCALE_IP}:18789"
echo "   (or via tunnel: ssh -L 18789:localhost:18789 root@${TAILSCALE_IP})"
echo ""
echo "SECURITY:"
echo "- SSH restricted to: ${MACBOOK_TAILSCALE_IP}"
echo "- All other access via Tailscale only"
echo "- Auto-updates: daily 3am UTC"
echo "=============================================="
