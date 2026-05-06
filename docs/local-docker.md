# Local Docker Lab

This path runs the OpenClaw Gateway in Docker and keeps all OpenClaw state under this repository's ignored `data/` directory.

## Prerequisites

- Docker Desktop or Docker Engine
- Docker Compose v2
- At least 2 GB RAM available to Docker
- A model provider API key

## Setup

```bash
cp .env.example .env
./scripts/setup-local.sh
```

## Provider Choice In Docker

For Anthropic, choose **Anthropic API key** during Docker onboarding unless you specifically want to debug Claude CLI credential reuse inside the container.

Claude CLI reuse works best when OpenClaw runs directly on the same host where `claude` is installed and authenticated. In this lab, onboarding runs inside a Linux container. That container cannot automatically see a macOS Claude Code login, especially when credentials are stored in Keychain. An Anthropic API key is therefore the clearest and least surprising path for Docker Desktop and Azure VM labs.

You can either paste the key when onboarding prompts you, or set it in `.env` before setup:

```text
ANTHROPIC_API_KEY=sk-ant-...
```

Do not commit `.env`.

The setup script:

- Generates `OPENCLAW_GATEWAY_TOKEN` if missing.
- Creates `data/config` and `data/workspace`.
- Pulls the OpenClaw container image.
- Runs interactive OpenClaw onboarding.
- Pins Docker-friendly gateway settings.
- Starts the gateway.

## Daily Commands

```bash
./scripts/start.sh
./scripts/stop.sh
./scripts/logs.sh
./scripts/health.sh
./scripts/cli.sh doctor
./scripts/security-audit.sh
```

## Open The Dashboard

```bash
./scripts/dashboard.sh
```

The command prints the dashboard URL. If you open the Control UI directly, use:

```text
http://127.0.0.1:18789/
```

## Optional Channels

After the gateway is running:

```bash
./scripts/cli.sh channels login
./scripts/cli.sh channels add --channel telegram --token "<token>"
./scripts/cli.sh channels add --channel discord --token "<token>"
```

Use dedicated test accounts and bot tokens for lab work.

## Reset

Stop the gateway:

```bash
./scripts/stop.sh
```

Then remove local OpenClaw state:

```bash
rm -rf data/
```

Keep `.env` if you want to reuse the same gateway token, or delete it and recreate it from `.env.example`.
