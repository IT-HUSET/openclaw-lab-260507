# Native Multi-Gateway Lab

Use this mode when participants cannot run Docker locally and you want to run multiple OpenClaw gateways directly under one macOS account, for example `multi-claw`.

This is not the same as the shared Docker host mode. No containers or Compose projects are used here. OpenClaw is installed directly on the account, and each participant gets a separate OpenClaw profile and gateway port.

## When To Use This

Use native multi-gateway when:

- Docker Desktop is unavailable, too heavy, or not wanted on the lab machine.
- The lab machine can run OpenClaw directly.
- Participants are trusted colleagues.
- You are comfortable managing OpenClaw profiles instead of Docker volumes.

Prefer `docs/shared-docker-host.md` when you want repo-driven setup, containerized state folders, and easier cleanup.

## SSH Account Model

Multiple participants can SSH to the same macOS account:

```bash
ssh multi-claw@172.24.110.136
```

This is low-overhead, but it is not isolation. Everyone logged in as `multi-claw` can generally inspect the same files, shell history, processes, and OpenClaw profile directories.

For a trusted lab, this is acceptable. For stronger isolation, use one Unix account per participant, one VM per participant/group, or the shared Docker host mode with clear participant folders and Compose projects.

## Install OpenClaw Once

Run this as the `multi-claw` user:

```bash
curl -fsSL https://openclaw.ai/install.sh | bash -s -- --no-onboard
```

Then open a fresh shell and verify:

```bash
openclaw --version
```

## Port Plan

The OpenClaw multiple-gateway model uses a base gateway port and derives related ports from it. Leave room between participant base ports. A 20-port step follows the upstream multiple-gateway guidance.

Example:

| Participant | Profile | Gateway Port | Control UI |
| --- | --- | ---: | --- |
| p01 | `p01` | 18789 | `http://172.24.110.136:18789/` |
| p02 | `p02` | 18809 | `http://172.24.110.136:18809/` |
| p03 | `p03` | 18829 | `http://172.24.110.136:18829/` |
| p04 | `p04` | 18849 | `http://172.24.110.136:18849/` |

## Participant Setup

Participant `p01`:

```bash
ssh multi-claw@172.24.110.136
openclaw --profile p01 onboard
openclaw --profile p01 gateway install --port 18789
```

Participant `p02`:

```bash
ssh multi-claw@172.24.110.136
openclaw --profile p02 onboard
openclaw --profile p02 gateway install --port 18809
```

Each participant opens their assigned URL from their own browser.

## Status And Troubleshooting

Check one profile:

```bash
openclaw --profile p01 gateway status --deep
openclaw --profile p01 gateway probe
openclaw --profile p01 status
```

Restart one gateway:

```bash
openclaw --profile p01 gateway restart
```

Stop one gateway:

```bash
openclaw --profile p01 gateway stop
```

## Cleanup

Stop gateways before removing profiles:

```bash
openclaw --profile p01 gateway stop
openclaw --profile p02 gateway stop
```

Then remove or archive the corresponding OpenClaw profile directories according to the current OpenClaw docs and your local lab policy.

## Native Versus Docker

| Question | Native Multi-Gateway | Shared Docker Host |
| --- | --- | --- |
| Requires Docker | No | Yes |
| Isolation unit | OpenClaw profile | Compose project plus bind-mounted folders |
| Port step | 20 by convention | 100 by this repo's scripts |
| Cleanup | OpenClaw profile/gateway state | `instances/<id>/` plus Compose project |
| Best for | Direct macOS lab machine | Repeatable repo-driven lab |

## Security Notes

Use dedicated lab API keys and accounts. Do not use production messaging accounts or broad filesystem access. If ports are reachable on the LAN, treat gateway URLs and tokens as sensitive lab credentials.

Source: OpenClaw [Multiple Gateways](https://docs.openclaw.ai/gateway/multiple-gateways).
