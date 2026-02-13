# Quick Start Guide - Kubernetes on Hetzner Cloud

This guide will help you deploy a complete Kubernetes cluster on Hetzner Cloud in about 20-30 minutes.

## What You'll Get

- 3 Ubuntu 24.04 servers on Hetzner Cloud
- 1 Kubernetes master node + 2 worker nodes
- Kubernetes v1.29 with Calico networking
- Ready to deploy applications

## Prerequisites Checklist

- [ ] Hetzner Cloud account ([sign up here](https://www.hetzner.com/cloud))
- [ ] Hetzner Cloud API token ([create here](https://console.hetzner.cloud/))
- [ ] 1Password account with service account token
- [ ] SSH key pair
- [ ] Terraform installed (v1.0+)
- [ ] Ansible installed (v2.9+)
- [ ] jq installed (for scripts)

## Step-by-Step Instructions

### Step 1: Clone the Repository

```bash
git clone https://bitbucket.org/storelogix/kubernetes-demo.git
cd kubernetes-demo
```

### Step 2: Set Up 1Password

1. Store your SSH public key in 1Password
2. Create a service account token for Terraform
3. Note the vault UUID and item UUID

### Step 3: Configure Terraform

```bash
cd infrastructure/terraform
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:

```hcl
hcloud_token              = "your-hetzner-api-token"
op_service_account_token  = "your-1password-service-token"
op_vault_uuid             = "your-vault-uuid"
op_item_uuid              = "your-ssh-key-item-uuid"
location                  = "nbg1"  # or fsn1, hel1, ash, hil
environment               = "kubernetes-demo"
```

### Step 4: Deploy Infrastructure

```bash
terraform init
terraform plan
terraform apply
```

Type `yes` when prompted. This takes 1-2 minutes.

### Step 5: Provision Kubernetes Cluster

```bash
cd ../ansible
./generate-inventory.sh
ansible-playbook site.yml
```

This takes 10-15 minutes. The playbook will:
1. Install container runtime and Kubernetes on all nodes (~5 min)
2. Initialize the master node (~3 min)
3. Join worker nodes to the cluster (~2 min)

### Step 6: Access Your Cluster

Get the master IP from Terraform output:

```bash
cd ../terraform
terraform output server_ips
```

Copy kubeconfig from master:

```bash
MASTER_IP=$(terraform output -json server_ips | jq -r '.[0]')
ssh root@$MASTER_IP cat /etc/kubernetes/admin.conf > ~/.kube/config-hetzner
export KUBECONFIG=~/.kube/config-hetzner
```

Verify the cluster:

```bash
kubectl get nodes
kubectl get pods -A
```

### Step 7: Deploy Sample Applications

```bash
cd ../../kubernetes/apps

# Deploy PostgreSQL
helm install postgresql ./postgresql

# Deploy InfluxDB
helm install influxdb ./influxdb

# Deploy monitoring
helm install monitoring ../platform/monitoring
```

## Verification Commands

```bash
# Check node status
kubectl get nodes -o wide

# Check system pods
kubectl get pods -A

# Check cluster info
kubectl cluster-info

# Check Calico status
kubectl get pods -n kube-system -l k8s-app=calico-node
```

Expected output:
- 3 nodes in Ready state
- All system pods Running
- Calico pods Running on all nodes

## Troubleshooting

### Terraform Issues

**Problem**: Authentication failed
```bash
# Verify token
echo $HCLOUD_TOKEN
# Or check terraform.tfvars
```

**Problem**: SSH key not found in 1Password
```bash
# Verify 1Password item exists and contains public key in password field
op item get <item-uuid> --vault <vault-uuid>
```

### Ansible Issues

**Problem**: Cannot connect to nodes
```bash
# Test SSH manually
ssh root@<node-ip>

# Check inventory
cat infrastructure/ansible/inventory.ini
```

**Problem**: Playbook fails during node preparation
```bash
# Run with verbose output
ansible-playbook site.yml -vv

# Test individual playbook
ansible-playbook 01-prepare-nodes.yml
```

### Kubernetes Issues

**Problem**: Nodes not Ready
```bash
# SSH to problematic node
ssh root@<node-ip>

# Check kubelet logs
journalctl -xeu kubelet

# Check container runtime
systemctl status containerd
```

**Problem**: Pods not starting
```bash
# Check pod details
kubectl describe pod <pod-name> -n <namespace>

# Check node resources
kubectl top nodes  # requires metrics-server
```

## Common Questions

**Q: Can I use a different OS instead of Ubuntu 24.04?**
A: Yes, but you'll need to adjust the Ansible playbooks. Ubuntu 24.04 is recommended as it's tested and LTS.

**Q: Can I change the number of nodes?**
A: Yes, edit `count` in `infrastructure/terraform/main.tf` and adjust the Ansible inventory accordingly.

**Q: How much does this cost?**
A: Approximately €50/month for 3x cx33 servers + load balancer.

**Q: Can I scale the cluster later?**
A: Yes, increase the node count in Terraform, apply, and run the Ansible worker playbook on new nodes.

**Q: Is this production-ready?**
A: This is a demo setup. For production, consider:
- HA control plane (3 masters)
- Persistent storage solution
- Backup and disaster recovery
- Monitoring and logging
- Security hardening
- Network policies

## Next Steps

After deployment:

1. **Set up kubectl locally** - Copy kubeconfig for remote access
2. **Deploy your applications** - Use the Helm charts or your own
3. **Configure monitoring** - Install Prometheus and Grafana
4. **Set up ingress** - Install nginx-ingress or traefik
5. **Configure storage** - Set up CSI driver for persistent volumes
6. **Implement backups** - Use Velero or similar tools

## Getting Help

- Check the [main README](../../README.md)
- Review [Terraform README](../terraform/README.md)
- Review [Ansible README](../ansible/README.md)
- Open an issue on GitHub

## Cleanup

When you're done, destroy everything:

```bash
cd infrastructure/terraform
terraform destroy
```

Type `yes` to confirm. This removes all resources and stops billing.

---

**Estimated Time**: 20-30 minutes  
**Estimated Cost**: ~€50/month  
**Difficulty**: Intermediate
