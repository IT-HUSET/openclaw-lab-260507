# Security Notes

OpenClaw is powerful because it can use tools, run commands, and connect to accounts. Treat a lab environment as untrusted until you have reviewed its configuration.

## Defaults In This Repo

- Gateway host publish is `127.0.0.1`, not all interfaces.
- mDNS/Bonjour advertising is disabled with `OPENCLAW_DISABLE_BONJOUR=1`.
- OpenClaw state is stored in ignored local folders under `data/`.
- The container drops `NET_RAW` and `NET_ADMIN`.
- The container uses `no-new-privileges`.

## Unrestricted Lab Mode

`resources/lab-secrets.env` can enable `OPENCLAW_LAB_UNRESTRICTED=1` for preconfigured Shared Docker Host and Native Multi-Gateway labs. This intentionally broadens OpenClaw's runtime authority:

- `tools.profile="full"`
- `agents.defaults.sandbox.mode="off"`
- `tools.exec.host="gateway"`
- `tools.exec.security="full"`
- `tools.exec.ask="off"`
- `tools.exec.applyPatch.workspaceOnly=false`
- `tools.fs.workspaceOnly=false`
- `browser.ssrfPolicy.dangerouslyAllowPrivateNetwork=true`

In Shared Docker Host mode, this is still bounded by the container and its mounted config/workspace directories unless additional host paths are mounted. In Native Multi-Gateway mode, this runs as the shared macOS account and can access what that Unix account can access. Do not use unrestricted mode with untrusted participants, production credentials, or personal accounts.

## Lab Rules

- Use dedicated API keys and test accounts.
- Set spending limits with model providers where possible.
- Do not mount a participant's whole home directory.
- Do not expose port `18789` publicly.
- Do not use primary work or personal messaging accounts.
- Review any skills, plugins, or scripts before enabling them.
- Run `./scripts/local-docker/security-audit.sh` after onboarding.

## Remote Access

For a VM, prefer SSH tunnels, VPN/tailnet access, or Azure Bastion. If you intentionally publish the gateway beyond localhost, require gateway authentication and review the OpenClaw hardening docs first.

For a same-network shared Docker host lab, publish each participant instance only on the trusted lab network, use unique gateway tokens, and keep the network trusted. This is workshop isolation, not strong multi-tenant isolation.

For a native multi-gateway lab under one macOS account, remember that OpenClaw profiles separate gateway state but do not create Unix-level isolation between participants sharing the same account.

## Secrets

The `.env` file is ignored by git. Do not commit:

- `OPENCLAW_GATEWAY_TOKEN`
- `resources/lab-secrets.env`
- Model provider API keys
- Messaging bot tokens
- OAuth cookies or session keys
- `data/config`
- `data/workspace`
