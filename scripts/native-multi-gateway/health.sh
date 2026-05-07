#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
Usage:
  ./scripts/native-multi-gateway/health.sh <participant-index> [openclaw-health-args...]
  ./scripts/native-multi-gateway/health.sh <profile> [openclaw-health-args...]

Examples:
  ./scripts/native-multi-gateway/health.sh 1
  ./scripts/native-multi-gateway/health.sh p01 --verbose
  ./scripts/native-multi-gateway/health.sh 1 --json
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

openclaw --profile "$PROFILE" health "$@"
