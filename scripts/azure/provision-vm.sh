#!/usr/bin/env bash
set -euo pipefail

ENV_PATH="${1:-resources/azure.env}"
[[ -f "$ENV_PATH" ]] || {
  echo "ERROR: Missing Azure env file. Copy resources/azure.env.example to $ENV_PATH" >&2
  exit 1
}

# shellcheck disable=SC1090
source "$ENV_PATH"

: "${RG:?Set RG}"
: "${LOCATION:?Set LOCATION}"
: "${VNET_NAME:?Set VNET_NAME}"
: "${VNET_PREFIX:?Set VNET_PREFIX}"
: "${VM_SUBNET_NAME:?Set VM_SUBNET_NAME}"
: "${VM_SUBNET_PREFIX:?Set VM_SUBNET_PREFIX}"
: "${BASTION_SUBNET_PREFIX:?Set BASTION_SUBNET_PREFIX}"
: "${NSG_NAME:?Set NSG_NAME}"
: "${VM_NAME:?Set VM_NAME}"
: "${ADMIN_USERNAME:?Set ADMIN_USERNAME}"
: "${BASTION_NAME:?Set BASTION_NAME}"
: "${BASTION_PIP_NAME:?Set BASTION_PIP_NAME}"
: "${SSH_PUBLIC_KEY_PATH:?Set SSH_PUBLIC_KEY_PATH}"
: "${VM_SIZE:?Set VM_SIZE}"
: "${OS_DISK_SIZE_GB:?Set OS_DISK_SIZE_GB}"

command -v az >/dev/null 2>&1 || {
  echo "ERROR: Azure CLI is required: https://learn.microsoft.com/cli/azure/install-azure-cli" >&2
  exit 1
}

[[ -f "$SSH_PUBLIC_KEY_PATH" ]] || {
  echo "ERROR: SSH public key not found at $SSH_PUBLIC_KEY_PATH" >&2
  exit 1
}

SSH_PUB_KEY="$(cat "$SSH_PUBLIC_KEY_PATH")"

az extension add -n ssh --upgrade
az provider register --namespace Microsoft.Compute
az provider register --namespace Microsoft.Network

for namespace in Microsoft.Compute Microsoft.Network; do
  echo "Waiting for provider registration: $namespace"
  for _ in $(seq 1 60); do
    state="$(az provider show --namespace "$namespace" --query registrationState -o tsv)"
    [[ "$state" == "Registered" ]] && break
    sleep 5
  done
  state="$(az provider show --namespace "$namespace" --query registrationState -o tsv)"
  [[ "$state" == "Registered" ]] || {
    echo "ERROR: Provider did not register in time: $namespace" >&2
    exit 1
  }
done

az group create -n "$RG" -l "$LOCATION"

az network nsg create -g "$RG" -n "$NSG_NAME" -l "$LOCATION"

az network nsg rule create \
  -g "$RG" --nsg-name "$NSG_NAME" \
  -n AllowSshFromBastionSubnet --priority 100 \
  --access Allow --direction Inbound --protocol Tcp \
  --source-address-prefixes "$BASTION_SUBNET_PREFIX" \
  --destination-port-ranges 22

az network nsg rule create \
  -g "$RG" --nsg-name "$NSG_NAME" \
  -n DenyInternetSsh --priority 110 \
  --access Deny --direction Inbound --protocol Tcp \
  --source-address-prefixes Internet \
  --destination-port-ranges 22

az network nsg rule create \
  -g "$RG" --nsg-name "$NSG_NAME" \
  -n DenyVnetSsh --priority 120 \
  --access Deny --direction Inbound --protocol Tcp \
  --source-address-prefixes VirtualNetwork \
  --destination-port-ranges 22

az network vnet create \
  -g "$RG" -n "$VNET_NAME" -l "$LOCATION" \
  --address-prefixes "$VNET_PREFIX" \
  --subnet-name "$VM_SUBNET_NAME" \
  --subnet-prefixes "$VM_SUBNET_PREFIX"

az network vnet subnet update \
  -g "$RG" --vnet-name "$VNET_NAME" \
  -n "$VM_SUBNET_NAME" --nsg "$NSG_NAME"

az network vnet subnet create \
  -g "$RG" --vnet-name "$VNET_NAME" \
  -n AzureBastionSubnet \
  --address-prefixes "$BASTION_SUBNET_PREFIX"

az vm create \
  -g "$RG" -n "$VM_NAME" -l "$LOCATION" \
  --image "Canonical:ubuntu-24_04-lts:server:latest" \
  --size "$VM_SIZE" \
  --os-disk-size-gb "$OS_DISK_SIZE_GB" \
  --storage-sku StandardSSD_LRS \
  --admin-username "$ADMIN_USERNAME" \
  --ssh-key-values "$SSH_PUB_KEY" \
  --vnet-name "$VNET_NAME" \
  --subnet "$VM_SUBNET_NAME" \
  --public-ip-address "" \
  --nsg ""

az network public-ip create \
  -g "$RG" -n "$BASTION_PIP_NAME" -l "$LOCATION" \
  --sku Standard --allocation-method Static

az network bastion create \
  -g "$RG" -n "$BASTION_NAME" -l "$LOCATION" \
  --vnet-name "$VNET_NAME" \
  --public-ip-address "$BASTION_PIP_NAME" \
  --sku Standard --enable-tunneling true

echo "Azure VM created without a public IP."
echo "Connect with: ./scripts/azure/ssh.sh $ENV_PATH"
