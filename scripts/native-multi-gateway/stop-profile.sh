#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
Usage:
  ./scripts/native-multi-gateway/stop-profile.sh <profile>

Example:
  ./scripts/native-multi-gateway/stop-profile.sh 1
  ./scripts/native-multi-gateway/stop-profile.sh p01
EOF
  exit 1
}

[[ $# -eq 1 ]] || usage

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../common/participants.sh"

if is_participant_index "$1"; then
  PROFILE="$(participant_id_for_index "$1")"
else
  PROFILE="$1"
fi

validate_participant_id "$PROFILE" || usage

command -v openclaw >/dev/null 2>&1 || {
  echo "ERROR: openclaw is not installed for this account." >&2
  exit 1
}

openclaw --profile "$PROFILE" gateway stop
