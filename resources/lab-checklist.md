# Lab Checklist

## Before The Lab

- Confirm Docker Desktop or Docker Engine is installed if using a Docker path.
- Confirm `docker compose version` works if using a Docker path.
- Confirm each participant has a model provider API key.
- Decide whether participants use local Docker, a shared Docker host, native multi-gateway, or an Azure VM.
- If using a shared host, assign each participant a numeric index.
- Review the safety notes in `docs/reference/security.md`.

## Local Docker Setup

- Clone this repository.
- Run `cp .env.example .env`.
- Run `./scripts/local-docker/setup.sh`.
- Complete OpenClaw onboarding.
- Run `./scripts/local-docker/health.sh`.
- Run `./scripts/local-docker/dashboard.sh`.
- Open `http://127.0.0.1:18789/`.

## Shared Docker Host Setup

- Confirm the shared host has Docker and this repository.
- Confirm the shared host IP or DNS name, for example `172.24.110.136`.
- Run `./scripts/shared-docker-host/prepare.sh 20 172.24.110.136`.
- Share each participant's assigned row from `instances/roster.tsv`.
- Participant SSHes into the shared host.
- Participant runs `./scripts/shared-docker-host/setup-instance.sh <index> <host-ip>`.
- Participant completes OpenClaw onboarding in SSH.
- Participant opens `http://<host-ip>:<port>/` from their own browser.
- Participant uses `./scripts/shared-docker-host/instance.sh <index> <command>` for later commands.

## Native Multi-Gateway Setup

- Confirm OpenClaw is installed directly under the shared account, for example `multi-claw`.
- Confirm the shared host IP or DNS name, for example `172.24.110.136`.
- Assign each participant a numeric index; the scripts derive profile ids and ports.
- Participant SSHes into the shared host.
- Participant runs `./scripts/native-multi-gateway/setup-profile.sh <index> <host-ip>`.
- Participant opens `http://<host-ip>:<port>/` from their own browser.

## Azure VM Setup

- Copy `resources/azure.env.example` to `resources/azure.env`.
- Edit names, region, SSH key paths, and VM size.
- Run `./scripts/azure/provision-vm.sh resources/azure.env`.
- Connect with `./scripts/azure/ssh.sh resources/azure.env`.
- In the VM, install Docker with `scripts/azure/install-docker-on-vm.sh`.
- Clone this repository on the VM and run the local Docker setup.

## Wrap-Up

- Complete either the basic or advanced customization lab:
  - `docs/participants/customization-lab-basic.md`
  - `docs/participants/customization-lab-advanced.md`
- Run `./scripts/local-docker/security-audit.sh`.
- Stop local environments with `./scripts/local-docker/stop.sh` if not needed.
- For Azure, deallocate or delete resources to avoid ongoing cost.
