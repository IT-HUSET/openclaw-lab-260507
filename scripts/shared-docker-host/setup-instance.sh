#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
Usage:
  ./scripts/shared-docker-host/setup-instance.sh <participant-index> <host-ip-or-dns> [publish-host]
  ./scripts/shared-docker-host/setup-instance.sh <participant-id> <gateway-port> <host-ip-or-dns> [publish-host]

Example:
  ./scripts/shared-docker-host/setup-instance.sh 1 172.24.110.136
  ./scripts/shared-docker-host/setup-instance.sh 01 172.24.110.136
  ./scripts/shared-docker-host/setup-instance.sh p01 18789 172.24.110.136

The participant-id must be lowercase letters, numbers, or hyphens.
publish-host defaults to 0.0.0.0 for shared Docker host labs.
Numeric participant indices use participant id pNN and port 18789 + (index - 1) * 20.
EOF
  exit 1
}

[[ $# -ge 2 && $# -le 4 ]] || usage

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# shellcheck disable=SC1091
source "$SCRIPT_DIR/../common/participants.sh"

if [[ $# -ge 2 && $# -le 3 ]] && is_participant_index "$1"; then
  PARTICIPANT_ID="$(participant_id_for_index "$1")"
  GATEWAY_PORT="$(participant_port_for_index "$1" 18789 20)"
  HOST_NAME="$2"
  PUBLISH_HOST_ARG="${3:-}"
elif [[ $# -ge 3 && $# -le 4 ]]; then
  PARTICIPANT_ID="$1"
  GATEWAY_PORT="$2"
  HOST_NAME="$3"
  PUBLISH_HOST_ARG="${4:-}"
else
  usage
fi

validate_participant_id "$PARTICIPANT_ID" || usage
[[ "$GATEWAY_PORT" =~ ^[0-9]+$ ]] || usage
(( GATEWAY_PORT > 0 && GATEWAY_PORT < 65535 )) || usage

BRIDGE_PORT="$((GATEWAY_PORT + 1))"

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
source "$SCRIPT_DIR/../common/lib.sh"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../common/preconfigure.sh"

existing_publish_host="$(env_value OPENCLAW_PUBLISH_HOST)"
if [[ -n "$PUBLISH_HOST_ARG" ]]; then
  PUBLISH_HOST="$PUBLISH_HOST_ARG"
elif [[ -n "$existing_publish_host" ]]; then
  PUBLISH_HOST="$existing_publish_host"
else
  PUBLISH_HOST="0.0.0.0"
fi

set_env_value OPENCLAW_CONTAINER_ENV_FILE "./$INSTANCE_ENV_REL"
set_env_value OPENCLAW_CONFIG_DIR "./instances/${PARTICIPANT_ID}/config"
set_env_value OPENCLAW_WORKSPACE_DIR "./instances/${PARTICIPANT_ID}/workspace"
set_env_value OPENCLAW_PUBLISH_HOST "$PUBLISH_HOST"
set_env_value OPENCLAW_PUBLIC_HOST "$HOST_NAME"
set_env_value OPENCLAW_GATEWAY_PORT "$GATEWAY_PORT"
set_env_value OPENCLAW_BRIDGE_PORT "$BRIDGE_PORT"
set_env_value OPENCLAW_GATEWAY_BIND lan

apply_lab_secrets_to_env_file "$PARTICIPANT_ID" "$INSTANCE_ENV"

echo "Participant: $PARTICIPANT_ID"
echo "Env file:    $INSTANCE_ENV_REL"
echo "Project:     $COMPOSE_PROJECT"
echo "Gateway:     http://${HOST_NAME}:${GATEWAY_PORT}/"
echo
echo "Starting participant onboarding. Complete the prompts in this terminal."
echo

"$SCRIPT_DIR/../local-docker/setup.sh"
