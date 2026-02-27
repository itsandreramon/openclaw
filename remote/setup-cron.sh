#!/bin/bash
# setup auto-update cron job
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

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

log_step "Setting up nightly update cronjob..."
(crontab -l 2>/dev/null | grep -v openclaw-update; echo "0 3 * * * /usr/local/bin/openclaw-update.sh") | crontab -
log_ok "Cronjob configured (daily 3am UTC)"
