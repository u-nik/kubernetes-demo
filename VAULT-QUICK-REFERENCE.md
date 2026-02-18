# Vault + Kubernetes Quick Reference

Quick commands and workflows for working with Vault and Kubernetes secrets.

## 🚀 Initial Setup (One Time)

### 1. Run full cluster bootstrap

```powershell
# PowerShell
.\init-vault.ps1

# Bash/WSL
./init-cluster.sh
```

## 📋 Daily Commands

### Vault Access

```bash
# Set environment variables
export VAULT_ADDR="http://localhost:8200"
export VAULT_TOKEN="myroot"

# Or use Vault UI
# URL: http://localhost:8200/ui
# Token: myroot
```

### View Secrets in Vault

```bash
# List all secrets
vault kv list secret/

# Get specific secret
vault kv get secret/git/bitbucket

# Get as JSON
vault kv get -format=json secret/git/bitbucket
```

### Update Credentials

```bash
# Update git credentials (SSH)
vault kv put secret/git/bitbucket \
  url="git@bitbucket.org:storelogix/kubernetes-demo.git" \
  sshPrivateKey=@/path/to/argocd_git \
  insecureIgnoreHostKey="true"

# Add new secret
vault kv put secret/myapp/database \
  host="db.example.com" \
  username="dbuser" \
  password="dbpass"
```

### Check Kubernetes Sync Status

```bash
# Check SecretStore status
kubectl get secretstore -n argocd
kubectl get clustersecretstore

# Check ExternalSecret status
kubectl get externalsecret -n argocd

# Detailed status
kubectl describe externalsecret argocd-git-credentials -n argocd

# Check synced secret
kubectl get secret git-repository-credentials -n argocd
```

### Force Secret Sync

```bash
# If secret doesn't update automatically
kubectl annotate externalsecret argocd-git-credentials -n argocd \
  force-sync=$(date +%s) --overwrite
```

## 🔧 Troubleshooting

### Check Vault Connectivity

```bash
# From host
curl http://localhost:8200/v1/sys/health

# From Kubernetes pod
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- \
  curl http://host.docker.internal:8200/v1/sys/health
```

### Check External Secrets Operator Logs

```bash
# View ESO logs
kubectl logs -n external-secrets-system \
  -l app.kubernetes.io/name=external-secrets \
  --tail=50 -f

# Check for errors
kubectl logs -n external-secrets-system \
  -l app.kubernetes.io/name=external-secrets \
  --tail=100 | grep -i error
```

### Check SecretStore Issues

```bash
# Get detailed status
kubectl describe secretstore vault-secretstore -n argocd

# Check events
kubectl get events -n argocd --sort-by='.lastTimestamp' | grep -i secret
```

### Fix Common Issues

#### Secret Not Syncing

```bash
# 1. Check if Vault token secret exists
kubectl get secret vault-token -n argocd

# 2. Verify token is correct
kubectl get secret vault-token -n argocd -o jsonpath='{.data.token}' | base64 -d

# 3. Recreate if needed
kubectl delete secret vault-token -n argocd
kubectl create secret generic vault-token -n argocd --from-literal=token=myroot

# 4. Restart ESO
kubectl rollout restart deployment -n external-secrets-system
```

#### Vault Not Accessible

```bash
# Check if Vault is running
docker ps | grep vault

# Restart Vault
docker restart vault

# Or start fresh
docker stop vault && docker rm vault
./init-vault.ps1
```

## 📝 Common Workflows

### Rotate Bitbucket SSH Key

```bash
# 1. Generate a new SSH key (or use the script)
# ./scripts/rotate-argocd-git-ssh-key.sh

# 2. Update in Vault (if not using the script)
vault kv put secret/git/bitbucket \
  url="git@bitbucket.org:storelogix/kubernetes-demo.git" \
  sshPrivateKey=@/path/to/argocd_git \
  insecureIgnoreHostKey="true"

# 3. Wait for auto-sync (refresh interval: 1h) or force sync
kubectl annotate externalsecret argocd-git-credentials -n argocd \
  force-sync=$(date +%s) --overwrite

# 4. Verify the secret updated
kubectl get secret git-repository-credentials -n argocd -o yaml
```

### Add New Secret for Another App

```bash
# 1. Store in Vault
vault kv put secret/myapp/config \
  api_key="abc123" \
  api_secret="xyz789"

# 2. Create ExternalSecret manifest
cat <<EOF | kubectl apply -f -
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: myapp-config
  namespace: default
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: vault-cluster-secretstore
    kind: ClusterSecretStore
  target:
    name: myapp-config-secret
    creationPolicy: Owner
  data:
    - secretKey: api_key
      remoteRef:
        key: myapp/config
        property: api_key
    - secretKey: api_secret
      remoteRef:
        key: myapp/config
        property: api_secret
EOF

# 3. Verify
kubectl get externalsecret myapp-config
kubectl get secret myapp-config-secret
```

### Backup Vault Data

```bash
# Export all secrets (do this regularly!)
vault kv list -format=json secret/ | \
  jq -r '.[]' | \
  while read path; do
    echo "Backing up: $path"
    vault kv get -format=json "secret/$path" > "backup-${path//\//-}.json"
  done
```

### Restore from Backup

```bash
# Restore a specific secret
vault kv put secret/git/bitbucket \
  @backup-git-bitbucket.json
```

## 🔐 Security Reminders

### ✅ DO

- Use Vault for all sensitive data
- Rotate credentials regularly
- Use least-privilege access
- Enable Vault audit logging (production)
- Backup Vault data regularly
- Use TLS for Vault in production

### ❌ DON'T

- Commit `config/values.yaml`
- Share Vault tokens in plain text
- Use dev mode in production
- Store secrets in code or git
- Use root token in production
- Disable Vault sealing in production

## 🎯 Quick Health Check

Run this to verify everything is working:

```bash
# 1. Vault is accessible
curl -s http://localhost:8200/v1/sys/health | jq .

# 2. SecretStores are ready
kubectl get secretstore,clustersecretstore -A

# 3. ExternalSecrets are syncing
kubectl get externalsecret -A

# 4. Secrets are created
kubectl get secret git-repository-credentials -n argocd

# 5. ArgoCD applications are healthy
kubectl get applications -n argocd
```

## 📚 More Information

- [VAULT-SETUP.md](VAULT-SETUP.md) - Complete Vault setup guide
- [SECRET-MANAGEMENT-OPTIONS.md](SECRET-MANAGEMENT-OPTIONS.md) - Compare all options
- [Vault Documentation](https://www.vaultproject.io/docs)
- [External Secrets Docs](https://external-secrets.io/latest/)

## 🆘 Get Help

If something isn't working:

1. Check [VAULT-SETUP.md](VAULT-SETUP.md) troubleshooting section
2. Run the health check above
3. Check logs: `kubectl logs -n external-secrets-system -l app.kubernetes.io/name=external-secrets`
4. Verify connectivity: Test if pods can reach `host.docker.internal:8200`
