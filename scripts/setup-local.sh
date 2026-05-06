#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib.sh"

cd "$ROOT_DIR"

require_cmd docker
docker compose version >/dev/null 2>&1 || die "Docker Compose v2 is required"

if [[ ! -f "$ENV_FILE" ]]; then
  cp "$ROOT_DIR/.env.example" "$ENV_FILE"
  echo "Created .env from .env.example"
fi

token="$(env_value OPENCLAW_GATEWAY_TOKEN)"
if [[ -z "$token" ]]; then
  token="$(generate_token)"
  set_env_value OPENCLAW_GATEWAY_TOKEN "$token"
  echo "Generated OPENCLAW_GATEWAY_TOKEN in .env"
fi

config_dir="$(env_value OPENCLAW_CONFIG_DIR)"
workspace_dir="$(env_value OPENCLAW_WORKSPACE_DIR)"
mkdir -p "${config_dir:-./data/config}" "${workspace_dir:-./data/workspace}"

echo "Pulling OpenClaw image..."
compose pull openclaw-gateway openclaw-cli

if [[ "${OPENCLAW_SKIP_ONBOARDING:-}" == "1" ]]; then
  echo "Skipping onboarding because OPENCLAW_SKIP_ONBOARDING=1"
else
  echo "Starting interactive OpenClaw onboarding..."
  compose run --rm --no-deps --entrypoint node openclaw-gateway \
    dist/index.js onboard --mode local --no-install-daemon
fi

gateway_port="$(env_value OPENCLAW_GATEWAY_PORT)"
gateway_port="${gateway_port:-18789}"
gateway_bind="$(env_value OPENCLAW_GATEWAY_BIND)"
gateway_bind="${gateway_bind:-lan}"
allowed_origins="[\"http://localhost:${gateway_port}\",\"http://127.0.0.1:${gateway_port}\"]"

echo "Applying Docker gateway defaults..."
compose run --rm --no-deps --entrypoint node openclaw-gateway \
  dist/index.js config set --batch-json \
  "[{\"path\":\"gateway.mode\",\"value\":\"local\"},{\"path\":\"gateway.bind\",\"value\":\"${gateway_bind}\"},{\"path\":\"gateway.controlUi.allowedOrigins\",\"value\":${allowed_origins}}]"

echo "Starting OpenClaw Gateway..."
compose up -d openclaw-gateway

echo
echo "Gateway URL: http://127.0.0.1:${gateway_port}/"
echo "Health:      ./scripts/health.sh"
echo "Dashboard:   ./scripts/dashboard.sh"
echo "Token:       $token"
