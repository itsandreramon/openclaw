#!/bin/bash
# install docker and clone openclaw
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"
# shellcheck source=common.sh
source ./common.sh

log_step "Installing Docker..."
if ! command -v docker &>/dev/null; then
    apt-get update -qq >/dev/null 2>&1
    apt-get install -y -qq ca-certificates curl git >/dev/null 2>&1
    curl -fsSL https://get.docker.com | sh >/dev/null 2>&1 || log_fail "Docker install failed"
fi
DOCKER_VERSION=$(docker --version 2>/dev/null)
log_ok "Docker installed: ${DOCKER_VERSION}"

log_step "Verifying Docker Compose..."
docker compose version >/dev/null 2>&1 || log_fail "Docker Compose not available"
log_ok "Docker Compose available"

log_step "Cloning OpenClaw repository..."
if [[ -d /opt/openclaw ]]; then
    cd /opt/openclaw && git pull >/dev/null 2>&1
else
    git clone https://github.com/openclaw/openclaw.git /opt/openclaw >/dev/null 2>&1 || log_fail "Git clone failed"
fi
log_ok "Repository ready at /opt/openclaw"

log_step "Setting up permissions..."
mkdir -p /root/.openclaw/{workspace,credentials}
chown -R 1000:1000 /root/.openclaw
log_ok "Permissions configured (UID 1000 for node user)"
