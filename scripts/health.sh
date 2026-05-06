#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib.sh"

ensure_env_file
cd "$ROOT_DIR"

port="$(env_value OPENCLAW_GATEWAY_PORT)"
port="${port:-18789}"
token="$(env_value OPENCLAW_GATEWAY_TOKEN)"

echo "Checking unauthenticated liveness..."
curl -fsS "http://127.0.0.1:${port}/healthz"
echo

if [[ -n "$token" ]]; then
  echo "Checking authenticated OpenClaw health..."
  compose exec -T openclaw-gateway node dist/index.js health --token "$token"
fi
