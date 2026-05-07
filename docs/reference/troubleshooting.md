# Troubleshooting

## Docker Compose Is Missing

```bash
docker compose version
```

If this fails, install Docker Desktop or the Docker Compose v2 plugin.

## Image Pull Fails

The first setup can look quiet for a while while Docker Desktop pulls the OpenClaw image. The image is large, so wait until Docker reaches the full size and prints that the pull completed.

If the progress does not move for several minutes, stop with `Ctrl-C` and pull the image directly:

```bash
docker pull ghcr.io/openclaw/openclaw:latest
```

If that also stalls at the same byte count, restart Docker Desktop and retry the same command. Docker usually reuses the already downloaded layers.

Then rerun setup:

```bash
./scripts/local-docker/setup.sh
```

The script will reuse the existing `.env` and continue from the next step.

Check the image name:

```bash
grep OPENCLAW_IMAGE .env
docker pull ghcr.io/openclaw/openclaw:latest
```

If your network blocks GitHub Container Registry, build from the upstream OpenClaw repository or mirror the image internally.

## Gateway Is Not Healthy

```bash
./scripts/local-docker/logs.sh
./scripts/local-docker/health.sh
```

Check whether the port is already in use:

```bash
lsof -iTCP:18789 -sTCP:LISTEN
```

Set a different host port in `.env`:

```text
OPENCLAW_GATEWAY_PORT=18791
```

Then rerun:

```bash
./scripts/local-docker/start.sh
```

## Claude CLI Is Not Authenticated

If onboarding says:

```text
Claude CLI is not authenticated on this host.
Run claude auth login first, then re-run this setup.
```

In Docker, "this host" means the OpenClaw container, not your Mac. For the lab, rerun setup and choose **Anthropic API key** instead of **Anthropic Claude CLI**.

```bash
./scripts/local-docker/setup.sh
```

If you already have an Anthropic API key, you can add it to `.env` before rerunning:

```text
ANTHROPIC_API_KEY=sk-ant-...
```

Claude CLI reuse is possible, but it requires making Claude CLI and its credentials available inside the container. That is more brittle than an API key for Docker Desktop and Azure VM labs.

## Permission Errors In data/

The OpenClaw image runs as a non-root user. On Linux, fix ownership if needed:

```bash
sudo chown -R 1000:1000 data/config data/workspace
```

## Control UI Says Pairing Required

Ask OpenClaw for a fresh dashboard URL:

```bash
./scripts/local-docker/dashboard.sh
```

List and approve devices if needed:

```bash
./scripts/local-docker/cli.sh devices list
./scripts/local-docker/cli.sh devices approve <request-id>
```

## Local Docker Setup Printed A URL But Nothing Is Listening

If onboarding prints a Control UI URL with:

```text
Gateway: not detected (connect ECONNREFUSED 127.0.0.1:18789)
```

that URL came from the onboarding container before Docker published the gateway port. Finish setup by exiting the OpenClaw TUI in that terminal, then rerun the Docker setup completion path:

```bash
OPENCLAW_SKIP_ONBOARDING=1 ./scripts/local-docker/setup.sh
./scripts/local-docker/health.sh
```

## Reset Local State

```bash
./scripts/local-docker/stop.sh
rm -rf data/
./scripts/local-docker/setup.sh
```
