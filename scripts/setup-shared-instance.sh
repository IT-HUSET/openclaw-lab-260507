#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
Usage:
  ./scripts/setup-shared-instance.sh <participant-id> <gateway-port> <host-ip-or-dns> [publish-host]

Example:
  ./scripts/setup-shared-instance.sh alice 18789 172.24.110.136

The participant-id must be lowercase letters, numbers, or hyphens.
publish-host defaults to 0.0.0.0 for shared-host labs.
EOF
  exit 1
}

[[ $# -ge 3 && $# -le 4 ]] || usage

PARTICIPANT_ID="$1"
GATEWAY_PORT="$2"
HOST_NAME="$3"
PUBLISH_HOST="${4:-0.0.0.0}"

[[ "$PARTICIPANT_ID" =~ ^[a-z0-9][a-z0-9-]*$ ]] || usage
[[ "$GATEWAY_PORT" =~ ^[0-9]+$ ]] || usage

BRIDGE_PORT="$((GATEWAY_PORT + 1))"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

INSTANCE_ENV_REL="instances/${PARTICIPANT_ID}.env"
INSTANCE_ENV="$ROOT_DIR/$INSTANCE_ENV_REL"
COMPOSE_PROJECT="openclaw-${PARTICIPANT_ID}"

mkdir -p "$ROOT_DIR/instances/$PARTICIPANT_ID"
if [[ ! -f "$INSTANCE_ENV" ]]; then
  cp "$ROOT_DIR/.env.example" "$INSTANCE_ENV"
  chmod 600 "$INSTANCE_ENV" || true
fi

export OPENCLAW_ENV_FILE="$INSTANCE_ENV_REL"
export OPENCLAW_COMPOSE_PROJECT="$COMPOSE_PROJECT"

# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib.sh"

set_env_value OPENCLAW_CONTAINER_ENV_FILE "./$INSTANCE_ENV_REL"
set_env_value OPENCLAW_CONFIG_DIR "./instances/${PARTICIPANT_ID}/config"
set_env_value OPENCLAW_WORKSPACE_DIR "./instances/${PARTICIPANT_ID}/workspace"
set_env_value OPENCLAW_PUBLISH_HOST "$PUBLISH_HOST"
set_env_value OPENCLAW_PUBLIC_HOST "$HOST_NAME"
set_env_value OPENCLAW_GATEWAY_PORT "$GATEWAY_PORT"
set_env_value OPENCLAW_BRIDGE_PORT "$BRIDGE_PORT"
set_env_value OPENCLAW_GATEWAY_BIND lan

echo "Participant: $PARTICIPANT_ID"
echo "Env file:    $INSTANCE_ENV_REL"
echo "Project:     $COMPOSE_PROJECT"
echo "Gateway:     http://${HOST_NAME}:${GATEWAY_PORT}/"
echo
echo "Starting participant onboarding. Complete the prompts in this terminal."
echo

"$SCRIPT_DIR/setup-local.sh"
