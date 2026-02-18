# Repository Configuration Guide

This guide explains how to configure repository access credentials for ArgoCD to pull from Bitbucket.

## Overview

The repository uses a centralized configuration approach with a `config/values.yaml` file that is **NOT** committed to the repository. Instead, a `config/values.yaml.example` template is provided.

## Quick Setup

### 1. Create Bitbucket App Password

1. Log in to Bitbucket at https://bitbucket.org
2. Click on your profile avatar → **Personal settings**
3. Go to **App passwords** (under Access management)
4. Click **Create app password**
5. Give it a name (e.g., "Kubernetes ArgoCD")
6. Select the following permissions:
   - **Repositories**: Read
7. Click **Create**
8. **Copy the generated password** - you won't be able to see it again!

### 2. Create Local Configuration File

```bash
# Copy the example file
cp config/values.yaml.example config/values.yaml

# Edit with your credentials
nano config/values.yaml  # or use your preferred editor
```

### 3. Fill in Your Credentials

Edit `config/values.yaml`:

```yaml
repository:
   url: git@bitbucket.org:storelogix/kubernetes-demo.git

   auth:
      # Use SSH for repository access
      type: ssh

      # Paste your private key here
      sshPrivateKey: |
         -----BEGIN OPENSSH PRIVATE KEY-----
         ...
         -----END OPENSSH PRIVATE KEY-----

      # Disable host key checking (optional)
      insecureIgnoreHostKey: true

targetRevision: main
```

### 4. Deploy Git Credentials to Kubernetes

```bash
# Make sure you're in the repository root
cd kubernetes-demo

# Apply the ArgoCD application for git credentials
kubectl apply -f kubernetes/apps/argocd-git-credentials.yaml

# Wait for ArgoCD to sync (this may take a minute)
kubectl get application argocd-git-credentials -n argocd

# Verify the secret was created
kubectl get secret git-repository-credentials -n argocd
```

### 5. Verify Configuration

Check if ArgoCD can access the repository:

```bash
# Check ArgoCD application status
kubectl get application -n argocd

# View ArgoCD logs if there are issues
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server
```

## Security Best Practices

1. ✅ **Never commit `config/values.yaml`** - it's already in `.gitignore`
2. ✅ **Use a dedicated SSH key** for ArgoCD
3. ✅ **Grant minimum permissions** (only repository:read)
4. ✅ **Rotate credentials regularly**
5. ✅ **Use different App Passwords** for different environments

## Troubleshooting

### ArgoCD Can't Access Repository

If ArgoCD shows authentication errors:

1. Check the secret exists:
   ```bash
   kubectl get secret git-repository-credentials -n argocd -o yaml
   ```

2. Verify the repo URL is correct:
   ```bash
   kubectl get secret git-repository-credentials -n argocd -o jsonpath='{.data.url}' | base64 -d
   ```

3. Test Bitbucket access manually:
   ```bash
   # Replace with your key path
   GIT_SSH_COMMAND='ssh -i /path/to/argocd_git -o StrictHostKeyChecking=no' \
     git clone git@bitbucket.org:storelogix/kubernetes-demo.git test-clone
   ```

### Secret Not Created

If the secret isn't being created:

1. Check if the ArgoCD application is synced:
   ```bash
   kubectl describe application argocd-git-credentials -n argocd
   ```

2. Check ArgoCD application controller logs:
   ```bash
   kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller
   ```

3. Verify the values are being passed correctly:
   ```bash
   # From the repository root
   helm template kubernetes/manifests/argocd-git-credentials \
     --values config/values.yaml \
     --set enabled=true
   ```

## Alternative: Using External Secrets (Advanced)

For production environments, consider using External Secrets Operator with HashiCorp Vault for centralized secret management.

See [VAULT-SETUP.md](VAULT-SETUP.md) for Vault integration.

## File Structure

```
kubernetes-demo/
├── config/
│   ├── values.yaml           # ❌ NOT in git (your credentials)
│   └── values.yaml.example   # ✅ In git (template)
├── kubernetes/
│   ├── apps/
│   │   └── argocd-git-credentials.yaml   # ArgoCD application
│   └── manifests/
│       └── argocd-git-credentials/       # Helm chart
│           ├── Chart.yaml
│           ├── values.yaml
│           └── templates/
│               ├── _helpers.tpl
│               ├── secret.yaml
│               └── NOTES.txt
└── .gitignore                # Includes config/values.yaml
```

## References

- [Bitbucket App Passwords Documentation](https://support.atlassian.com/bitbucket-cloud/docs/app-passwords/)
- [ArgoCD Private Repositories](https://argo-cd.readthedocs.io/en/stable/user-guide/private-repositories/)
- [Kubernetes Secrets](https://kubernetes.io/docs/concepts/configuration/secret/)
