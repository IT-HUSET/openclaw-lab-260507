#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
Usage:
  ./scripts/prepare-shared-host.sh <count> <host-ip-or-dns> [start-gateway-port] [participant-prefix] [port-step] [publish-host]

Examples:
  ./scripts/prepare-shared-host.sh 20 172.24.110.136
  ./scripts/prepare-shared-host.sh 20 172.24.110.136 18789 p 100
  ./scripts/prepare-shared-host.sh 12 openclaw-lab.local 18789 team- 100

Creates per-participant env files under instances/ and writes instances/roster.tsv.
It does not run OpenClaw onboarding. Participants run setup-shared-instance.sh themselves.

publish-host defaults to 0.0.0.0 for shared-host labs. host-ip-or-dns is the
address participants open in their browsers.
EOF
  exit 1
}

[[ $# -ge 2 && $# -le 6 ]] || usage

COUNT="$1"
HOST_NAME="$2"
START_PORT="${3:-18789}"
PARTICIPANT_PREFIX="${4:-p}"
PORT_STEP="${5:-100}"
PUBLISH_HOST="${6:-0.0.0.0}"

[[ "$COUNT" =~ ^[0-9]+$ ]] || usage
[[ "$START_PORT" =~ ^[0-9]+$ ]] || usage
[[ "$PORT_STEP" =~ ^[0-9]+$ ]] || usage
(( COUNT > 0 )) || usage
(( START_PORT > 0 && START_PORT < 65535 )) || usage
(( PORT_STEP > 1 )) || usage

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib.sh"

cd "$ROOT_DIR"

require_cmd docker
docker compose version >/dev/null 2>&1 || die "Docker Compose v2 is required"

mkdir -p "$ROOT_DIR/instances"
ROSTER="$ROOT_DIR/instances/roster.tsv"

openclaw_image="$(env_value_from "$ROOT_DIR/.env.example" OPENCLAW_IMAGE)"
openclaw_image="${openclaw_image:-ghcr.io/openclaw/openclaw:latest}"

echo "Pulling OpenClaw image once for the shared host: $openclaw_image"
docker pull "$openclaw_image"

printf "participant_id\tgateway_port\tbridge_port\turl\tenv_file\tcompose_project\tonboarding_command\n" > "$ROSTER"

for i in $(seq 1 "$COUNT"); do
  participant_id="${PARTICIPANT_PREFIX}$(printf "%02d" "$i")"
  [[ "$participant_id" =~ ^[a-z0-9][a-z0-9-]*$ ]] || die "Invalid generated participant id: $participant_id"

  gateway_port="$((START_PORT + ((i - 1) * PORT_STEP)))"
  bridge_port="$((gateway_port + 1))"
  (( bridge_port < 65535 )) || die "Port range exceeds 65534 at participant $participant_id"

  instance_env_rel="instances/${participant_id}.env"
  instance_env="$ROOT_DIR/$instance_env_rel"
  mkdir -p "$ROOT_DIR/instances/$participant_id"

  if [[ ! -f "$instance_env" ]]; then
    cp "$ROOT_DIR/.env.example" "$instance_env"
    chmod 600 "$instance_env" || true
  fi

  token="$(env_value_from "$instance_env" OPENCLAW_GATEWAY_TOKEN)"
  if [[ -z "$token" ]]; then
    token="$(generate_token)"
    set_env_value_in "$instance_env" OPENCLAW_GATEWAY_TOKEN "$token"
  fi

  set_env_value_in "$instance_env" OPENCLAW_CONTAINER_ENV_FILE "./$instance_env_rel"
  set_env_value_in "$instance_env" OPENCLAW_CONFIG_DIR "./instances/${participant_id}/config"
  set_env_value_in "$instance_env" OPENCLAW_WORKSPACE_DIR "./instances/${participant_id}/workspace"
  set_env_value_in "$instance_env" OPENCLAW_PUBLISH_HOST "$PUBLISH_HOST"
  set_env_value_in "$instance_env" OPENCLAW_PUBLIC_HOST "$HOST_NAME"
  set_env_value_in "$instance_env" OPENCLAW_GATEWAY_PORT "$gateway_port"
  set_env_value_in "$instance_env" OPENCLAW_BRIDGE_PORT "$bridge_port"
  set_env_value_in "$instance_env" OPENCLAW_GATEWAY_BIND lan

  mkdir -p "$ROOT_DIR/instances/$participant_id/config" "$ROOT_DIR/instances/$participant_id/workspace"

  onboarding_command="./scripts/setup-shared-instance.sh $participant_id $gateway_port $HOST_NAME"
  url="http://${HOST_NAME}:${gateway_port}/"
  printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\n" \
    "$participant_id" \
    "$gateway_port" \
    "$bridge_port" \
    "$url" \
    "$instance_env_rel" \
    "openclaw-${participant_id}" \
    "$onboarding_command" >> "$ROSTER"
done

echo
echo "Prepared $COUNT shared OpenClaw instance definitions."
echo "Roster: $ROSTER"
echo
column -t -s $'\t' "$ROSTER" 2>/dev/null || cat "$ROSTER"
echo
echo "Participant command example:"
first_id="${PARTICIPANT_PREFIX}$(printf "%02d" 1)"
echo "  ./scripts/setup-shared-instance.sh $first_id $START_PORT $HOST_NAME"
