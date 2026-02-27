#!/bin/bash
# OpenClaw VPS Init Script
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

# shellcheck source=common.sh
source ./common.sh

./setup-swap.sh

TAILSCALE_IP=$(./setup-tailscale.sh | tail -1)
export TAILSCALE_IP

./setup-openclaw.sh
./setup-env.sh
./setup-cron.sh

# summary before firewall cuts public SSH
echo ""
echo "=============================================="
echo -e "${GREEN}VPS SETUP COMPLETE${NC}"
echo "=============================================="
echo ""
echo "Tailscale IP: ${TAILSCALE_IP}"
echo ""
echo "Next steps:"
echo "  ssh root@${TAILSCALE_IP}"
echo "  cd /opt/openclaw"
echo "  ./docker-setup.sh"
echo ""
echo "Dashboard: http://${TAILSCALE_IP}:18789"
echo "=============================================="
echo ""

./setup-firewall.sh
