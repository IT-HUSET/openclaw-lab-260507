#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
Usage:
  ./scripts/native-multi-gateway/logs.sh <participant-index> [openclaw-logs-args...]
  ./scripts/native-multi-gateway/logs.sh <profile> [openclaw-logs-args...]

Examples:
  ./scripts/native-multi-gateway/logs.sh 1
  ./scripts/native-multi-gateway/logs.sh p01 --limit 500
  ./scripts/native-multi-gateway/logs.sh 1 --json

With no log arguments, this follows logs with local timestamps.
EOF
  exit 1
}

[[ $# -ge 1 ]] || usage

TARGET="$1"
shift

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../common/participants.sh"

if is_participant_index "$TARGET"; then
  PROFILE="$(participant_id_for_index "$TARGET")"
else
  PROFILE="$TARGET"
fi

validate_participant_id "$PROFILE" || usage

command -v openclaw >/dev/null 2>&1 || {
  echo "ERROR: openclaw is not installed for this account." >&2
  exit 1
}

if [[ $# -eq 0 ]]; then
  set -- --follow --local-time
fi

openclaw --profile "$PROFILE" logs "$@"
