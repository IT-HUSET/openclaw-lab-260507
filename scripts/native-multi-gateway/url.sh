#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
Usage:
  ./scripts/native-multi-gateway/url.sh <participant-index> <host-ip-or-dns>
  ./scripts/native-multi-gateway/url.sh <profile> <gateway-port> <host-ip-or-dns>

Examples:
  ./scripts/native-multi-gateway/url.sh 1 172.24.110.136
  ./scripts/native-multi-gateway/url.sh p01 18789 172.24.110.136
EOF
  exit 1
}

[[ $# -eq 2 || $# -eq 3 ]] || usage

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../common/participants.sh"

if [[ $# -eq 2 ]] && is_participant_index "$1"; then
  GATEWAY_PORT="$(participant_port_for_index "$1" 18789 20)"
  HOST_NAME="$2"
elif [[ $# -eq 3 ]]; then
  GATEWAY_PORT="$2"
  HOST_NAME="$3"
else
  usage
fi

[[ "$GATEWAY_PORT" =~ ^[0-9]+$ ]] || usage
(( GATEWAY_PORT > 0 && GATEWAY_PORT < 65535 )) || usage

echo "http://${HOST_NAME}:${GATEWAY_PORT}/"
