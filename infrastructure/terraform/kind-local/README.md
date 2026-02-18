# KIND Local Terraform Configuration

This Terraform configuration creates a local Kubernetes cluster using [KIND](https://kind.sigs.k8s.io/) (Kubernetes IN Docker).

## Cluster Topology

| Node               | Role          |
|--------------------|---------------|
| `<name>-control-plane` | control-plane |
| `<name>-worker`        | worker        |
| `<name>-worker2`       | worker        |

The control-plane node is configured with port mappings for HTTP (80) and HTTPS (443) to support ingress controllers.

## Prerequisites

1. [Docker](https://docs.docker.com/get-docker/) installed and running
2. [KIND](https://kind.sigs.k8s.io/docs/user/quick-start/#installation) installed
3. [Terraform](https://developer.hashicorp.com/terraform/downloads) >= 1.0

## Setup

1. Initialize Terraform:
   ```bash
   terraform init
   ```

2. Create the cluster:
   ```bash
   terraform apply -var="cluster_name=my-cluster"
   ```

   Or set the cluster name via environment variable:
   ```bash
   export TF_VAR_cluster_name="my-cluster"
   terraform apply
   ```

3. Export the kubeconfig:
   ```bash
   terraform output -raw kubeconfig > ~/.kube/kind-config
   export KUBECONFIG=$(terraform output -raw kubeconfig_path)
   ```

## Integration with Ansible

This setup is used by the Ansible playbook at `ansible/init-cluster.yml`. The playbook will:

1. Prompt for a cluster name (or use the `CLUSTER_NAME` environment variable)
2. Run `terraform apply` to create the KIND cluster
3. Export the kubeconfig and proceed with cluster initialization

```bash
# Using environment variable
export CLUSTER_NAME="my-cluster"
ansible-playbook ansible/init-cluster.yml

# Or let the playbook prompt you
ansible-playbook ansible/init-cluster.yml
```

## Cleanup

Destroy the cluster:
```bash
terraform destroy
```

## Variables

| Variable       | Description              | Default            |
|----------------|--------------------------|--------------------|
| `cluster_name` | Name of the KIND cluster | `kubernetes-demo`  |
