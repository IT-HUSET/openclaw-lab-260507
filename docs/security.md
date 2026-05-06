# Security Notes

OpenClaw is powerful because it can use tools, run commands, and connect to accounts. Treat a lab environment as untrusted until you have reviewed its configuration.

## Defaults In This Repo

- Gateway host publish is `127.0.0.1`, not all interfaces.
- mDNS/Bonjour advertising is disabled with `OPENCLAW_DISABLE_BONJOUR=1`.
- OpenClaw state is stored in ignored local folders under `data/`.
- The container drops `NET_RAW` and `NET_ADMIN`.
- The container uses `no-new-privileges`.

## Lab Rules

- Use dedicated API keys and test accounts.
- Set spending limits with model providers where possible.
- Do not mount a participant's whole home directory.
- Do not expose port `18789` publicly.
- Do not use primary work or personal messaging accounts.
- Review any skills, plugins, or scripts before enabling them.
- Run `./scripts/security-audit.sh` after onboarding.

## Remote Access

For a VM, prefer SSH tunnels, VPN/tailnet access, or Azure Bastion. If you intentionally publish the gateway beyond localhost, require gateway authentication and review the OpenClaw hardening docs first.

## Secrets

The `.env` file is ignored by git. Do not commit:

- `OPENCLAW_GATEWAY_TOKEN`
- Model provider API keys
- Messaging bot tokens
- OAuth cookies or session keys
- `data/config`
- `data/workspace`
