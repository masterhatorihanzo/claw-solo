#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

if [[ ! -f .env ]]; then
  echo "MISSING: .env"
  exit 1
fi

set -a
source .env
set +a

echo "== env =="
echo "RESOURCE_GROUP=${RESOURCE_GROUP:-}"
echo "LOCATION=${LOCATION:-}"
echo "SSH_KEY_PATH=${SSH_KEY_PATH:-}"
echo "SECRETS_FILE=${SECRETS_FILE:-}"

echo "== ssh key =="
if [[ -z "${SSH_KEY_PATH:-}" || ! -f "$SSH_KEY_PATH" ]]; then
  echo "MISSING ssh key: ${SSH_KEY_PATH:-<empty>}"
  exit 1
fi
echo "OK ssh key found"

echo "== secrets file =="
if [[ -z "${SECRETS_FILE:-}" || ! -f "$SECRETS_FILE" ]]; then
  echo "MISSING secrets file: ${SECRETS_FILE:-<empty>}"
  exit 1
fi
jq -e . "$SECRETS_FILE" >/dev/null
echo "OK secrets is valid JSON"

echo "== azure auth =="
az account show --query "{name:name,id:id,tenantId:tenantId,user:user.name}" -o json

echo "== bicep =="
az bicep version
az bicep build --file infra/main.bicep --outfile infra/main.json >/dev/null
echo "OK bicep build"

echo "== precheck complete =="
