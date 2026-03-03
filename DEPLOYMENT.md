# Deployment Guide

This guide documents the current single-user deployment flow for this repo.

## 1) Prerequisites

- Azure CLI installed and logged in (`az login`)
- Bicep installed via Azure CLI (`az bicep install`)
- `jq` available in shell
- Subscription selected (`az account set --subscription <id>`)

## 2) Local setup

1. Create project SSH keypair (dedicated for VM access):
   - `bash scripts/generate-openclaw-key.sh`
2. Confirm `.env` points to that public key:
   - `SSH_KEY_PATH=$HOME/.ssh/id_rsa_openclaw.pub`
3. Fill `secrets.json` with Azure OpenAI values:
   - `AZURE_OPENAI_API_KEY`
   - `AZURE_OPENAI_BASE_URL` (for example `https://<resource>.openai.azure.com/openai/v1`)

## 3) Precheck

Run:

- `bash scripts/precheck.sh`

This validates:
- `.env` and required variables
- SSH key exists
- `secrets.json` is valid JSON
- Azure auth context
- Bicep compile

## 4) Deploy

Run:

- `./scripts/deploy.sh`

The deployment creates:
- Resource group
- VNet + NSG
- Key Vault + `openclaw-secrets`
- User-assigned managed identity
- VMSS (1 instance by default, `Standard_B2s`)

## 5) Post-deploy checks

1. Wait 3-5 minutes for cloud-init bootstrap.
2. SSH into VM:
   - `./scripts/ssh-to-instance.sh`
3. Verify setup inside VM:
   - `tail -f /var/log/openclaw-setup.log`
   - `systemctl --user status openclaw-gateway`

## 6) Updating secrets later

You can update Key Vault secrets after deployment.

- Edit `secrets.json`
- Redeploy (`./scripts/deploy.sh`) to republish secret, or update Key Vault directly with Azure CLI.

## 7) Updating runtime config

- Edit `config/openclaw.template.json`
- Push to running VM:
  - `./scripts/update-config.sh`

## 8) Teardown

- `./scripts/teardown.sh`

Deletes the resource group and all resources.

## Current baseline

- VM size: `Standard_B2s`
- Instance count: `1`
- Region: `eastus2` (from `.env`)
- Security: SSH-only auth, NSG source restriction, Key Vault + managed identity, Trusted Launch
