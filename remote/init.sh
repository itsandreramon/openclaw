#!/bin/bash
# OpenClaw VPS Init Script
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

# shellcheck source=common.sh
source ./common.sh

TOTAL_STEPS=7
CURRENT_STEP=0

run_step() {
    local name="$1"
    local script="$2"
    CURRENT_STEP=$((CURRENT_STEP + 1))
    echo -e "\n${YELLOW}[${CURRENT_STEP}/${TOTAL_STEPS}]${NC} ${name}"
    if $script; then
        echo -e "${GREEN}[OK]${NC} ${name}"
    else
        echo -e "${RED}[FAIL]${NC} ${name}"
        exit 1
    fi
}

run_step "Swap" ./setup-swap.sh

# tailscale needs special handling to capture IP
CURRENT_STEP=$((CURRENT_STEP + 1))
echo -e "\n${YELLOW}[${CURRENT_STEP}/${TOTAL_STEPS}]${NC} Tailscale"
if TAILSCALE_IP=$(./setup-tailscale.sh | tail -1); then
    export TAILSCALE_IP
    echo -e "${GREEN}[OK]${NC} Tailscale (${TAILSCALE_IP})"
else
    echo -e "${RED}[FAIL]${NC} Tailscale"
    exit 1
fi

run_step "Docker & OpenClaw" ./setup-openclaw.sh
run_step "Environment" ./setup-env.sh
run_step "OpenClaw config" ./setup-openclaw-config.sh
run_step "Auto-updates" ./setup-cron.sh

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

run_step "Firewall" ./setup-firewall.sh
