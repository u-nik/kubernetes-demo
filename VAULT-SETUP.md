# HashiCorp Vault Integration Guide

This guide explains how to use HashiCorp Vault as the secret manager for ArgoCD git credentials in a Docker Desktop Kubernetes environment.

## 🎯 Overview

Instead of storing credentials in local `values.yaml` files, this setup uses:

- **HashiCorp Vault** running on your host machine (localhost:8200)
- **External Secrets Operator** in Kubernetes to sync secrets from Vault
- **Docker Desktop networking** (`host.docker.internal`) to allow containers to access the host

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────┐
│                     HOST MACHINE                         │
│                                                          │
│  ┌────────────────────────┐                            │
│  │  HashiCorp Vault       │                            │
│  │  localhost:8200        │                            │
│  │  Token: myroot         │                            │
│  └────────────────────────┘                            │
│              ▲                                          │
│              │ host.docker.internal:8200                │
│              │                                          │
│  ┌───────────┴──────────────────────────────────────┐  │
│  │         Docker Desktop Kubernetes                 │  │
│  │                                                    │  │
│  │  ┌──────────────────────────────────────────┐   │  │
│  │  │  External Secrets Operator               │   │  │
│  │  │  - Connects to Vault                     │   │  │
│  │  │  - Syncs secrets every 1h                │   │  │
│  │  └──────────────────────────────────────────┘   │  │
│  │            │                                     │  │
│  │            ▼                                     │  │
│  │  ┌──────────────────────────────────────────┐   │  │
│  │  │  Kubernetes Secret                        │   │  │
│  │  │  git-repository-credentials               │   │  │
│  │  │  (auto-synced from Vault)                │   │  │
│  │  └──────────────────────────────────────────┘   │  │
│  │            │                                     │  │
│  │            ▼                                     │  │
│  │  ┌──────────────────────────────────────────┐   │  │
│  │  │  ArgoCD                                   │   │  │
│  │  │  Uses credentials for Bitbucket           │   │  │
│  │  └──────────────────────────────────────────┘   │  │
│  └────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

## ✅ Prerequisites

1. **Docker Desktop** with Kubernetes enabled
2. **Vault running** on localhost:8200
3. **kubectl** configured for your cluster
4. **External Secrets Operator** deployed
5. **Bitbucket App Password** or Personal Access Token

## 🚀 Quick Start

### Option 1: Automated Setup (Recommended)

#### For Bash/WSL:

```bash
# Full cluster bootstrap (Traefik + ArgoCD + Vault integration)
./init-cluster.sh
```

#### For PowerShell:

```powershell
# Initialize Vault with git credentials
.\init-vault.ps1

# Deploy to Kubernetes
.\deploy-vault-integration.ps1
```

### Option 2: Manual Setup

#### Step 1: Start Vault

```bash
# Using the provided script
docker run -d --name vault \
  --cap-add=IPC_LOCK \
  -e "VAULT_DEV_ROOT_TOKEN_ID=myroot" \
  -p 8200:8200 \
  hashicorp/vault
```

Vault will be available at: http://localhost:8200
Root token: `myroot`

#### Step 2: Create Bitbucket SSH Key

1. Generate an SSH key for ArgoCD (see Step 3 for the script).
2. Add the **public key** to Bitbucket (Workspace settings -> SSH keys).

#### Step 3: Store Credentials in Vault

```bash
export VAULT_ADDR="http://localhost:8200"
export VAULT_TOKEN="myroot"

# Generate a new SSH key and store it in Vault
./scripts/rotate-argocd-git-ssh-key.sh

# Enable KV v2 engine (if not already enabled)
vault secrets enable -version=2 -path=secret kv

# Or store git credentials manually (SSH)
vault kv put secret/git/bitbucket \
  url="git@bitbucket.org:storelogix/kubernetes-demo.git" \
  sshPrivateKey=@/path/to/argocd_git \
  insecureIgnoreHostKey="true"

# Verify
vault kv get secret/git/bitbucket
```

