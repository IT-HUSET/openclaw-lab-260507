# Shared Docker Host Participant Guide

Use this mode when the facilitator gives you a participant index and SSH access to a shared Docker host. The scripts derive your participant id and ports from the index.

Example assignment:

| Field | Value |
| --- | --- |
| SSH account | `multi-claw@172.24.110.136` |
| Participant index | `1` |
| Participant id | `p01` |
| Gateway port | `18789` |
| Browser URL | `http://172.24.110.136:18789/` |

## Setup

SSH to the shared host:

```bash
ssh multi-claw@172.24.110.136
cd openclaw-getting-started
```

Run your assigned onboarding command:

```bash
./scripts/shared-docker-host/setup-instance.sh 1 172.24.110.136
```

The setup script usually runs interactive OpenClaw onboarding in your SSH terminal. If the facilitator preconfigured the lab, setup may run non-interactively and skip provider-key prompts.

Participant index `1` maps to id `p01` and port `18789`; index `2` maps to id `p02` and port `18809`.

When setup finishes, open your assigned URL from your own browser:

```text
http://172.24.110.136:18789/
```

If OpenClaw asks for a token, use the token printed by the setup script.

## Later Commands

Run these from the shared host:

```bash
./scripts/shared-docker-host/instance.sh 1 url
./scripts/shared-docker-host/instance.sh 1 dashboard
./scripts/shared-docker-host/instance.sh 1 health
./scripts/shared-docker-host/instance.sh 1 cli doctor
./scripts/shared-docker-host/instance.sh 1 logs
```

Stop your instance:

```bash
./scripts/shared-docker-host/instance.sh 1 stop
```

Start it again:

```bash
./scripts/shared-docker-host/instance.sh 1 start
```

## Boundaries

If everyone logs in as the same Unix account, this is a trusted-lab setup, not isolation. Stay inside your assigned participant id and do not inspect or change other participants' `instances/<id>/` folders or Docker projects.
