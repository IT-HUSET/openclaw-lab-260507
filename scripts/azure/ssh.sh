#!/usr/bin/env bash
set -euo pipefail

ENV_PATH="${1:-resources/azure.env}"
[[ -f "$ENV_PATH" ]] || {
  echo "ERROR: Missing Azure env file: $ENV_PATH" >&2
  exit 1
}

# shellcheck disable=SC1090
source "$ENV_PATH"

: "${RG:?Set RG}"
: "${VM_NAME:?Set VM_NAME}"
: "${BASTION_NAME:?Set BASTION_NAME}"
: "${ADMIN_USERNAME:?Set ADMIN_USERNAME}"
: "${SSH_PRIVATE_KEY_PATH:?Set SSH_PRIVATE_KEY_PATH}"

VM_ID="$(az vm show -g "$RG" -n "$VM_NAME" --query id -o tsv)"

az network bastion ssh \
  --name "$BASTION_NAME" \
  --resource-group "$RG" \
  --target-resource-id "$VM_ID" \
  --auth-type ssh-key \
  --username "$ADMIN_USERNAME" \
  --ssh-key "$SSH_PRIVATE_KEY_PATH"
