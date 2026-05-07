# OpenClaw Getting Started Lab

This repository is a lab kit for running [OpenClaw](https://docs.openclaw.ai) in Docker on a participant computer, as multiple Docker instances on one shared host, or as native multiple gateways under one shared macOS account. Azure VM notes are included as a backup path.

For a guided introduction to using and personalizing OpenClaw, see the IT-Huset [OpenClaw Guide](https://it-huset.github.io/openclaw-guide/).

The default path is intentionally conservative:

- Run the OpenClaw Gateway in Docker Compose.
- Persist state under `./data/`, which is ignored by git.
- Publish the gateway only on `127.0.0.1:18789` by default.
- For shared Docker host labs, publish only to the trusted lab network and give each participant a separate token, port, config folder, and Compose project.
- For native multi-gateway labs, give each participant a separate OpenClaw profile and gateway port.

## Facilitator

Start with [docs/facilitator.md](docs/facilitator.md). It separates lab preparation from participant instructions and helps choose between local Docker, shared Docker host, native multi-gateway, and Azure VM setups.

## Participant Quick Start

For local Docker:

- Docker Desktop or Docker Engine
- Docker Compose v2 (`docker compose version`)
- A model provider API key for onboarding

Run:

```bash
cp .env.example .env
./scripts/local-docker/setup.sh
```

Open the Control UI:

```bash
./scripts/local-docker/dashboard.sh
```

Or open:

```text
http://127.0.0.1:18789/
```

Useful commands:

```bash
./scripts/local-docker/health.sh
./scripts/local-docker/logs.sh
./scripts/local-docker/cli.sh doctor
./scripts/local-docker/stop.sh
./scripts/local-docker/start.sh
```

See [docs/participants/local-docker.md](docs/participants/local-docker.md).

## Shared Docker Host

Use this when participants cannot run Docker locally. The facilitator prepares slots, then each participant SSHes into the shared host, runs onboarding in the terminal, and opens the assigned URL from their own browser.

Prepare 20 participant slots:

```bash
./scripts/shared-docker-host/prepare.sh 20 172.24.110.136
```

Then each participant runs their assigned onboarding command. Example:

```bash
./scripts/shared-docker-host/setup-instance.sh 1 172.24.110.136
```

When setup finishes, participant `p01` opens:

```text
http://172.24.110.136:18789/
```

Later commands:

```bash
./scripts/shared-docker-host/instance.sh 1 dashboard
./scripts/shared-docker-host/instance.sh 1 health
./scripts/shared-docker-host/instance.sh 1 cli doctor
./scripts/shared-docker-host/instance.sh 1 logs
```

See [docs/participants/shared-docker-host.md](docs/participants/shared-docker-host.md).

## Native Multi-Gateway

Use this when Docker is not desired on the lab machine. OpenClaw runs directly under a macOS account such as `multi-claw`, with one OpenClaw profile and gateway port per participant.

Example:

```bash
ssh multi-claw@172.24.110.136
./scripts/native-multi-gateway/setup-profile.sh 1 172.24.110.136

./scripts/native-multi-gateway/setup-profile.sh 2 172.24.110.136
```

See [docs/participants/native-multi-gateway.md](docs/participants/native-multi-gateway.md).

## Customization Lab

After a participant has a working gateway, use [docs/participants/customization-lab.md](docs/participants/customization-lab.md) to choose a personalization track:

- [Basic customization lab](docs/participants/customization-lab-basic.md) for dashboard-first participants.
- [Advanced customization lab](docs/participants/customization-lab-advanced.md) for participants who want terminal commands, workspace files, heartbeat, cron jobs, personal-assistant setup, and a knowledge vault.

## Repository Layout

```text
.
|-- compose.yaml
|-- .env.example
|-- scripts/
|   |-- common/
|   |-- local-docker/
|   |-- shared-docker-host/
|   |-- native-multi-gateway/
|   `-- azure/
|-- docs/
|   |-- facilitator.md
|   |-- participants/
|   `-- reference/
`-- resources/
    |-- lab-checklist.md
    `-- azure.env.example
```

## Azure VM Path

The Azure guide provisions a VM without a public IP and uses Azure Bastion for SSH. Start with:

```bash
cp resources/azure.env.example resources/azure.env
./scripts/azure/provision-vm.sh resources/azure.env
./scripts/azure/ssh.sh resources/azure.env
```

Inside the VM, install Docker and run the same local Docker setup. See [docs/participants/azure-vm.md](docs/participants/azure-vm.md).

## Publish To GitHub

Initialize and review before publishing:

```bash
git init
git add .
git status
git commit -m "Add OpenClaw getting started lab"
```

Then create a GitHub repository and push:

```bash
git remote add origin git@github.com:<owner>/<repo>.git
git branch -M main
git push -u origin main
```

## Upstream References

- [OpenClaw Getting Started](https://docs.openclaw.ai/start/getting-started)
- [OpenClaw Agent bootstrapping](https://docs.openclaw.ai/start/bootstrapping)
- [OpenClaw Agent workspace](https://docs.openclaw.ai/concepts/agent-workspace)
- [OpenClaw SOUL.md personality guide](https://docs.openclaw.ai/concepts/soul)
- [OpenClaw Memory overview](https://docs.openclaw.ai/concepts/memory)
- [IT-Huset OpenClaw Guide](https://it-huset.github.io/openclaw-guide/)
- [IT-Huset Personal Assistant recipe](https://it-huset.github.io/openclaw-guide/docs/recipes/personal-assistant/)
- [IT-Huset Knowledge Vault recipe](https://it-huset.github.io/openclaw-guide/docs/recipes/knowledge-vault/)
- [OpenClaw Docker install](https://docs.openclaw.ai/install/docker)
- [OpenClaw Azure install](https://docs.openclaw.ai/install/azure)
- [OpenClaw Multiple Gateways](https://docs.openclaw.ai/gateway/multiple-gateways)
- [OpenClaw Automation & Tasks](https://docs.openclaw.ai/automation)
- [OpenClaw Heartbeat](https://docs.openclaw.ai/gateway/heartbeat)
- [OpenClaw Cron jobs](https://docs.openclaw.ai/cron)
- [OpenClaw environment variables](https://docs.openclaw.ai/help/environment)
- [OpenClaw security audit command](https://docs.openclaw.ai/cli/security)
