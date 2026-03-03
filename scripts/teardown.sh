#!/bin/bash
source "$(dirname "$0")/common.sh"

check_prerequisites

echo "Deleting resource group: $RESOURCE_GROUP"
az group delete --name "$RESOURCE_GROUP" --yes --no-wait

echo "Teardown started"
