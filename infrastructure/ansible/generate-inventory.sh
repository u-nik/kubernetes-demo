#!/bin/bash
# Script to generate Ansible inventory from Terraform outputs

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TERRAFORM_DIR="$SCRIPT_DIR/../terraform"
INVENTORY_FILE="$SCRIPT_DIR/inventory.ini"

# Check if terraform directory exists
if [ ! -d "$TERRAFORM_DIR" ]; then
    echo "Error: Terraform directory not found at $TERRAFORM_DIR"
    exit 1
fi

# Check if terraform state exists
if [ ! -f "$TERRAFORM_DIR/terraform.tfstate" ]; then
    echo "Error: Terraform state not found. Please run 'terraform apply' first."
    exit 1
fi

# Get IPs from Terraform output
cd "$TERRAFORM_DIR"
echo "Fetching server IPs from Terraform..."

# Get server IPs as JSON array
SERVER_IPS=$(terraform output -json server_ips | jq -r '.[]')

# Convert to array
IPS_ARRAY=($SERVER_IPS)

# Check if we have exactly 3 IPs
if [ ${#IPS_ARRAY[@]} -ne 3 ]; then
    echo "Error: Expected 3 server IPs, got ${#IPS_ARRAY[@]}"
    exit 1
fi

MASTER_IP=${IPS_ARRAY[0]}
WORKER1_IP=${IPS_ARRAY[1]}
WORKER2_IP=${IPS_ARRAY[2]}

echo "Master IP: $MASTER_IP"
echo "Worker 1 IP: $WORKER1_IP"
echo "Worker 2 IP: $WORKER2_IP"

# Generate inventory file
cat > "$INVENTORY_FILE" <<EOF
[k8s_masters]
node-1 ansible_host=$MASTER_IP

[k8s_workers]
node-2 ansible_host=$WORKER1_IP
node-3 ansible_host=$WORKER2_IP

[k8s_cluster:children]
k8s_masters
k8s_workers

[k8s_cluster:vars]
ansible_user=root
ansible_python_interpreter=/usr/bin/python3
EOF

echo ""
echo "✅ Inventory file generated successfully at: $INVENTORY_FILE"
echo ""
echo "You can now run the Ansible playbooks with:"
echo "  cd $SCRIPT_DIR"
echo "  ansible-playbook site.yml"
