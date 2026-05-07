# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

This is a **lab kit**, not an application. It packages repeatable ways to run OpenClaw for workshop participants:

- Local Docker on a participant computer.
- Multiple Docker-backed participant instances on one shared Docker host.
- Native multiple OpenClaw gateways under one shared macOS account.
- Azure VM setup as a backup path.

There is no source app to build. The main deliverables are `compose.yaml`, shell wrappers under `scripts/`, facilitator/participant docs under `docs/`, and lab resources under `resources/`.

When changing things, optimize for:

1. Clear facilitator setup separated from participant instructions.
2. One-command participant setup for the chosen mode.
3. Safe defaults for local Docker and Azure.
4. Consistent participant indexing across shared-host modes.

## Documentation Layout

- `docs/facilitator.md` — shared decision guide, setup prep, roster guidance, wrap-up.
- `docs/participants/local-docker.md` — participant instructions for Docker on their own computer.
- `docs/participants/shared-docker-host.md` — participant instructions for shared Docker host mode.
- `docs/participants/native-multi-gateway.md` — participant instructions for native OpenClaw profiles/gateways.
- `docs/participants/azure-vm.md` — Azure VM path.
- `docs/reference/security.md`, `docs/reference/troubleshooting.md`, `docs/reference/resources.md` — reference material.

Keep facilitator-only preparation out of participant docs unless the participant must run the command.

## Common Commands

Local Docker lifecycle:

```bash
cp .env.example .env
./scripts/local-docker/setup.sh
./scripts/local-docker/start.sh
./scripts/local-docker/stop.sh
./scripts/local-docker/logs.sh
./scripts/local-docker/health.sh
./scripts/local-docker/dashboard.sh
./scripts/local-docker/cli.sh doctor
./scripts/local-docker/security-audit.sh
```

Skip interactive Docker onboarding for scripted reruns:

```bash
OPENCLAW_SKIP_ONBOARDING=1 ./scripts/local-docker/setup.sh
```

Shared Docker host:

```bash
./scripts/shared-docker-host/prepare.sh 20 172.24.110.136
./scripts/shared-docker-host/setup-instance.sh 1 172.24.110.136
./scripts/shared-docker-host/instance.sh 1 dashboard
./scripts/shared-docker-host/instance.sh 1 health
./scripts/shared-docker-host/instance.sh 1 logs
./scripts/shared-docker-host/instance.sh 1 stop
```

Native multi-gateway:

```bash
./scripts/native-multi-gateway/setup-profile.sh 1 172.24.110.136
./scripts/native-multi-gateway/url.sh 1 172.24.110.136
./scripts/native-multi-gateway/dashboard.sh 1
./scripts/native-multi-gateway/health.sh 1
./scripts/native-multi-gateway/logs.sh 1
./scripts/native-multi-gateway/status.sh 1
./scripts/native-multi-gateway/stop-profile.sh 1
```

Azure path, run from a workstation:

```bash
cp resources/azure.env.example resources/azure.env
./scripts/azure/provision-vm.sh resources/azure.env
./scripts/azure/ssh.sh resources/azure.env
# then inside the VM:
./scripts/azure/install-docker-on-vm.sh
./scripts/local-docker/setup.sh
```

Validation:

```bash
shellcheck scripts/**/*.sh
bash -n scripts/**/*.sh
docker compose --env-file .env.example -f compose.yaml config
git diff --check
```

## Participant Indexing

Shared-host modes use the same default participant mapping:

```text
1 or 01 -> p01 -> 18789
2       -> p02 -> 18809
3       -> p03 -> 18829
```

Formula:

```text
id/profile = pNN
port = 18789 + (index - 1) * 20
```

The mapping logic lives in `scripts/common/participants.sh`. Both shared Docker and native multi-gateway scripts should use it rather than duplicating index parsing.

The explicit custom forms still exist where useful:

```bash
./scripts/shared-docker-host/setup-instance.sh p01 18789 172.24.110.136
./scripts/native-multi-gateway/setup-profile.sh p01 18789 172.24.110.136
```

## Architecture

### Docker Compose

