# OpenClaw Solo on Azure

Single-user deployment of OpenClaw on Azure using Bicep + Bash.

## Security defaults
- SSH key authentication only (password auth disabled)
- NSG access restricted to your current public IP by default
- OpenClaw secrets stored in Azure Key Vault
- VMSS uses system-assigned managed identity to read Key Vault secrets
- Trusted Launch enabled (Secure Boot + vTPM)

## Quick start
1. Copy `.env.example` to `.env` and update values.
2. Copy `secrets.example.json` to `secrets.json` and fill real values.
3. Run `./scripts/deploy.sh`.
4. SSH with `./scripts/ssh-to-instance.sh`.
5. Edit `config/openclaw.template.json` and apply with `./scripts/update-config.sh`.

## Notes
- This repo is intentionally single-user and contains no team onboarding features.
- Infrastructure defaults are defined in `infra/main.bicepparam`.

## Operational workflow
- Deploy: `./scripts/deploy.sh` (restricts NSG to your detected public IP by default)
- Connect: `./scripts/ssh-to-instance.sh`
- Rotate secrets: edit `secrets.json`, then redeploy with `./scripts/deploy.sh`
- Update runtime config: edit `config/openclaw.template.json`, then run `./scripts/update-config.sh`
- Tear down: `./scripts/teardown.sh`
