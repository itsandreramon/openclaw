# OpenClaw VPS Deployment

Minimal, secure OpenClaw deployment with Tailscale. Native installation (no Docker) with full browser support.

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
- Node.js 22 + browser dependencies
- OpenClaw + Puppeteer (with Chrome)
- UFW firewall (SSH restricted to your Mac's Tailscale IP)
- Systemd service (enabled, not started)
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
    ├── setup-node.sh     # install node.js + browser deps
    ├── setup-firewall.sh # configure ufw
    ├── setup-openclaw.sh # install openclaw
    ├── setup-env.sh      # create environment file
    ├── setup-systemd.sh  # create systemd service
    └── setup-cron.sh     # setup auto-update cron
```

## Configure (Manual)

After provisioning, SSH in and run the onboarding wizard:

```bash
ssh root@<vps-tailscale-ip>
openclaw onboard
```

When prompted:
- **Gateway bind**: `lan`
- **Gateway auth**: `token`
- **Gateway token**: press Enter (auto-generated)
- **Tailscale exposure**: `Off`
- **Install Gateway daemon**: `No`
- **Model provider**: `openrouter`

Start the gateway:

```bash
systemctl start openclaw
```

## Access

Get your gateway token:

```bash
cat /root/.openclaw/openclaw.json | jq -r '.gateway.token'
```

Access dashboard:
- Direct: `http://<vps-tailscale-ip>:18789`
- Via tunnel: `ssh -L 18789:localhost:18789 root@<vps-tailscale-ip>` then `http://localhost:18789`

## Optional: Add Telegram

```bash
openclaw channels add --channel telegram --token "<BOT_TOKEN>"
systemctl restart openclaw
```

## Optional: Add Whisper STT

```bash
jq '.tools.media.audio = {
  "enabled": true,
  "maxBytes": 20971520,
  "models": [{"provider": "openai", "model": "gpt-4o-mini-transcribe"}]
}' /root/.openclaw/openclaw.json > /tmp/oc.json && mv /tmp/oc.json /root/.openclaw/openclaw.json
systemctl restart openclaw
```

## Optional: Add TTS

```bash
jq '. + {
  "messages": {
    "tts": {
      "auto": "tagged",
      "provider": "elevenlabs",
      "elevenlabs": {
        "apiKey": "YOUR_ELEVENLABS_API_KEY",
        "modelId": "eleven_multilingual_v2",
        "voiceId": "CwhRBWXzGAHq8TQ4Fs17"
      }
    }
  }
}' /root/.openclaw/openclaw.json > /tmp/oc.json && mv /tmp/oc.json /root/.openclaw/openclaw.json
systemctl restart openclaw
```

Voices: `CwhRBWXzGAHq8TQ4Fs17` (Roger), `onwK4e9ZLuTAKqWW03F9` (Daniel), `pNInz6obpgDQGcFmaJgB` (Adam)

## Managing

```bash
systemctl status openclaw      # status
journalctl -u openclaw -f      # logs
systemctl restart openclaw     # restart
```

## Updates

Automatic nightly updates at 3am UTC. Logs: `/var/log/openclaw-update.log`

Manual update:
```bash
/usr/local/bin/openclaw-update.sh
```

## Security

- **SSH**: Restricted to your MacBook's Tailscale IP only
- **Firewall**: UFW blocks all public access, allows Tailscale interface
- **Gateway**: Only accessible via Tailscale network
- **No public ports**: SSH (22), HTTP (80), HTTPS (443) blocked from public internet
