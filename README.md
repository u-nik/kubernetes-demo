# Kubernetes Demo on Hetzner Cloud

This repository demonstrates a complete Kubernetes cluster setup on Hetzner Cloud, provisioned with Terraform and Ansible.

## Overview

The setup consists of:
- **Infrastructure**: 3 Ubuntu 24.04 servers on Hetzner Cloud (managed with Terraform)
- **Kubernetes Cluster**: 1 master node + 2 worker nodes (provisioned with Ansible)
- **Applications**: Sample Helm charts for PostgreSQL, InfluxDB, and monitoring

## Architecture

```
┌─────────────────────────────────────────────┐
│           Hetzner Cloud                     │
│                                             │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐ │
│  │ node-1   │  │ node-2   │  │ node-3   │ │
│  │ (Master) │  │ (Worker) │  │ (Worker) │ │
│  │  cx33    │  │  cx33    │  │  cx33    │ │
│  └──────────┘  └──────────┘  └──────────┘ │
│       │              │              │      │
│       └──────────────┴──────────────┘      │
│              Load Balancer (lb11)          │
└─────────────────────────────────────────────┘
```

## Quick Start

### 1. Prerequisites

- [Terraform](https://www.terraform.io/downloads) (>= 1.0)
- [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html) (>= 2.9)
- [Hetzner Cloud Account](https://www.hetzner.com/cloud)
- SSH key pair
- jq (for inventory generation)

### 2. Provision Infrastructure

```bash
cd infrastructure/terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your Hetzner API token and 1Password credentials
terraform init
terraform apply
```

This creates:
- 3 Ubuntu 24.04 servers (cx33: 4 vCPU, 16 GB RAM each)
- 1 load balancer
- SSH key configuration

### 3. Provision Kubernetes Cluster

```bash
cd ../ansible
./generate-inventory.sh
ansible-playbook site.yml
```

This installs and configures:
- Container runtime (containerd)
- Kubernetes v1.29 (kubeadm, kubelet, kubectl)
- Calico CNI network plugin
- Complete cluster initialization

The process takes approximately 10-15 minutes.

### 4. Access Your Cluster

Copy the kubeconfig from the master node:

```bash
ssh root@<MASTER_IP> cat /etc/kubernetes/admin.conf > ~/.kube/config-hetzner
export KUBECONFIG=~/.kube/config-hetzner
kubectl get nodes
```

### 5. Deploy Applications

The repository includes sample Helm charts in the `kubernetes/` directory:

```bash
# Deploy PostgreSQL
helm install postgresql ./kubernetes/apps/postgresql

# Deploy InfluxDB
helm install influxdb ./kubernetes/apps/influxdb

# Deploy monitoring stack
helm install monitoring ./kubernetes/platform/monitoring
```

### 6. Configure Secret Management with Vault

This repository uses **HashiCorp Vault** for secure secret management:

```bash
# Initialize Vault with credentials
./init-vault.sh

# Deploy Vault integration
./deploy-vault-integration.sh

# Apply the configurations
kubectl apply -f kubernetes/apps/vault-secretstore.yaml
kubectl apply -f kubernetes/apps/argocd-git-credentials.yaml
```

See [VAULT-SETUP.md](VAULT-SETUP.md) for detailed instructions.

#### Alternative: Local Configuration Files

For quick local development only (not recommended for production):

1. Copy `config/values.yaml.example` to `config/values.yaml`
2. Fill in your credentials
3. Update `source: direct` in argocd-git-credentials values.yaml
4. Deploy: `kubectl apply -f kubernetes/apps/argocd-git-credentials.yaml`

See [REPOSITORY-SETUP.md](REPOSITORY-SETUP.md) for details.

## Directory Structure

```
.
├── infrastructure/
│   ├── terraform/          # Infrastructure as Code (Hetzner Cloud)
│   │   ├── main.tf         # Main Terraform configuration
│   │   ├── variables.tf    # Variable definitions
│   │   └── outputs.tf      # Output values (server IPs, etc.)
│   └── ansible/            # Kubernetes cluster provisioning
│       ├── site.yml        # Main playbook
│       ├── 01-prepare-nodes.yml
│       ├── 02-init-master.yml
│       ├── 03-join-workers.yml
│       └── generate-inventory.sh
└── kubernetes/
    ├── apps/               # Application Helm charts
    │   ├── postgresql/
    │   └── influxdb/
    └── platform/           # Platform services
        └── monitoring/     # Monitoring stack (Prometheus, Grafana)
```

## Components

### Infrastructure (Terraform)

- **Provider**: Hetzner Cloud
- **Servers**: 3x cx33 (4 vCPU, 16 GB RAM)
- **OS**: Ubuntu 24.04 LTS
- **Location**: Nuremberg, Germany (configurable)
- **Load Balancer**: lb11

See [infrastructure/terraform/README.md](infrastructure/terraform/README.md) for details.

### Kubernetes Cluster (Ansible)

- **Version**: Kubernetes 1.29
- **Control Plane**: 1 master node
- **Workers**: 2 worker nodes
- **Container Runtime**: containerd
- **CNI**: Calico
- **Pod Network CIDR**: 10.244.0.0/16

See [infrastructure/ansible/README.md](infrastructure/ansible/README.md) for details.

## Cost Estimation

Current configuration (approximate monthly costs):
- 3x cx33 servers: ~3 × €15 = €45/month
- 1x lb11 load balancer: ~€5/month
- **Total**: ~€50/month

*Prices as of 2024. Check [Hetzner pricing](https://www.hetzner.com/cloud#pricing) for current rates.*

## Customization

### Change Server Size

Edit `infrastructure/terraform/main.tf`:

```hcl
server_type = "cpx21"  # Instead of cx33
```

Available types: cx22, cx33, cx42, cpx21, cpx31, cpx41, cpx51

### Change Kubernetes Version

Edit `infrastructure/ansible/01-prepare-nodes.yml`:

```yaml
repo: "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /"
```

### Change CNI Plugin

Edit `infrastructure/ansible/02-init-master.yml` to install a different CNI (Flannel, Weave, etc.)

## Troubleshooting

### Terraform Issues

```bash
cd infrastructure/terraform
terraform validate
terraform plan
```

### Ansible Issues

```bash
cd infrastructure/ansible
ansible-playbook site.yml --check  # Dry run
ansible -m ping all                # Test connectivity
```

### Kubernetes Issues

```bash
# On master node
kubectl get nodes
kubectl get pods -A
journalctl -xeu kubelet
```

## Cleanup

To destroy all resources:

```bash
cd infrastructure/terraform
terraform destroy
```

## Contributing

Feel free to open issues or submit pull requests for improvements.

## License

This project is provided as-is for demonstration purposes.

## Resources

- [Hetzner Cloud Documentation](https://docs.hetzner.com/cloud/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Terraform Hetzner Provider](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs)
- [Ansible Documentation](https://docs.ansible.com/)
