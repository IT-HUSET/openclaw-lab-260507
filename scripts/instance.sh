#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
Usage:
  ./scripts/instance.sh <participant-id> <command> [args...]

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
  ./scripts/instance.sh alice dashboard
  ./scripts/instance.sh alice cli doctor
  ./scripts/instance.sh alice logs
EOF
  exit 1
}

[[ $# -ge 2 ]] || usage

PARTICIPANT_ID="$1"
COMMAND="$2"
shift 2

[[ "$PARTICIPANT_ID" =~ ^[a-z0-9][a-z0-9-]*$ ]] || usage

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
INSTANCE_ENV_REL="instances/${PARTICIPANT_ID}.env"
INSTANCE_ENV="$ROOT_DIR/$INSTANCE_ENV_REL"

[[ -f "$INSTANCE_ENV" ]] || {
  echo "ERROR: Missing $INSTANCE_ENV_REL. Run setup-shared-instance.sh first." >&2
  exit 1
}

export OPENCLAW_ENV_FILE="$INSTANCE_ENV_REL"
export OPENCLAW_COMPOSE_PROJECT="openclaw-${PARTICIPANT_ID}"

# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib.sh"

case "$COMMAND" in
  start)
    exec "$SCRIPT_DIR/start.sh" "$@"
    ;;
  stop)
    exec "$SCRIPT_DIR/stop.sh" "$@"
    ;;
  logs)
    exec "$SCRIPT_DIR/logs.sh" "$@"
    ;;
  health)
    exec "$SCRIPT_DIR/health.sh" "$@"
    ;;
  dashboard)
    exec "$SCRIPT_DIR/dashboard.sh" "$@"
    ;;
  security-audit)
    exec "$SCRIPT_DIR/security-audit.sh" "$@"
    ;;
  cli)
    exec "$SCRIPT_DIR/cli.sh" "$@"
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
