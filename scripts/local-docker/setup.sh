#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../common/lib.sh"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../common/preconfigure.sh"

cd "$ROOT_DIR"

require_cmd docker
docker compose version >/dev/null 2>&1 || die "Docker Compose v2 is required"

if [[ ! -f "$ENV_FILE" ]]; then
  mkdir -p "$(dirname "$ENV_FILE")"
  cp "$ROOT_DIR/.env.example" "$ENV_FILE"
  echo "Created $ENV_FILE from .env.example"
fi

token="$(env_value OPENCLAW_GATEWAY_TOKEN)"
if [[ -z "$token" ]]; then
  token="$(generate_token)"
  set_env_value OPENCLAW_GATEWAY_TOKEN "$token"
  chmod 600 "$ENV_FILE" || true
  echo "Generated OPENCLAW_GATEWAY_TOKEN in $ENV_FILE"
fi

config_dir="$(env_value OPENCLAW_CONFIG_DIR)"
workspace_dir="$(env_value OPENCLAW_WORKSPACE_DIR)"
mkdir -p "${config_dir:-./data/config}" "${workspace_dir:-./data/workspace}"

gateway_port="$(env_value OPENCLAW_GATEWAY_PORT)"
gateway_port="${gateway_port:-18789}"
gateway_bind="$(env_value OPENCLAW_GATEWAY_BIND)"
gateway_bind="${gateway_bind:-lan}"

openclaw_image="$(env_value OPENCLAW_IMAGE)"
openclaw_image="${openclaw_image:-ghcr.io/openclaw/openclaw:latest}"

echo "Pulling OpenClaw image: $openclaw_image"
docker pull "$openclaw_image"

if [[ "${OPENCLAW_SKIP_ONBOARDING:-}" == "1" ]]; then
  echo "Skipping onboarding because OPENCLAW_SKIP_ONBOARDING=1"
elif [[ "$(env_value OPENCLAW_NONINTERACTIVE_ONBOARDING)" == "1" ]]; then
  auth_choice="$(env_value OPENCLAW_AUTH_CHOICE)"
  echo "Starting non-interactive OpenClaw onboarding with auth choice '${auth_choice:-skip}'..."
  load_env_file_for_process "$ENV_FILE"
  onboard_args=(dist/index.js)
  while IFS= read -r -d '' arg; do
    onboard_args+=("$arg")
  done < <(openclaw_onboard_args "${auth_choice:-skip}" 18789 "$gateway_bind")
  compose run --rm --no-deps --entrypoint node openclaw-gateway "${onboard_args[@]}"
else
  echo "Starting interactive OpenClaw onboarding..."
  compose run --rm --no-deps --entrypoint node openclaw-gateway \
    dist/index.js onboard --mode local --no-install-daemon --skip-ui
fi

public_host="$(env_value OPENCLAW_PUBLIC_HOST)"
publish_host="$(env_value OPENCLAW_PUBLISH_HOST)"
public_host="${public_host:-${publish_host:-127.0.0.1}}"
allowed_origins="[\"http://localhost:${gateway_port}\",\"http://127.0.0.1:${gateway_port}\""
if [[ "$public_host" != "127.0.0.1" && "$public_host" != "localhost" && "$public_host" != "0.0.0.0" ]]; then
  allowed_origins="${allowed_origins},\"http://${public_host}:${gateway_port}\""
fi
allowed_origins="${allowed_origins}]"

echo "Applying Docker gateway defaults..."
compose run --rm --no-deps --entrypoint node openclaw-gateway \
  dist/index.js config set --batch-json \
  "[{\"path\":\"gateway.mode\",\"value\":\"local\"},{\"path\":\"gateway.bind\",\"value\":\"${gateway_bind}\"},{\"path\":\"gateway.controlUi.allowedOrigins\",\"value\":${allowed_origins}}]"

if [[ "$(env_value OPENCLAW_LAB_UNRESTRICTED)" == "1" ]]; then
  echo "Applying unrestricted lab tool policy..."
  compose run --rm --no-deps --entrypoint node openclaw-gateway \
    dist/index.js config set --batch-json "$(permissive_openclaw_config_json)"
fi

echo "Starting OpenClaw Gateway..."
compose up -d openclaw-gateway

echo
command_prefix=""
if [[ -n "${OPENCLAW_ENV_FILE:-}" ]]; then
  command_prefix="${command_prefix}OPENCLAW_ENV_FILE=${OPENCLAW_ENV_FILE} "
fi
if [[ -n "${OPENCLAW_COMPOSE_PROJECT:-}" ]]; then
  command_prefix="${command_prefix}OPENCLAW_COMPOSE_PROJECT=${OPENCLAW_COMPOSE_PROJECT} "
fi
echo "Gateway URL: http://${public_host}:${gateway_port}/"
echo "Health:      ${command_prefix}./scripts/local-docker/health.sh"
echo "Dashboard:   ${command_prefix}./scripts/local-docker/dashboard.sh"
echo "Token:       $token"
