#!/bin/bash
# setup auto-update cron job
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"
# shellcheck source=common.sh
source ./common.sh

log_step "Setting up auto-updates"
cat > /usr/local/bin/openclaw-update.sh << 'EOF'
#!/bin/bash
set -euo pipefail
LOG="/var/log/openclaw-update.log"

echo "[$(date -Iseconds)] Starting update" >> "$LOG"
cd /opt/openclaw
git pull >> "$LOG" 2>&1
docker build -t openclaw:local -f Dockerfile . >> "$LOG" 2>&1
docker compose up -d openclaw-gateway >> "$LOG" 2>&1
echo "[$(date -Iseconds)] Update complete" >> "$LOG"
EOF
chmod +x /usr/local/bin/openclaw-update.sh
(crontab -l 2>/dev/null | grep -v openclaw-update; echo "0 3 * * * /usr/local/bin/openclaw-update.sh") | crontab -
log_ok "Auto-updates configured (daily 3am UTC)"
