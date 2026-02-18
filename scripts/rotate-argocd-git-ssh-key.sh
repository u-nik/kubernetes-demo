#!/usr/bin/env bash
set -euo pipefail

if ! command -v vault >/dev/null 2>&1; then
  echo "Error: vault CLI not found in PATH." >&2
  exit 1
fi
if ! command -v ssh-keygen >/dev/null 2>&1; then
  echo "Error: ssh-keygen not found in PATH." >&2
  exit 1
fi

: "${VAULT_ADDR:?Set VAULT_ADDR, e.g. http://localhost:8200}"
: "${VAULT_TOKEN:?Set VAULT_TOKEN}" 

REPO_URL="${REPO_URL:-git@bitbucket.org:storelogix/kubernetes-demo.git}"
VAULT_PATH="${VAULT_PATH:-secret/git/bitbucket}"
KEY_COMMENT="${KEY_COMMENT:-argocd@kubernetes-demo}"
KNOWN_HOSTS_FILE="${KNOWN_HOSTS_FILE:-}"

workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

key_file="$workdir/argocd_git"
ssh-keygen -t ed25519 -a 64 -N "" -C "$KEY_COMMENT" -f "$key_file" >/dev/null

vault_args=(kv put "$VAULT_PATH" "url=$REPO_URL" "sshPrivateKey=@$key_file" "insecureIgnoreHostKey=true")
if [[ -n "$KNOWN_HOSTS_FILE" ]]; then
  vault_args+=("sshKnownHosts=@$KNOWN_HOSTS_FILE")
fi

vault "${vault_args[@]}"

echo "Public key (add to Bitbucket):"
cat "$key_file.pub"
