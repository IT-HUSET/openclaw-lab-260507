#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
Usage:
  ./scripts/shared-docker-host/instance.sh <participant-id> <command> [args...]

Commands:
  start
  stop
  logs
  health
  dashboard
  security-audit [args...]
  cli <openclaw-args...>
  url
  ps

Examples:
  ./scripts/shared-docker-host/instance.sh 1 dashboard
  ./scripts/shared-docker-host/instance.sh p01 dashboard
  ./scripts/shared-docker-host/instance.sh p01 cli doctor
  ./scripts/shared-docker-host/instance.sh p01 logs
EOF
  exit 1
}

[[ $# -ge 2 ]] || usage

PARTICIPANT_ID="$1"
COMMAND="$2"
shift 2

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# shellcheck disable=SC1091
source "$SCRIPT_DIR/../common/participants.sh"

if is_participant_index "$PARTICIPANT_ID"; then
  PARTICIPANT_ID="$(participant_id_for_index "$PARTICIPANT_ID")"
fi

validate_participant_id "$PARTICIPANT_ID" || usage

INSTANCE_ENV_REL="instances/${PARTICIPANT_ID}.env"
INSTANCE_ENV="$ROOT_DIR/$INSTANCE_ENV_REL"

[[ -f "$INSTANCE_ENV" ]] || {
  echo "ERROR: Missing $INSTANCE_ENV_REL. Run scripts/shared-docker-host/setup-instance.sh first." >&2
  exit 1
}

export OPENCLAW_ENV_FILE="$INSTANCE_ENV_REL"
export OPENCLAW_COMPOSE_PROJECT="openclaw-${PARTICIPANT_ID}"

# shellcheck disable=SC1091
source "$SCRIPT_DIR/../common/lib.sh"

case "$COMMAND" in
  start)
    exec "$SCRIPT_DIR/../local-docker/start.sh" "$@"
    ;;
  stop)
    exec "$SCRIPT_DIR/../local-docker/stop.sh" "$@"
    ;;
  logs)
    exec "$SCRIPT_DIR/../local-docker/logs.sh" "$@"
    ;;
  health)
    exec "$SCRIPT_DIR/../local-docker/health.sh" "$@"
    ;;
  dashboard)
    exec "$SCRIPT_DIR/../local-docker/dashboard.sh" "$@"
    ;;
  security-audit)
    exec "$SCRIPT_DIR/../local-docker/security-audit.sh" "$@"
    ;;
  cli)
    exec "$SCRIPT_DIR/../local-docker/cli.sh" "$@"
    ;;
  url)
    public_host="$(env_value OPENCLAW_PUBLIC_HOST)"
    gateway_port="$(env_value OPENCLAW_GATEWAY_PORT)"
    echo "http://${public_host:-127.0.0.1}:${gateway_port:-18789}/"
    ;;
  ps)
    compose ps "$@"
    ;;
  *)
    usage
    ;;
esac
