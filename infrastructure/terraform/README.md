# Hetzner Cloud Terraform Configuration

This Terraform configuration creates 3 Ubuntu 24.04 Linux VMs on Hetzner Cloud.

## Prerequisites

1. A Hetzner Cloud account
2. A Hetzner Cloud API token (create one at: https://console.hetzner.cloud/)
3. Terraform installed (version 1.0 or higher)

## Server Configuration

The configuration creates the following servers:

- **Server Names**: node-1, node-2, node-3
- **Server Type**: cx33 (4 vCPU, 16 GB RAM)
- **Image**: Ubuntu 24.04
- **Default Location**: nbg1 (Nuremberg, Germany)

## Setup

1. Copy the example variables file:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. Edit `terraform.tfvars` and add your Hetzner Cloud API token:
   ```hcl
   hcloud_token = "your-actual-token-here"
   ```

3. Initialize Terraform:
   ```bash
   terraform init
   ```

## Usage

### Plan the infrastructure

Preview the changes that Terraform will make:

```bash
terraform plan
```

### Apply the configuration

Create the infrastructure:

```bash
terraform apply
```

Review the planned changes and type `yes` to confirm.

### View outputs

After applying, you can view the server details:

```bash
terraform output
```

This will show:
- Server IDs
- Server names
- Public IPv4 addresses
- IPv6 addresses

### Destroy the infrastructure

When you're done, you can destroy all resources:

```bash
terraform destroy
```

## Configuration Options

You can customize the deployment by modifying `terraform.tfvars`:

- `hcloud_token`: Your Hetzner Cloud API token (required)
- `location`: Server location (default: nbg1)
  - Available: nbg1, fsn1, hel1, ash, hil
- `environment`: Environment label for the servers (default: kubernetes-demo)

## Resources

- [Hetzner Cloud Terraform Tutorial](https://community.hetzner.com/tutorials/howto-hcloud-terraform)
- [Hetzner Cloud Provider Documentation](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs)
- [Hetzner Cloud Provider](https://registry.terraform.io/providers/hetznercloud/hcloud/latest)

## Security Notes

- Never commit your `terraform.tfvars` file with real credentials
- The `.gitignore` file is configured to exclude sensitive files
- The API token is marked as sensitive in the Terraform configuration
