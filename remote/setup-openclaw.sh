#!/bin/bash
# install docker and clone openclaw
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"
# shellcheck source=common.sh
source ./common.sh

if ! command -v docker &>/dev/null; then
    apt-get update -qq >/dev/null 2>&1
    apt-get install -y -qq ca-certificates curl git >/dev/null 2>&1
    curl -fsSL https://get.docker.com | sh >/dev/null 2>&1 || log_fail "docker install failed"
fi
docker compose version >/dev/null 2>&1 || log_fail "docker compose not available"

if [[ -d /opt/openclaw ]]; then
    cd /opt/openclaw && git pull >/dev/null 2>&1
else
    git clone https://github.com/openclaw/openclaw.git /opt/openclaw >/dev/null 2>&1 || log_fail "git clone failed"
fi

mkdir -p /root/.openclaw/{workspace,credentials}
chown -R 1000:1000 /root/.openclaw
