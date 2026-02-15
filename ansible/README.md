# Ansible Cluster Bootstrap

This playbook provisions the same stack as `init-cluster.sh` on top of an existing (bare) Kubernetes cluster:

- Traefik
- ArgoCD
- External Secrets Operator
- Vault SecretStore + ArgoCD git credential sync
- ArgoCD repo-auth bootstrap secret to avoid private-repo sync deadlock

## Run

From repository root:

```bash
ansible-playbook -i ansible/inventory.ini ansible/init-cluster.yml
```

You will be prompted for:

- Bitbucket Username
- Bitbucket App Password/Token

## Optional Variables

Override defaults as needed:

```bash
ansible-playbook -i ansible/inventory.ini ansible/init-cluster.yml \
  -e argocd_namespace=argocd \
  -e vault_addr=http://localhost:8200 \
  -e vault_token=myroot \
  -e repo_url=https://bitbucket.org/storelogix/kubernetes-demo.git
```

## Prerequisites

- `kubectl`, `helm`, `docker`, `curl`
- Kubernetes context already configured (`kubectl cluster-info` works)
