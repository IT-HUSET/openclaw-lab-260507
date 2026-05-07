# Native Multi-Gateway Participant Guide

Use this mode when the facilitator gives you a participant index and SSH access to a shared macOS account where OpenClaw is installed directly. The scripts derive your OpenClaw profile and port from the index.

This is not the same as the shared Docker host mode. No containers or Compose projects are used here. Each participant gets a separate OpenClaw profile and gateway port.

Example assignment:

| Field | Value |
| --- | --- |
| SSH account | `multi-claw@172.24.110.136` |
| Participant index | `1` |
| Profile | `p01` |
| Gateway port | `18789` |
| Browser URL | `http://172.24.110.136:18789/` |

## Setup

SSH to the shared host:

```bash
ssh multi-claw@172.24.110.136
cd openclaw-getting-started
```

Run your assigned setup command:

```bash
./scripts/native-multi-gateway/setup-profile.sh 1 172.24.110.136
```

The script usually runs:

```bash
openclaw --profile p01 onboard --skip-ui
openclaw --profile p01 gateway install --port 18789
```

Onboarding creates/configures your profile, including profile-specific config, state, workspace, and credentials. The setup script skips the final UI handoff so it can continue to `gateway install --port ...`, which installs the managed gateway service for your assigned port. The OpenClaw docs note that if onboarding already installed the service, the final install command is not needed; the helper script still runs it so setup is explicit and repeatable.

If the facilitator preconfigured the lab, setup may run non-interactively and skip provider-key prompts.

Participant index `1` maps to profile `p01` and port `18789`; index `2` maps to profile `p02` and port `18809`.

When setup finishes, open your assigned URL from your own browser:

```text
http://172.24.110.136:18789/
```

## Later Commands

Check your profile:

```bash
./scripts/native-multi-gateway/url.sh 1 172.24.110.136
./scripts/native-multi-gateway/dashboard.sh 1
./scripts/native-multi-gateway/health.sh 1
./scripts/native-multi-gateway/logs.sh 1
./scripts/native-multi-gateway/status.sh 1
```

Restart your gateway:

```bash
openclaw --profile p01 gateway restart
```

Stop your gateway:

```bash
./scripts/native-multi-gateway/stop-profile.sh 1
```

OpenClaw CLI commands for your profile:

```bash
openclaw --profile p01 status
openclaw --profile p01 gateway probe
openclaw --profile p01 gateway status --deep
```

## Boundaries

If everyone logs in as the same Unix account, this is a trusted-lab setup, not isolation. Stay inside your assigned OpenClaw profile and do not inspect or change other participants' profiles or processes.

Source: OpenClaw [Multiple Gateways](https://docs.openclaw.ai/gateway/multiple-gateways).