Or use the Vault UI at http://localhost:8200/ui:

1. Login with token: `myroot`
2. Navigate to **secret** (KV v2)
3. Create secret at path: `git/bitbucket`
4. Add keys: `url`, `sshPrivateKey`, `insecureIgnoreHostKey`

#### Step 4: Create Vault Token Secret in Kubernetes

```bash
kubectl create secret generic vault-token \
  -n argocd \
  --from-literal=token=myroot
```

#### Step 5: Deploy Vault SecretStore

```bash
# Deploy the SecretStore configuration
kubectl apply -f kubernetes/apps/vault-secretstore.yaml

# Wait for it to be ready
kubectl get secretstore vault-secretstore -n argocd
kubectl get clustersecretstore vault-cluster-secretstore
```

Expected output:

```
NAME                AGE   STATUS   CAPABILITIES   READY
vault-secretstore   10s   Valid    ReadWrite      True
```

#### Step 6: Deploy ArgoCD Git Credentials

```bash
# Deploy the ExternalSecret
kubectl apply -f kubernetes/apps/argocd-git-credentials.yaml

# Check ExternalSecret status
kubectl get externalsecret -n argocd
kubectl describe externalsecret argocd-git-credentials -n argocd

# Verify the synced secret
kubectl get secret git-repository-credentials -n argocd
```

## 🔍 Verification

### Check Vault Connection

```bash
# From your host
curl http://localhost:8200/v1/sys/health

# From within a Kubernetes pod
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- \
  curl http://host.docker.internal:8200/v1/sys/health
```

### Check SecretStore Status

```bash
# Check if SecretStore is ready
kubectl get secretstore vault-secretstore -n argocd -o yaml

# Check ClusterSecretStore
kubectl get clustersecretstore vault-cluster-secretstore -o yaml

# Look for status.conditions with type "Ready" and status "True"
```

### Check ExternalSecret Status

```bash
# Get ExternalSecret status
kubectl get externalsecret argocd-git-credentials -n argocd

# Detailed status
kubectl describe externalsecret argocd-git-credentials -n argocd

# Check if secret was created
kubectl get secret git-repository-credentials -n argocd

# Verify secret has correct labels for ArgoCD
kubectl get secret git-repository-credentials -n argocd -o yaml | grep argocd
```

### Check ArgoCD

```bash
# Check if ArgoCD sees the repository
kubectl get applications -n argocd

# Check ArgoCD logs for authentication issues
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server --tail=50
```

## 🐛 Troubleshooting

### Vault Not Accessible from Kubernetes

**Symptom**: SecretStore status shows connection errors

**Solution**:

```bash
# Test connectivity from a pod
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- \
  curl http://host.docker.internal:8200/v1/sys/health

# If this fails, host.docker.internal might not be working
# Check Docker Desktop settings or your /etc/hosts
```

### Invalid Vault Token

**Symptom**: SecretStore shows "permission denied" or "invalid token"

**Solution**:

```bash
# Verify the token in Kubernetes
kubectl get secret vault-token -n argocd -o jsonpath='{.data.token}' | base64 -d

# Update with correct token
kubectl delete secret vault-token -n argocd
kubectl create secret generic vault-token -n argocd --from-literal=token=myroot
```

### ExternalSecret Not Syncing

**Symptom**: ExternalSecret exists but secret is not created

**Solution**:

```bash
# Check ExternalSecret events
kubectl describe externalsecret argocd-git-credentials -n argocd

# Check External Secrets Operator logs
kubectl logs -n external-secrets-system -l app.kubernetes.io/name=external-secrets

# Manually trigger sync
kubectl annotate externalsecret argocd-git-credentials -n argocd \
  force-sync=$(date +%s) --overwrite
```

### Secret Path Not Found

**Symptom**: "secret not found" errors

**Solution**:

