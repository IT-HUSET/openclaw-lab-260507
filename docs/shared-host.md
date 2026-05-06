# Shared Docker Host Lab

Use this mode when participants cannot run Docker on their own computers, but can SSH into a shared machine on the same local network.

Example shared host:

```text
172.24.110.136
```

## Mental Model

Each participant gets a separate OpenClaw instance on the shared Docker host:

| Participant | Gateway URL | Env file | Compose project |
| --- | --- | --- | --- |
| p01 | `http://172.24.110.136:18789/` | `instances/p01.env` | `openclaw-p01` |
| p02 | `http://172.24.110.136:18889/` | `instances/p02.env` | `openclaw-p02` |

The participant does onboarding in an SSH terminal. They open the Control UI in their own browser.

## Facilitator Setup

On the shared host:

```bash
git clone <repo-url>
cd openclaw-getting-started
docker compose version
```

### SSH Account Model

Multiple participants can SSH to the same macOS or Linux account, for example:

```bash
ssh multi-claw@172.24.110.136
```

This is acceptable for a trusted lab, but it is not isolation. Everyone logged in as `multi-claw` can usually read the same files, see the same shell history, inspect the same Docker projects, and stop or modify another participant's container if they know the commands.

Use the shared-account approach when you want low setup overhead and participants are trusted colleagues. Use one Unix account per participant, Docker rootless setups, or separate VMs if participants should not be able to affect each other.

If using one shared account:

- Put each participant in a separate OpenClaw instance under `instances/<participant-id>/`.
- Assign each participant a unique port pair.
- Give each participant only their own token and URL.
- Ask participants to run only `./scripts/setup-shared-instance.sh <id> <port> <host>` and `./scripts/instance.sh <id> ...`.
- Avoid production API keys and production messaging accounts.

Prepare 20 participant slots:

```bash
./scripts/prepare-shared-host.sh 20 172.24.110.136
```

This creates:

- `instances/p01.env` through `instances/p20.env`
- `instances/p01/` through `instances/p20/`
- `instances/roster.tsv`
- unique gateway and bridge ports
- unique gateway tokens

The default port plan starts at `18789` and increments by `100`, so `p01` gets `18789`, `p02` gets `18889`, and so on.

## Participant Instructions

Give each participant:

- SSH details for the shared host.
- Their participant id.
- Their assigned gateway port.
- The host IP or DNS name.

Example for participant `p01`:

```bash
ssh multi-claw@172.24.110.136
cd openclaw-getting-started
./scripts/setup-shared-instance.sh p01 18789 172.24.110.136
```

The setup script runs the same interactive onboarding as local Docker setup. When it finishes, `p01` opens this URL on their own computer:

```text
http://172.24.110.136:18789/
```

If OpenClaw asks for a token, the setup script printed it at the end. It is also stored in that participant's env file.

## Later Commands

From the shared host:

```bash
./scripts/instance.sh p01 url
./scripts/instance.sh p01 dashboard
./scripts/instance.sh p01 health
./scripts/instance.sh p01 cli doctor
./scripts/instance.sh p01 logs
./scripts/instance.sh p01 stop
./scripts/instance.sh p01 start
```

## Port Plan

Use one gateway port plus the next port for the bridge:

| Participant | Gateway | Bridge |
| --- | ---: | ---: |
| p01 | 18789 | 18790 |
| p02 | 18889 | 18890 |
| p03 | 18989 | 18990 |
| p04 | 19089 | 19090 |

For 20 participants with the default plan, the last participant `p20` uses gateway port `20689` and bridge port `20690`.

Avoid reusing a port while an instance is still running.

## Security Notes

This mode intentionally publishes gateway ports on the shared host. The scripts bind Docker to `0.0.0.0` by default and use `172.24.110.136` as the browser-facing host. Keep it on a trusted lab network, give each participant a unique token, and do not use production accounts or broad filesystem mounts.

For a less exposed setup, keep `OPENCLAW_PUBLISH_HOST=127.0.0.1` and use SSH tunnels. That is safer but harder for a workshop.
