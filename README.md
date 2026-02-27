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
| `TAILSCALE_AUTH_KEY` | Yes | [login.tailscale.com/admin/settings/keys](https://login.tailscale.com/admin/settings/keys) |
| `OPENROUTER_API_KEY` | Yes | [openrouter.ai/settings/keys](https://openrouter.ai/settings/keys) |
| `OPENAI_API_KEY` | No | [platform.openai.com/api-keys](https://platform.openai.com/api-keys) |
| `ELEVENLABS_API_KEY` | No | [elevenlabs.io/app/settings/api-keys](https://elevenlabs.io/app/settings/api-keys) |

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

The setup wizard runs automatically after provisioning. Complete the interactive
onboarding to configure your instance.

Dashboard: `http://<tailscale-ip>:18789`

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

## Security

- SSH restricted to your Mac's Tailscale IP only
- UFW blocks all public access
- Gateway only accessible via Tailscale
- No public ports exposed
