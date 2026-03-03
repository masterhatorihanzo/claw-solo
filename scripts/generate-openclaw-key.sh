#!/usr/bin/env bash
set -euo pipefail

mkdir -p ~/.ssh

if [[ ! -f ~/.ssh/id_rsa_openclaw ]]; then
  ssh-keygen -q -t rsa -b 4096 -f ~/.ssh/id_rsa_openclaw -N '' -C openclaw-vm-access
fi

ls -l ~/.ssh/id_rsa_openclaw*
echo "PUBLIC_KEY_CONTENT:"
cat ~/.ssh/id_rsa_openclaw.pub
