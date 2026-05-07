# Facilitator Guide

Use this guide to choose and prepare the lab setup. Send participants only the participant document for the mode they will use.

## Choose A Mode

| Mode | Best When | Participant Doc |
| --- | --- | --- |
| Local Docker | Participants can run Docker on their own computers. | `docs/participants/local-docker.md` |
| Shared Docker Host | Participants cannot run Docker locally, but can SSH to a Docker host. | `docs/participants/shared-docker-host.md` |
| Native Multi-Gateway | Docker is unavailable or unwanted on the shared macOS lab account. | `docs/participants/native-multi-gateway.md` |
| Azure VM | You need a cloud-hosted Linux backup path. | `docs/participants/azure-vm.md` |

For trusted colleagues, a shared account such as `multi-claw@172.24.110.136` is acceptable. It is not isolation: users of the same Unix account can generally inspect the same files, processes, and history.

After setup, send participants to `docs/participants/customization-lab.md` to choose a personalization track. Use `docs/participants/customization-lab-basic.md` for dashboard-first participants and `docs/participants/customization-lab-advanced.md` for participants who are comfortable with terminal commands, workspace files, heartbeat, cron jobs, personal-assistant setup, and a knowledge vault.

## Common Prep

- Confirm each participant has a model provider API key or a lab-specific shared provider plan.
- Use dedicated lab accounts and bot tokens for messaging channels.
- Review `docs/reference/security.md`.
- Decide whether participants should use production machines, a shared host, or Azure.
- Keep gateway ports on a trusted lab network unless using SSH tunnels.

## Optional Lab Preconfiguration

Use this when facilitators want Shared Docker Host or Native Multi-Gateway instances to start with provider API keys, gateway token refs, and broad tool access already configured.

On the shared host:

```bash
cp resources/lab-secrets.env.example resources/lab-secrets.env
$EDITOR resources/lab-secrets.env
chmod 600 resources/lab-secrets.env
```

Set either a shared provider key, such as `ANTHROPIC_API_KEY`, or per-participant overrides such as `P01_ANTHROPIC_API_KEY`. If `OPENCLAW_LAB_AUTH_CHOICE` is empty, the scripts infer the onboarding provider from the first configured key.

When `resources/lab-secrets.env` exists and `OPENCLAW_LAB_PRECONFIGURE=1`, the shared-host scripts:

- copy whitelisted provider values into each participant env file
- run `openclaw onboard --non-interactive` with `--secret-input-mode ref`
- store gateway auth as an `OPENCLAW_GATEWAY_TOKEN` env ref
- apply the unrestricted lab tool policy when `OPENCLAW_LAB_UNRESTRICTED=1`

The unrestricted policy sets `tools.profile="full"`, disables OpenClaw's tool sandbox, runs exec on the gateway host with `security="full"` and `ask="off"`, disables workspace-only guards for filesystem/apply-patch tools, and allows browser access to private-network targets. Use only on trusted lab hosts with dedicated lab credentials.

## Local Docker Prep

Ask participants to use `docs/participants/local-docker.md`.

No roster is required. Each participant runs:

```bash
cp .env.example .env
./scripts/local-docker/setup.sh
```

## Shared Docker Host Prep

On the shared Docker host:

```bash
ssh multi-claw@172.24.110.136
cd openclaw-getting-started
docker compose version
./scripts/shared-docker-host/prepare.sh 20 172.24.110.136
```

If `resources/lab-secrets.env` exists, `prepare.sh` also pre-seeds `instances/pNN.env` for non-interactive setup.

This creates:

- `instances/p01.env` through `instances/p20.env`
- `instances/p01/` through `instances/p20/`
- `instances/roster.tsv`
- unique gateway and bridge ports
- unique gateway tokens

Give each participant one row from `instances/roster.tsv`. The default port plan starts at `18789` and increments by `20`.

With the default plan, participants can use their numeric index instead of typing the generated id and port. For example, participant `1` maps to `p01` on port `18789`, and participant `2` maps to `p02` on port `18809`.

## Native Multi-Gateway Prep

Install OpenClaw once under the shared macOS account:

```bash
ssh multi-claw@172.24.110.136
curl -fsSL https://openclaw.ai/install.sh | bash -s -- --no-onboard
openclaw --version
```

Assign each participant a profile and base gateway port. Leave at least 20 ports between base ports because OpenClaw derives browser/control/CDP ports from the base gateway port.

Example roster:

| Participant | Profile | Gateway Port | URL |
| --- | --- | ---: | --- |
| p01 | `p01` | 18789 | `http://172.24.110.136:18789/` |
| p02 | `p02` | 18809 | `http://172.24.110.136:18809/` |
| p03 | `p03` | 18829 | `http://172.24.110.136:18829/` |

Participants can use:

```bash
./scripts/native-multi-gateway/setup-profile.sh 1 172.24.110.136
```