```bash
# Verify the secret exists in Vault
export VAULT_ADDR="http://localhost:8200"
export VAULT_TOKEN="myroot"
vault kv get secret/git/bitbucket

# Ensure path matches in values.yaml:
# vault.path: "git/bitbucket"
# Vault KV v2 automatically adds "secret/data/" prefix
```

### Docker Desktop Networking Issues

**For Windows**: `host.docker.internal` should work by default

**For Mac**: `host.docker.internal` should work by default

**For Linux** (if using Docker Desktop for Linux):

```bash
# Add host.docker.internal to /etc/hosts
echo "172.17.0.1 host.docker.internal" | sudo tee -a /etc/hosts
```

## 🔒 Security Best Practices

### For Development

- ✅ Use dev mode with root token (already configured)
- ✅ Store token in Kubernetes secret (not in code)
- ✅ Use `host.docker.internal` for local access

### For Production

- ⚠️ **Never use dev mode** - Initialize Vault properly with Shamir sealing
- ⚠️ **Use AppRole or Kubernetes auth** instead of root tokens
- ⚠️ **Use TLS** for Vault connections
- ⚠️ **Run Vault in Kubernetes** instead of on host
- ⚠️ **Enable audit logging**
- ⚠️ **Use policies** to limit access scope

### Upgrading to Production

```bash
# Install Vault in Kubernetes using Helm
helm repo add hashicorp https://helm.releases.hashicorp.com
helm install vault hashicorp/vault \
  --namespace vault \
  --create-namespace \
  --set server.dev.enabled=false \
  --set server.ha.enabled=true

# Use Kubernetes authentication
# Update vault-secretstore values.yaml:
vault:
  server: "http://vault.vault.svc.cluster.local:8200"
  auth:
    kubernetes:
      role: "external-secrets"
      serviceAccountRef:
        name: "external-secrets"
```

## 📚 Additional Resources

- [External Secrets Operator - Vault Provider](https://external-secrets.io/latest/provider/hashicorp-vault/)
- [Vault Documentation](https://www.vaultproject.io/docs)
- [Docker Desktop Networking](https://docs.docker.com/desktop/networking/#i-want-to-connect-from-a-container-to-a-service-on-the-host)
- [ArgoCD Private Repositories](https://argo-cd.readthedocs.io/en/stable/user-guide/private-repositories/)

## 🎯 Quick Reference

### Vault Paths

- **Credentials location**: `secret/git/bitbucket`
- **API path (KV v2)**: `secret/data/git/bitbucket`
- **UI path**: http://localhost:8200/ui/vault/secrets/secret/show/git/bitbucket

### Important Commands

```bash
# View Vault secrets
vault kv get secret/git/bitbucket

# Update credentials (SSH)
vault kv put secret/git/bitbucket \
  url="git@bitbucket.org:storelogix/kubernetes-demo.git" \
  sshPrivateKey=@/path/to/argocd_git \
  insecureIgnoreHostKey="true"

# Force sync in Kubernetes
kubectl annotate externalsecret argocd-git-credentials -n argocd \
  force-sync=$(date +%s) --overwrite

# Check all resources
kubectl get secretstore,clustersecretstore,externalsecret -A
```

## 🆚 Comparison: Vault vs Local Files

| Feature          | Local values.yaml     | Vault                         |
| ---------------- | --------------------- | ----------------------------- |
| Security         | ⚠️ File-based         | ✅ Centralized secret mgmt    |
| Rotation         | ❌ Manual file update | ✅ Update in Vault, auto-sync |
| Audit            | ❌ Git history only   | ✅ Full audit log             |
| Sharing          | ⚠️ File distribution  | ✅ Central access             |
| Production-ready | ❌ Not recommended    | ✅ Yes                        |
| Complexity       | ✅ Simple             | ⚠️ More components            |
| Offline work     | ✅ Yes                | ❌ Requires Vault             |
