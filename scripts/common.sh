#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

if [[ -f "$PROJECT_ROOT/.env" ]]; then
  set -a
  source "$PROJECT_ROOT/.env"
  set +a
fi

RESOURCE_GROUP="${RESOURCE_GROUP:-openclaw-solo-rg}"
LOCATION="${LOCATION:-eastus2}"
SSH_KEY_PATH="${SSH_KEY_PATH:-$HOME/.ssh/id_rsa.pub}"
SECRETS_FILE="${SECRETS_FILE:-$PROJECT_ROOT/secrets.json}"
ADMIN_USERNAME="${ADMIN_USERNAME:-openclaw}"

if [[ -n "${AZURE_SUBSCRIPTION:-}" ]]; then
  az account set --subscription "$AZURE_SUBSCRIPTION"
fi

check_prerequisites() {
  local missing=0
  for cmd in az jq curl; do
    if ! command -v "$cmd" &>/dev/null; then
      echo "ERROR: '$cmd' is required but not installed"
      missing=1
    fi
  done

  if [[ $missing -eq 1 ]]; then
    exit 1
  fi

  if ! az account show &>/dev/null; then
    echo "ERROR: Not logged in to Azure. Run: az login"
    exit 1
  fi
}

get_vmss_name() {
  az vmss list -g "$RESOURCE_GROUP" --query "[0].name" -o tsv 2>/dev/null
}

require_file() {
  local file_path="$1"
  local label="$2"
  if [[ ! -f "$file_path" ]]; then
    echo "ERROR: Missing $label at $file_path"
    exit 1
  fi
}

validate_json_file() {
  local file_path="$1"
  local label="$2"
  if ! jq -e . "$file_path" >/dev/null 2>&1; then
    echo "ERROR: $label must contain valid JSON: $file_path"
    exit 1
  fi
}

get_public_ip() {
  local detected_ip
  detected_ip=$(curl -s --max-time 8 https://api.ipify.org || true)

  if [[ -n "$detected_ip" && "$detected_ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "$detected_ip"
    return 0
  fi

  echo ""
}

get_first_instance_ip() {
  local vmss_name
  vmss_name=$(get_vmss_name)
  if [[ -z "$vmss_name" ]]; then
    echo ""
    return 0
  fi

  az vmss list-instance-public-ips \
    -g "$RESOURCE_GROUP" \
    -n "$vmss_name" \
    --query "[0].ipAddress" \
    -o tsv
}