`compose.yaml` declares two services backed by the same `OPENCLAW_IMAGE`:

- `openclaw-gateway` — long-running gateway. Serves the Control UI and bridge. The internal gateway port is `18789`; host publishing is controlled by env vars.
- `openclaw-cli` — one-shot CLI container. It uses `network_mode: "service:openclaw-gateway"` so it shares the gateway network namespace and reaches the gateway over loopback.

Both services bind-mount the same config/workspace directories. For local Docker those default to `data/config` and `data/workspace`; for shared Docker they become `instances/<participant-id>/config` and `instances/<participant-id>/workspace`.

`scripts/local-docker/cli.sh`, `dashboard.sh`, and `security-audit.sh` run `compose run --rm openclaw-cli ...`.

`scripts/local-docker/health.sh` checks `/healthz` from the host and then runs the authenticated OpenClaw health command inside the running gateway container.

### Native Multi-Gateway

Native multi-gateway does not use Docker or Compose. It assumes OpenClaw is installed directly under a shared macOS account such as `multi-claw`.

`scripts/native-multi-gateway/setup-profile.sh 1 172.24.110.136` derives `p01` and port `18789`, then runs:

```bash
openclaw --profile p01 onboard
openclaw --profile p01 gateway install --port 18789
```

Onboarding creates/configures the profile. `gateway install --port ...` ensures a managed gateway service exists on the assigned port. OpenClaw may report no extra work is needed if onboarding already installed the service.

## Script Topology

- `scripts/common/lib.sh` — repo root detection, env file selection, Compose wrapper, env read/write helpers, token generation.
- `scripts/common/participants.sh` — participant index/id/port helpers.
- `scripts/local-docker/` — local Docker lifecycle wrappers.
- `scripts/shared-docker-host/` — shared Docker host prepare/setup/instance wrappers.
- `scripts/native-multi-gateway/` — native OpenClaw profile/gateway wrappers.
- `scripts/azure/` — Azure provisioning, SSH, and Docker install helpers.

Docker scripts that need Compose should use the `compose` helper from `scripts/common/lib.sh`.

Do not duplicate participant index parsing. Use `scripts/common/participants.sh`.

## Local Docker Setup Flow

`scripts/local-docker/setup.sh` is idempotent and should stay that way. Order:

1. Verify Docker Compose v2.
2. Copy `.env.example` to the selected env file if missing.
3. Generate `OPENCLAW_GATEWAY_TOKEN` if empty.
4. Create host bind-mount directories.
5. Pull the configured OpenClaw image.
6. Run interactive onboarding unless `OPENCLAW_SKIP_ONBOARDING=1`.
7. Apply Docker-friendly gateway config, including `gateway.controlUi.allowedOrigins`.
8. Start `openclaw-gateway`.

Step 7 should stay on every run because allowed origins depend on the selected host/public port.

## Security Defaults

Local Docker defaults are intentionally conservative:

- `OPENCLAW_PUBLISH_HOST=127.0.0.1`
- `OPENCLAW_DISABLE_BONJOUR=1`
- `cap_drop: [NET_RAW, NET_ADMIN]`
- `security_opt: [no-new-privileges:true]`

Shared Docker host mode intentionally publishes to the lab network by default through `OPENCLAW_PUBLISH_HOST=0.0.0.0`, with per-participant tokens, ports, config folders, and Compose projects. Treat this as trusted-workshop isolation, not strong multi-tenant isolation.

Native multi-gateway profiles separate OpenClaw state but do not create Unix-level isolation if everyone logs in as the same macOS account.

Azure provisioning creates a VM with no public IP and SSH via Azure Bastion.

If a change loosens local Docker or Azure exposure, confirm the tradeoff explicitly.

## State And Secrets

Ignored local state and secrets:

- `.env`
- `resources/azure.env`
- `data/`
- `instances/`

Do not commit provider API keys, `OPENCLAW_GATEWAY_TOKEN`, messaging bot tokens, OAuth cookies, or generated OpenClaw state.

Keep `.env.example` and `resources/azure.env.example` in sync with variables referenced by `compose.yaml` or scripts.
