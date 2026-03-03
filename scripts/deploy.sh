#!/bin/bash
source "$(dirname "$0")/common.sh"

usage() {
  echo "Usage: $0 [--open]"
  echo "  --open   Allow inbound traffic from any IP (default restricts to your IP)"
}

OPEN_ACCESS=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --open) OPEN_ACCESS=true; shift ;;
    --help|-h) usage; exit 0 ;;
    *) echo "Unknown option: $1"; usage; exit 1 ;;
  esac
done

check_prerequisites

require_file "$SECRETS_FILE" "secrets file"
require_file "$SSH_KEY_PATH" "SSH public key"
validate_json_file "$SECRETS_FILE" "secrets file"

SSH_KEY=$(cat "$SSH_KEY_PATH")
SECRETS=$(cat "$SECRETS_FILE")

if [[ "$OPEN_ACCESS" == true ]]; then
  SSH_CIDR="*"
  GATEWAY_CIDR="*"
else
  MY_IP=$(get_public_ip)
  if [[ -n "$MY_IP" ]]; then
    SSH_CIDR="$MY_IP/32"
    GATEWAY_CIDR="$MY_IP/32"
  else
    echo "WARNING: Could not detect public IP. Falling back to '*'"
    SSH_CIDR="*"
    GATEWAY_CIDR="*"
  fi
fi

echo "Creating resource group: $RESOURCE_GROUP"
az group create --name "$RESOURCE_GROUP" --location "$LOCATION" --output none

echo "Deploying Bicep template..."
az deployment group create \
  --resource-group "$RESOURCE_GROUP" \
  --template-file "$PROJECT_ROOT/infra/main.bicep" \
  --parameters "$PROJECT_ROOT/infra/main.bicepparam" \
  --parameters sshPublicKey="$SSH_KEY" \
  --parameters openclawSecrets="$SECRETS" \
  --parameters sshSourceCidr="$SSH_CIDR" \
  --parameters gatewaySourceCidr="$GATEWAY_CIDR" \
  --output table

INSTANCE_IP=$(get_first_instance_ip)
if [[ -n "$INSTANCE_IP" ]]; then
  echo "Deployment complete. Instance public IP: $INSTANCE_IP"
else
  echo "Deployment complete. Public IP not available yet; retry in ~30 seconds."
fi
echo "SSH with: ./scripts/ssh-to-instance.sh"
