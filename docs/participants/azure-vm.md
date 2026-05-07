# Azure VM Lab

This path creates an Azure Linux VM for OpenClaw lab work. The VM has no public IP, and SSH is routed through Azure Bastion.

## Why This Shape

OpenClaw can execute tools and interact with external services. For a shared lab or enterprise pilot, avoid exposing the gateway directly to the internet. Use:

- No public IP on the VM.
- NSG rules that only allow SSH from the Bastion subnet.
- Gateway port bound to `127.0.0.1` on the VM.
- SSH or Bastion tunneling for browser access.

## Provision

From your local machine:

```bash
cp resources/azure.env.example resources/azure.env
$EDITOR resources/azure.env
./scripts/azure/provision-vm.sh resources/azure.env
```

Provisioning Azure Bastion can take 5-30 minutes depending on region.

## SSH

```bash
./scripts/azure/ssh.sh resources/azure.env
```

## Install Docker In The VM

Inside the VM:

```bash
git clone <this-repository-url>
cd openclaw-getting-started
./scripts/azure/install-docker-on-vm.sh
```

Log out and back in so Docker group membership applies.

## Run OpenClaw In Docker

Inside the VM:

```bash
cp .env.example .env
./scripts/local-docker/setup.sh
```

Keep `OPENCLAW_PUBLISH_HOST=127.0.0.1`. Do not publish `18789` to the public internet.

## Access The Dashboard

Use a tunnel from your local machine. With a normal SSH path this would be:

```bash
ssh -L 18789:127.0.0.1:18789 openclaw@<vm-host>
```

With Azure Bastion, use `az network bastion tunnel` if your Azure CLI and tenant policy support it, or use the Azure Portal SSH session for administration and keep the UI local to the VM during the lab.

## Cost Control

Stop compute billing when the lab is not running:

```bash
az vm deallocate -g "$RG" -n "$VM_NAME"
```

Delete all resources created by the example:

```bash
az group delete -n "$RG" --yes --no-wait
```
