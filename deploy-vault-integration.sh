#!/bin/bash
# Deploy Vault integration to Kubernetes
set -e

VAULT_TOKEN="${VAULT_TOKEN:-myroot}"
NAMESPACE="argocd"

echo "🚀 Deploying Vault integration to Kubernetes..."

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed"
    exit 1
fi

# Check if namespace exists, create if not
if ! kubectl get namespace ${NAMESPACE} &> /dev/null; then
    echo "📦 Creating namespace: ${NAMESPACE}"
    kubectl create namespace ${NAMESPACE}
fi

# Create or update Vault token secret
echo "🔑 Creating Vault token secret..."
kubectl create secret generic vault-token \
    -n ${NAMESPACE} \
    --from-literal=token="${VAULT_TOKEN}" \
    --dry-run=client -o yaml | kubectl apply -f -

echo "✅ Vault token secret created in namespace: ${NAMESPACE}"

# Deploy Vault SecretStore
echo "📋 Deploying Vault SecretStore..."
kubectl apply -f kubernetes/apps/vault-secretstore.yaml

# Wait for SecretStore to be ready
echo "⏳ Waiting for SecretStore to be ready..."
sleep 5

# Check SecretStore status
echo "🔍 Checking SecretStore status..."
kubectl get secretstore -n ${NAMESPACE}
kubectl get clustersecretstore

# Deploy ArgoCD Git Credentials
echo "🔐 Deploying ArgoCD Git Credentials..."
kubectl apply -f kubernetes/apps/argocd-git-credentials.yaml

# Wait for ExternalSecret to sync
echo "⏳ Waiting for ExternalSecret to sync..."
sleep 5

# Check ExternalSecret status
echo "🔍 Checking ExternalSecret status..."
kubectl get externalsecret -n ${NAMESPACE}

# Verify the secret was created
if kubectl get secret git-repository-credentials -n ${NAMESPACE} &> /dev/null; then
    echo "✅ Git repository credentials secret created successfully!"
    echo ""
    echo "Secret details:"
    kubectl get secret git-repository-credentials -n ${NAMESPACE} -o jsonpath='{.metadata.labels}'
    echo ""
else
    echo "⚠️  Secret not yet created. Check ExternalSecret status:"
    kubectl describe externalsecret argocd-git-credentials -n ${NAMESPACE}
fi

echo ""
echo "✅ Vault integration deployment complete!"
echo ""
echo "To verify everything is working:"
echo "  kubectl get externalsecret -n ${NAMESPACE}"
echo "  kubectl describe externalsecret argocd-git-credentials -n ${NAMESPACE}"
echo "  kubectl get secret git-repository-credentials -n ${NAMESPACE}"
