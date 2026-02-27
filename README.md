# OpenClaw VPS Deployment

Secure OpenClaw deployment on Hetzner with Tailscale and Docker.

## Prerequisites

- Hetzner account with CLI tool installed
- Tailscale account with auth key
- OpenRouter API key
- (Optional) OpenAI API key for Whisper STT
- (Optional) ElevenLabs API key for TTS

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `TAILSCALE_AUTH_KEY` | Yes | Auth key from [admin.tailscale.com](https://admin.tailscale.com) |
| `OPENROUTER_API_KEY` | Yes | API key from [openrouter.ai](https://openrouter.ai) |
| `OPENAI_API_KEY` | No | For Whisper speech-to-text |
| `ELEVENLABS_API_KEY` | No | For text-to-speech |

## Quick Start

```bash
# install hetzner cli
brew install hcloud
hcloud context create openclaw

# run setup script
./setup.sh
```

The setup script will:
1. Upload your SSH key to Hetzner (if not already present)
2. Prompt for API keys (or load from `.env`)
3. Auto-detect your Mac's Tailscale IP
4. Create the VPS and run remote init scripts

The remote init provisions:
- 4GB swap
- Tailscale VPN with SSH
- Docker + Docker Compose
- OpenClaw repository clone
- UFW firewall (SSH restricted to your Mac's Tailscale IP)
- Auto-update cron (daily 3am UTC)

## Project Structure

```
├── setup.sh              # main entry point (run on mac)
├── local/                # scripts that run on your mac
│   ├── common.sh         # shared utilities
│   ├── check-hcloud.sh   # verify hcloud cli
│   ├── setup-ssh-key.sh  # upload ssh key to hetzner
│   ├── create-server.sh  # create hetzner server
│   └── wait-for-ssh.sh   # wait for server to be accessible
└── remote/               # scripts that run on the vps
    ├── common.sh         # shared utilities
    ├── init.sh           # main init script
    ├── setup-swap.sh     # configure swap
    ├── setup-tailscale.sh# install tailscale
    ├── setup-firewall.sh # configure ufw
    ├── setup-openclaw.sh # install docker + clone repo
    ├── setup-env.sh      # create environment file
    └── setup-cron.sh     # setup auto-update cron
```

## Configure

After provisioning, SSH in and run the Docker setup:

```bash
ssh root@<vps-tailscale-ip>
cd /opt/openclaw

# setup with persistence and system packages
export OPENCLAW_HOME_VOLUME="openclaw_home"
export OPENCLAW_DOCKER_APT_PACKAGES="git curl jq"
./docker-setup.sh

# install browser for web automation
docker compose run --rm openclaw-cli \
  node /app/node_modules/playwright-core/cli.js install chromium
```

- `OPENCLAW_HOME_VOLUME` persists `/home/node` (agent sessions, browser cache) across rebuilds
- `OPENCLAW_DOCKER_APT_PACKAGES` bakes system packages into the image

Follow the onboarding wizard prompts.

## Access

Access dashboard:
- Direct: `http://<vps-tailscale-ip>:18789`
- Via tunnel: `ssh -L 18789:localhost:18789 root@<vps-tailscale-ip>` then `http://localhost:18789`

## Managing

```bash
cd /opt/openclaw
docker compose ps                    # status
docker compose logs -f               # logs
docker compose restart               # restart
docker compose down && docker compose up -d  # full restart
```

## Updates

Automatic nightly updates at 3am UTC. Logs: `/var/log/openclaw-update.log`

Manual update:
```bash
cd /opt/openclaw
git pull
docker build -t openclaw:local -f Dockerfile .
docker compose up -d openclaw-gateway
```

## Security

- **SSH**: Restricted to your MacBook's Tailscale IP only
- **Firewall**: UFW blocks all public access, allows Tailscale interface
- **Gateway**: Only accessible via Tailscale network
- **No public ports**: SSH (22), HTTP (80), HTTPS (443) blocked from public internet
