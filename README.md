# OpenClaw VPS Deployment

Automated OpenClaw deployment on Hetzner with Tailscale and Docker.

## Prerequisites

- macOS with Homebrew
- Hetzner account
- Tailscale account

## Environment Variables

Create a `.env` file or enter values when prompted.

| Variable | Required | Description |
|----------|----------|-------------|
| `TAILSCALE_AUTH_KEY` | Yes | [admin.tailscale.com](https://admin.tailscale.com) → Settings → Keys → Generate auth key |
| `OPENROUTER_API_KEY` | Yes | [openrouter.ai/keys](https://openrouter.ai/keys) |
| `OPENAI_API_KEY` | No | For Whisper speech-to-text |
| `ELEVENLABS_API_KEY` | No | For text-to-speech |

## Quick Start

```bash
# install hetzner cli
brew install hcloud
hcloud context create openclaw

# run setup
./setup.sh
```

The setup will:
1. Fetch server types/locations from Hetzner API
2. Prompt for configuration (or load from `.env`)
3. Create VPS (default: cx23 ~€3.50/mo)
4. Run remote provisioning with progress [1/7]...[7/7]

## What Gets Installed

| Step | Description |
|------|-------------|
| Swap | 4GB swap file |
| Tailscale | VPN with SSH enabled |
| Docker | Docker + Docker Compose |
| OpenClaw | Clone to `/opt/openclaw` |
| Environment | API keys in `/opt/openclaw/.env` |
| Auto-updates | Daily 3am UTC cron job |
| Firewall | UFW restricts SSH to your Tailscale IP |

## Post-Setup

Setup runs automatically. Once complete, access the dashboard at:

`http://<tailscale-ip>:18789`

## Configure Telegram & Web Search

After setup, SSH in and configure via CLI:

```bash
ssh root@<tailscale-ip>
cd /opt/openclaw

# set model with free fallback
docker compose run --rm openclaw-cli config set agents.defaults.model.primary "openrouter/minimax/minimax-m2.5"
docker compose run --rm openclaw-cli config set agents.defaults.model.fallbacks '["openrouter/meta-llama/llama-3.3-70b-instruct:free"]'

# configure telegram
docker compose run --rm openclaw-cli config set channels.telegram.enabled true
docker compose run --rm openclaw-cli config set channels.telegram.botToken "YOUR_BOT_TOKEN"
docker compose run --rm openclaw-cli config set channels.telegram.dmPolicy "allowlist"
docker compose run --rm openclaw-cli config set channels.telegram.allowFrom '["tg:YOUR_USER_ID"]'

# configure web search (optional)
docker compose run --rm openclaw-cli config set tools.web.search.apiKey "YOUR_BRAVE_API_KEY"

# restart gateway to apply changes
docker compose restart openclaw-gateway
```

## Managing

```bash
cd /opt/openclaw
docker compose ps          # status
docker compose logs -f     # logs
docker compose restart     # restart
```

## Security

- SSH restricted to your Mac's Tailscale IP only
- UFW blocks all public access
- Gateway only accessible via Tailscale
- No public ports exposed
