# OpenClaw Getting Started Lab

This repository is a lab kit for running [OpenClaw](https://docs.openclaw.ai) in Docker on a participant computer, as multiple Docker instances on one shared host, or as native multiple gateways under one macOS account. Azure VM notes are included as a backup path.

The default path is intentionally conservative:

- Run the OpenClaw Gateway in Docker Compose.
- Persist state under `./data/`, which is ignored by git.
- Publish the gateway only on `127.0.0.1:18789` by default.
- For shared Docker host labs, publish only to the trusted lab network and give each participant a separate token, port, config folder, and Compose project.
- For native multi-gateway labs, give each participant a separate OpenClaw profile and gateway port.

## Quick Start

Prerequisites:

- Docker Desktop or Docker Engine
- Docker Compose v2 (`docker compose version`)
- A model provider API key for onboarding

Run:

```bash
cp .env.example .env
./scripts/setup-local.sh
```

Open the Control UI:

```bash
./scripts/dashboard.sh
```

Or open:

```text
http://127.0.0.1:18789/
```

Useful commands:

```bash
./scripts/health.sh
./scripts/logs.sh
./scripts/cli.sh doctor
./scripts/stop.sh
./scripts/start.sh
```

## Shared Docker Host

Use this when participants cannot run Docker locally. The participant SSHes into the shared host, runs onboarding in the terminal, and opens the assigned URL from their own browser.

Example for a host at `172.24.110.136`:

Prepare 20 participant slots:

```bash
./scripts/prepare-shared-host.sh 20 172.24.110.136
```

Then each participant runs their assigned onboarding command. Example:

```bash
./scripts/setup-shared-instance.sh p01 18789 172.24.110.136
```

When setup finishes, participant `p01` opens:

```text
http://172.24.110.136:18789/
```

Later commands:

```bash
./scripts/instance.sh p01 dashboard
./scripts/instance.sh p01 health
./scripts/instance.sh p01 cli doctor
./scripts/instance.sh p01 logs
```

See [docs/shared-docker-host.md](docs/shared-docker-host.md).

## Native Multi-Gateway

Use this when Docker is not desired on the lab machine. OpenClaw runs directly under a macOS account such as `multi-claw`, with one OpenClaw profile and gateway port per participant.

Example:

```bash
ssh multi-claw@172.24.110.136
openclaw --profile p01 onboard
openclaw --profile p01 gateway install --port 18789

openclaw --profile p02 onboard
openclaw --profile p02 gateway install --port 18809
```

See [docs/native-multi-gateway.md](docs/native-multi-gateway.md).

## Repository Layout

```text
.
|-- compose.yaml
|-- .env.example
|-- scripts/
|   |-- setup-local.sh
|   |-- start.sh
|   |-- stop.sh
|   |-- health.sh
|   |-- logs.sh
|   |-- dashboard.sh
|   |-- cli.sh
|   |-- setup-shared-instance.sh
|   |-- prepare-shared-host.sh
|   |-- instance.sh
|   `-- azure/
|-- docs/
|   |-- local-docker.md
|   |-- shared-docker-host.md
|   |-- native-multi-gateway.md
|   |-- azure-vm.md
|   |-- security.md
|   `-- troubleshooting.md
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

Inside the VM, install Docker and run the same local Docker setup. See [docs/azure-vm.md](docs/azure-vm.md).

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
- [OpenClaw Docker install](https://docs.openclaw.ai/install/docker)
- [OpenClaw Azure install](https://docs.openclaw.ai/install/azure)
- [OpenClaw Multiple Gateways](https://docs.openclaw.ai/gateway/multiple-gateways)
- [OpenClaw environment variables](https://docs.openclaw.ai/help/environment)
- [OpenClaw security audit command](https://docs.openclaw.ai/cli/security)
