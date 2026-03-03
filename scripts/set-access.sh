#!/bin/bash
source "$(dirname "$0")/common.sh"

usage() {
  echo "Usage: $0 [--ssh on|off] [--gateway on|off] [--ssh-cidr auto|CIDR|*] [--gateway-cidr auto|CIDR|*]"
  echo ""
  echo "Examples:"
  echo "  $0 --ssh on --ssh-cidr auto"
  echo "  $0 --gateway on --gateway-cidr 203.0.113.10/32"
  echo "  $0 --ssh off --gateway off"
}

SSH_STATE=""
GATEWAY_STATE=""
SSH_CIDR="auto"
GATEWAY_CIDR="auto"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --ssh)
      SSH_STATE="${2:-}"
      shift 2
      ;;
    --gateway)
      GATEWAY_STATE="${2:-}"
      shift 2
      ;;
    --ssh-cidr)
      SSH_CIDR="${2:-}"
      shift 2
      ;;
    --gateway-cidr)
      GATEWAY_CIDR="${2:-}"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      usage
      exit 1
      ;;
  esac
done

if [[ -z "$SSH_STATE" && -z "$GATEWAY_STATE" ]]; then
  echo "ERROR: Set at least one of --ssh or --gateway"
  usage
  exit 1
fi

check_prerequisites

NSG_NAME=$(az network nsg list -g "$RESOURCE_GROUP" --query "[0].name" -o tsv)
if [[ -z "$NSG_NAME" ]]; then
  echo "ERROR: Could not find NSG in resource group '$RESOURCE_GROUP'"
  exit 1
fi

resolve_cidr() {
  local value="$1"

  if [[ "$value" == "*" ]]; then
    echo "*"
    return 0
  fi

  if [[ "$value" == "auto" ]]; then
    local my_ip
    my_ip=$(get_public_ip)
    if [[ -z "$my_ip" ]]; then
      echo "ERROR: Could not detect public IP automatically" >&2
      echo "Set explicit CIDR with --ssh-cidr or --gateway-cidr (for example 203.0.113.10/32)" >&2
      return 1
    fi
    echo "$my_ip/32"
    return 0
  fi

  echo "$value"
}

set_rule() {
  local rule_name="$1"
  local state="$2"
  local cidr_input="$3"

  if [[ "$state" == "on" ]]; then
    local cidr
    cidr=$(resolve_cidr "$cidr_input") || return 1
    az network nsg rule update \
      -g "$RESOURCE_GROUP" \
      --nsg-name "$NSG_NAME" \
      -n "$rule_name" \
      --access Allow \
      --source-address-prefixes "$cidr" \
      --output none
    echo "$rule_name: ON (Allow from $cidr)"
  elif [[ "$state" == "off" ]]; then
    az network nsg rule update \
      -g "$RESOURCE_GROUP" \
      --nsg-name "$NSG_NAME" \
      -n "$rule_name" \
      --access Deny \
      --source-address-prefixes '*' \
      --output none
    echo "$rule_name: OFF (Deny all)"
  elif [[ -n "$state" ]]; then
    echo "ERROR: Invalid state '$state' for $rule_name (use on|off)"
    return 1
  fi
}

set_rule "AllowSSH" "$SSH_STATE" "$SSH_CIDR"
set_rule "AllowOpenClawGateway" "$GATEWAY_STATE" "$GATEWAY_CIDR"

echo ""
echo "Current NSG rule summary:"
az network nsg rule list \
  -g "$RESOURCE_GROUP" \
  --nsg-name "$NSG_NAME" \
  --query "[?name=='AllowSSH' || name=='AllowOpenClawGateway'].{name:name,access:access,source:sourceAddressPrefix,destinationPort:destinationPortRange,priority:priority}" \
  -o table
