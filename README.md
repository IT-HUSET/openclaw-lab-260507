# OpenClaw Getting Started Lab

This repository is a lab kit for running [OpenClaw](https://docs.openclaw.ai) in a Docker container on a participant's computer, with optional notes and scripts for an Azure Linux VM.

The default path is intentionally conservative:

- Run the OpenClaw Gateway in Docker Compose.
- Persist state under `./data/`, which is ignored by git.
- Publish the gateway only on `127.0.0.1:18789` by default.
- Use an SSH tunnel or Azure Bastion for remote access instead of exposing the gateway publicly.

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
|   `-- azure/
|-- docs/
|   |-- local-docker.md
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
- [OpenClaw environment variables](https://docs.openclaw.ai/help/environment)
- [OpenClaw security audit command](https://docs.openclaw.ai/cli/security)
