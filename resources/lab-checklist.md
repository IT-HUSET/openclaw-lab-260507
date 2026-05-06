# Lab Checklist

## Before The Lab

- Confirm Docker Desktop or Docker Engine is installed.
- Confirm `docker compose version` works.
- Confirm each participant has a model provider API key.
- Decide whether participants use local Docker only or an Azure VM.
- Review the safety notes in `docs/security.md`.

## Local Docker Setup

- Clone this repository.
- Run `cp .env.example .env`.
- Run `./scripts/setup-local.sh`.
- Complete OpenClaw onboarding.
- Run `./scripts/health.sh`.
- Run `./scripts/dashboard.sh`.
- Open `http://127.0.0.1:18789/`.

## Azure VM Setup

- Copy `resources/azure.env.example` to `resources/azure.env`.
- Edit names, region, SSH key paths, and VM size.
- Run `./scripts/azure/provision-vm.sh resources/azure.env`.
- Connect with `./scripts/azure/ssh.sh resources/azure.env`.
- In the VM, install Docker with `scripts/azure/install-docker-on-vm.sh`.
- Clone this repository on the VM and run the local Docker setup.

## Wrap-Up

- Run `./scripts/security-audit.sh`.
- Stop local environments with `./scripts/stop.sh` if not needed.
- For Azure, deallocate or delete resources to avoid ongoing cost.
