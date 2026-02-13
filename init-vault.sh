#!/bin/bash
# Initialize HashiCorp Vault for Kubernetes integration
set -e

echo "🔐 Initializing HashiCorp Vault..."

# Configuration
VAULT_ADDR="http://localhost:8200"
VAULT_TOKEN="myroot"
REPO_URL="https://bitbucket.org/storelogix/kubernetes-demo.git"

# Vault CLI wrapper function
# Uses vault CLI inside Docker container instead of requiring local installation
# All vault commands will be executed via: docker exec vault vault <command>
vault() {
    docker exec -e VAULT_ADDR=http://127.0.0.1:8200 -e VAULT_TOKEN="${VAULT_TOKEN}" vault vault "$@"
}

# Check if Vault is running
if ! curl -s "${VAULT_ADDR}/v1/sys/health" > /dev/null; then
    echo "❌ Vault is not accessible at ${VAULT_ADDR}"
    echo "Starting Vault in dev mode..."
    
    # Stop any existing Vault container
    docker stop vault 2>/dev/null || true
    docker rm vault 2>/dev/null || true
    
    # Start Vault in dev mode
    docker run -d --name vault \
      --cap-add=IPC_LOCK \
      -e "VAULT_DEV_ROOT_TOKEN_ID=${VAULT_TOKEN}" \
      -p 8200:8200 \
      hashicorp/vault
    
    echo "⏳ Waiting for Vault to be ready..."
    sleep 3
fi

echo "✅ Vault is running at ${VAULT_ADDR}"

# Enable KV v2 secrets engine if not already enabled
echo "📦 Ensuring KV v2 secrets engine is enabled..."
if ! vault secrets list | grep -q "^secret/"; then
    vault secrets enable -version=2 -path=secret kv
    echo "✅ KV v2 secrets engine enabled at path 'secret'"
else
    echo "✅ KV v2 secrets engine already enabled"
fi

# Prompt for Bitbucket credentials
echo ""
echo "🔑 Please provide your Bitbucket credentials:"
read -p "Bitbucket Username: " BITBUCKET_USERNAME
read -sp "Bitbucket App Password/Token: " BITBUCKET_TOKEN
echo ""

# Store git credentials in Vault
echo "💾 Storing git credentials in Vault..."
vault kv put secret/git/bitbucket \
  url="${REPO_URL}" \
  username="${BITBUCKET_USERNAME}" \
  password="${BITBUCKET_TOKEN}"

echo "✅ Git credentials stored at: secret/git/bitbucket"

echo ""
echo "✅ Vault initialization complete!"
echo ""
echo "Next steps:"
echo "1. Create Vault token secret in Kubernetes:"
echo "   kubectl create secret generic vault-token -n argocd --from-literal=token=${VAULT_TOKEN}"
echo ""
echo "2. Deploy Vault SecretStore:"
echo "   kubectl apply -f kubernetes/apps/vault-secretstore.yaml"
echo ""
echo "3. Deploy ArgoCD Git Credentials:"
echo "   kubectl apply -f kubernetes/apps/argocd-git-credentials.yaml"
echo ""
echo "Vault UI: ${VAULT_ADDR}/ui"
echo "Token: ${VAULT_TOKEN}"
