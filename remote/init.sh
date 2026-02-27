#!/bin/bash
# OpenClaw VPS Init Script
# Runs on the VPS to set up all components
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

# run each setup phase
"${SCRIPT_DIR}/setup-swap.sh"

TAILSCALE_IP=$("${SCRIPT_DIR}/setup-tailscale.sh" | tail -1)
export TAILSCALE_IP

"${SCRIPT_DIR}/setup-node.sh"
"${SCRIPT_DIR}/setup-firewall.sh"
"${SCRIPT_DIR}/setup-openclaw.sh"
"${SCRIPT_DIR}/setup-env.sh"
"${SCRIPT_DIR}/setup-systemd.sh"
"${SCRIPT_DIR}/setup-cron.sh"

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