The script runs onboarding and then installs the gateway service for that profile. If `resources/lab-secrets.env` exists, it writes profile secrets to `~/.openclaw-pNN/.env`, runs non-interactive onboarding, and applies the unrestricted lab policy when enabled. If onboarding already installed the service, the install command may report that no extra work is needed.

## Azure VM Prep

Use `docs/participants/azure-vm.md` if the facilitator is also provisioning the VM. The Azure path creates a VM without a public IP and uses Azure Bastion for SSH.

## Sharing Configuration Files With Participants

Local Docker participants edit `data/config/` and `data/workspace/` directly on their own laptop. Shared Docker host and native multi-gateway participants do not — their config and workspace files live on the shared host. This section is the one-time host prep needed to let those participants edit from their own machines.

The kit ships read-only helpers that print connection details for a participant once host prep is in place:

```bash
./scripts/shared-docker-host/share-instance.sh 1
./scripts/shared-docker-host/share-instance.sh p01 participant01

./scripts/native-multi-gateway/share-profile.sh 1
./scripts/native-multi-gateway/share-profile.sh p01 172.24.110.136 multi-claw
```

These scripts do not configure SSH users, file permissions, or File Sharing. That is intentional — host security policy varies and the kit avoids privileged actions on the shared host.

### Pick An Access Pattern

| Pattern | Best For | Host Prep |
| --- | --- | --- |
| Remote-SSH (VS Code/Cursor) | Developer participants. Best DX, scales well. | SSH access only. |
| `scp` | One-off file copy. | SSH access only. |
| SSHFS | Networks that block SMB (port 445). | SSH access only; participant installs `sshfs`. |
| SMB / File Sharing | Drag-and-drop, non-developer participants. | macOS File Sharing or `samba` enabled, per-user share scoping. |

For most workshops, Remote-SSH plus `scp` is enough and needs no host prep beyond the SSH access participants already use to reach the shared host.

### Per-Participant Isolation On The Shared Host

If everyone logs in as the same Unix account (for example `multi-claw`), there is no isolation. Acceptable for trusted-colleague workshops; not acceptable if participants should not see one another's API keys, tokens, or workspace files.

For real isolation on the shared Docker host, create one macOS user per participant and scope ownership of both `instances/pNN/` and the matching `instances/pNN.env` file:

```bash
# On the shared macOS host, per participant
sudo sysadminctl -addUser participant01 -fullName "Participant 01" -password -
sudo chown -R participant01:staff /Users/multi-claw/openclaw-getting-started/instances/p01 \
  /Users/multi-claw/openclaw-getting-started/instances/p01.env
sudo chmod 700 /Users/multi-claw/openclaw-getting-started/instances/p01
sudo chmod 600 /Users/multi-claw/openclaw-getting-started/instances/p01.env
```

Native multi-gateway is harder to isolate because OpenClaw's profile directories live under a single user's home. Either accept the trusted-lab posture or use POSIX ACLs:

```bash
chmod +a "participant01 allow read,write,execute,delete,add_file,add_subdirectory,file_inherit,directory_inherit" \
  "$HOME/.openclaw/profiles/p01"
```

### Optional: Enable SMB File Sharing On The Shared Host

Use this only when participants prefer Finder/Explorer over Remote-SSH. On macOS:

1. System Settings -> General -> Sharing -> File Sharing -> turn on.
2. Add the shared folder, for example `/Users/multi-claw/openclaw-getting-started/instances`.
3. Set per-user permissions so each participant has Read & Write only on their own `pNN/` directory.
4. Confirm port 445/tcp is reachable from the lab network.

Participants then connect with `smb://<host>/<share>` from Finder (Cmd+K) or `\\<host>\<share>` from Explorer.

## Customization Lab Prep

Run the customization lab only after each participant has a healthy gateway.

Suggested flow:

1. Let the Web UI start OpenClaw bootstrapping and have participants answer the bootstrap questions.
2. Ask the assistant to describe its environment, workspace files, memory, tools, and boundaries.
3. Add workspace instructions and low-risk personal preferences.
4. Introduce the agentic mindset: memory, knowledge vault, heartbeat, cron jobs, background tasks, standing orders, hooks, and task flows.
5. Build a workshop-safe personal assistant role.
6. Create a small knowledge vault.
7. Review tools, gateway exposure, heartbeat, cron jobs, and channel policy before connecting external services.

Keep messaging channels optional unless you have dedicated lab accounts and a clear moderation plan.

For non-developer participants, prepare the environment before the exercise and give each person a URL, token if needed, participant index, and first prompt. Terminal and SSH commands should be copied exactly or handled by facilitators.

## Wrap-Up

- Stop local Docker gateways with `./scripts/local-docker/stop.sh`.
- Stop shared Docker instances with `./scripts/shared-docker-host/instance.sh <id> stop`.
- Stop native gateways with `./scripts/native-multi-gateway/stop-profile.sh <profile>`.
- Delete or archive lab state after checking no participant needs it.
- For Azure, deallocate or delete resources to control cost.
