#!/bin/bash
# OpenClaw VPS Init Script
# Runs on the VPS to set up all components
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

# shellcheck source=common.sh
source ./common.sh

# run each setup phase
./setup-swap.sh

TAILSCALE_IP=$(./setup-tailscale.sh | tail -1)
export TAILSCALE_IP

./setup-openclaw.sh
./setup-env.sh
./setup-cron.sh

# firewall last - locks out public SSH
./setup-firewall.sh

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
echo "2. Run OpenClaw Docker setup:"
echo "   cd /opt/openclaw"
echo "   export OPENCLAW_HOME_VOLUME=\"openclaw_home\""
echo "   export OPENCLAW_DOCKER_APT_PACKAGES=\"git curl jq\""
echo "   ./docker-setup.sh"
echo ""
echo "3. Install Playwright browser:"
echo "   docker compose run --rm openclaw-cli node /app/node_modules/playwright-core/cli.js install chromium"
echo ""
echo "4. Follow the onboarding wizard prompts"
echo ""
echo "5. Access dashboard:"
echo "   http://${TAILSCALE_IP}:18789"
echo "   (or via tunnel: ssh -L 18789:localhost:18789 root@${TAILSCALE_IP})"
echo ""
echo "SECURITY:"
echo "- SSH restricted to: ${MACBOOK_TAILSCALE_IP}"
echo "- All other access via Tailscale only"
echo "- Auto-updates: daily 3am UTC"
echo "=============================================="
