# Troubleshooting

## Docker Compose Is Missing

```bash
docker compose version
```

If this fails, install Docker Desktop or the Docker Compose v2 plugin.

## Image Pull Fails

Check the image name:

```bash
grep OPENCLAW_IMAGE .env
docker pull ghcr.io/openclaw/openclaw:latest
```

If your network blocks GitHub Container Registry, build from the upstream OpenClaw repository or mirror the image internally.

## Gateway Is Not Healthy

```bash
./scripts/logs.sh
./scripts/health.sh
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
./scripts/start.sh
```

## Permission Errors In data/

The OpenClaw image runs as a non-root user. On Linux, fix ownership if needed:

```bash
sudo chown -R 1000:1000 data/config data/workspace
```

## Control UI Says Pairing Required

Ask OpenClaw for a fresh dashboard URL:

```bash
./scripts/dashboard.sh
```

List and approve devices if needed:

```bash
./scripts/cli.sh devices list
./scripts/cli.sh devices approve <request-id>
```

## Reset Local State

```bash
./scripts/stop.sh
rm -rf data/
./scripts/setup-local.sh
```
