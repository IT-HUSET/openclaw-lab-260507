#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
Usage:
  ./scripts/native-multi-gateway/setup-profile.sh <participant-index> <host-ip-or-dns>
  ./scripts/native-multi-gateway/setup-profile.sh <profile> <gateway-port> <host-ip-or-dns>

Example:
  ./scripts/native-multi-gateway/setup-profile.sh 1 172.24.110.136
  ./scripts/native-multi-gateway/setup-profile.sh 01 172.24.110.136
  ./scripts/native-multi-gateway/setup-profile.sh p01 18789 172.24.110.136

Runs OpenClaw onboarding for the named profile, then installs the gateway on
the requested base port. If onboarding already installed the service, the
install command may report that no extra work is needed.

Numeric participant indices use profile pNN and port 18789 + (index - 1) * 20.
EOF
  exit 1
}

[[ $# -eq 2 || $# -eq 3 ]] || usage

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../common/participants.sh"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../common/lib.sh"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/../common/preconfigure.sh"

if [[ $# -eq 2 ]] && is_participant_index "$1"; then
  PROFILE="$(participant_id_for_index "$1")"
  GATEWAY_PORT="$(participant_port_for_index "$1" 18789 20)"
  HOST_NAME="$2"
elif [[ $# -eq 3 ]]; then
  PROFILE="$1"
  GATEWAY_PORT="$2"
  HOST_NAME="$3"
else
  usage
fi

validate_participant_id "$PROFILE" || usage
[[ "$GATEWAY_PORT" =~ ^[0-9]+$ ]] || usage
(( GATEWAY_PORT > 0 && GATEWAY_PORT < 65535 )) || usage

command -v openclaw >/dev/null 2>&1 || {
  echo "ERROR: openclaw is not installed for this account." >&2
  echo "Install it first as the lab account: curl -fsSL https://openclaw.ai/install.sh | bash -s -- --no-onboard" >&2
  exit 1
}

echo "Profile:     $PROFILE"
echo "Gateway URL: http://${HOST_NAME}:${GATEWAY_PORT}/"
echo
apply_lab_secrets_to_native_profile_env "$PROFILE"
profile_env="$(native_profile_env_file "$PROFILE")"
if [[ -f "$profile_env" ]]; then
  load_env_file_for_process "$profile_env"
fi

if [[ "${OPENCLAW_NONINTERACTIVE_ONBOARDING:-}" == "1" ]]; then
  auth_choice="${OPENCLAW_AUTH_CHOICE:-skip}"
  echo "Starting non-interactive OpenClaw onboarding for profile '$PROFILE' with auth choice '$auth_choice'."
  onboard_args=()
  while IFS= read -r -d '' arg; do
    onboard_args+=("$arg")
  done < <(openclaw_onboard_args "$auth_choice" "$GATEWAY_PORT" lan)
  openclaw --profile "$PROFILE" "${onboard_args[@]}"
else
  echo "Starting OpenClaw onboarding for profile '$PROFILE'."
  openclaw --profile "$PROFILE" onboard --skip-ui
fi

if [[ "${OPENCLAW_LAB_UNRESTRICTED:-}" == "1" ]]; then
  echo
  echo "Applying unrestricted lab tool policy for profile '$PROFILE'."
  openclaw --profile "$PROFILE" config set --batch-json "$(permissive_openclaw_config_json)"
fi

echo
echo "Installing gateway service for profile '$PROFILE' on port $GATEWAY_PORT."
openclaw --profile "$PROFILE" gateway install --port "$GATEWAY_PORT"

echo
echo "Gateway URL: http://${HOST_NAME}:${GATEWAY_PORT}/"
echo "Status:      ./scripts/native-multi-gateway/status.sh $PROFILE"
