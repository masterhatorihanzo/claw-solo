#!/bin/bash
source "$(dirname "$0")/common.sh"

check_prerequisites

VMSS_NAME=$(get_vmss_name)
if [[ -z "$VMSS_NAME" ]]; then
  echo "ERROR: No VMSS found in resource group $RESOURCE_GROUP"
  exit 1
fi

CONFIG_FILE="${1:-$PROJECT_ROOT/config/openclaw.template.json}"
require_file "$CONFIG_FILE" "OpenClaw config template"
validate_json_file "$CONFIG_FILE" "OpenClaw config template"

CONFIG_CONTENT=$(jq -c . "$CONFIG_FILE")
ADMIN_USER="${ADMIN_USERNAME:-openclaw}"

echo "Pushing config to all instances of $VMSS_NAME..."

INSTANCE_IDS=$(az vmss list-instances -g "$RESOURCE_GROUP" -n "$VMSS_NAME" --query "[].instanceId" -o tsv)
if [[ -z "$INSTANCE_IDS" ]]; then
  echo "ERROR: No VMSS instances found in resource group $RESOURCE_GROUP"
  exit 1
fi

for INSTANCE_ID in $INSTANCE_IDS; do
  echo "Updating instance $INSTANCE_ID..."
  az vmss run-command invoke \
    -g "$RESOURCE_GROUP" \
    -n "$VMSS_NAME" \
    --instance-id "$INSTANCE_ID" \
    --command-id RunShellScript \
    --scripts "echo '${CONFIG_CONTENT}' | jq . > /home/${ADMIN_USER}/.openclaw/openclaw.json && sudo -u ${ADMIN_USER} XDG_RUNTIME_DIR=/run/user/\$(id -u ${ADMIN_USER}) systemctl --user restart openclaw-gateway" \
    --output none
  echo "  Instance $INSTANCE_ID updated."
done

echo "Config pushed to all instances."
