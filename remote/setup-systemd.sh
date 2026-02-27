#!/bin/bash
# create systemd service for openclaw
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

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
