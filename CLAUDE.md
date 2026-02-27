# OpenClaw VPS Deployment

## Documentation

Before making changes, check the official documentation:

**OpenClaw:**
- https://docs.openclaw.ai
- https://docs.openclaw.ai/install/hetzner.md (official Hetzner guide - uses Docker)
- https://github.com/openclaw/openclaw

**Hetzner Cloud CLI:**
- https://github.com/hetznercloud/cli
- https://community.hetzner.com/tutorials/howto-hcloud-cli

OpenClaw updates frequently. Configuration options, CLI commands, and default behaviors may change between versions.

Note: This repo uses native installation (not Docker) because Docker browser support requires a separate sandbox container setup and has known issues with accessibility. Native install provides straightforward browser functionality out of the box.

## Writing Scripts

**Local scripts (`local/`):** Must be Zsh compatible (macOS default shell). Avoid Bash 4+ features:
- Use `[[ "$VAR" =~ ^[Yy]$ ]]` instead of `${VAR,,}` for case-insensitive comparison
- Use `$(command)` instead of backticks
- Avoid associative arrays (`declare -A`)

**Remote scripts (`remote/`):** Run on Ubuntu VPS with Bash. Standard Bash features are fine.

## Project Structure

- `setup.sh` - main entry point, run on your Mac
- `local/` - scripts that run locally (hcloud, ssh, server creation)
- `remote/` - scripts that run on the VPS (tailscale, firewall, openclaw, etc.)
- `.env` - API keys (gitignored)

## Common Commands

```bash
# provision new server
./setup.sh

# ssh into server (after tailscale connects)
ssh root@<tailscale-ip>

# check openclaw status
systemctl status openclaw

# view logs
journalctl -u openclaw -f

# restart after config changes
systemctl restart openclaw

# manual update
openclaw update --channel stable
```
