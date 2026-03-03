#!/bin/bash
source "$(dirname "$0")/common.sh"

check_prerequisites

IP=$(get_first_instance_ip)
if [[ -z "$IP" ]]; then
  echo "ERROR: No VMSS instance public IP found in $RESOURCE_GROUP"
  exit 1
fi

echo "Connecting to $ADMIN_USERNAME@$IP"
ssh -o StrictHostKeyChecking=accept-new "$ADMIN_USERNAME@$IP"
