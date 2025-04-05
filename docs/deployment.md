# Deployment Guide

This document provides detailed instructions for deploying SQL Server Developer Edition in Azure using this repository.

## Prerequisites

Before you begin, ensure you have:

1. **Azure Account**: An active Microsoft Azure subscription.
2. **Azure CLI**: Installed and configured on your local machine.
3. **Required Tools**:
   - Terraform v1.0.0 or later
   - Ansible v2.9.0 or later
   - Python 3.6 or later

## Azure Authentication Setup

1. **Log in to Azure**:
   ```bash
   az login
   ```

2. **Create a Service Principal** (optional, for automated deployments):
   ```bash
   az ad sp create-for-rbac --name "sql-server-deployment" --role Contributor --scopes /subscriptions/YOUR_SUBSCRIPTION_ID
   ```

3. **Record the credentials** returned from the command above:
   - `appId` (this is your `client_id`)
   - `password` (this is your `client_secret`)
   - `tenant` (this is your `tenant_id`)

## Configuration

1. **Clone the repository**:
   ```bash
   git clone https://github.com/your-organization/sql-server-azure.git
   cd sql-server-azure
   ```

2. **Create terraform.tfvars file**:
   Create a file at `terraform/environments/dev/terraform.tfvars` with the following content:

   ```hcl
   # Azure Authentication
   subscription_id     = "your-subscription-id"
   tenant_id           = "your-tenant-id"
   client_id           = "your-client-id"
   client_secret       = "your-client-secret"

   # Azure Configuration
   location            = "westeurope"
   resource_group_name = "sql-server-rg"

   # VM Configuration
   admin_username      = "azureuser"
   admin_password      = "YourSecurePassword123!"
   vm_size             = "Standard_B1s"
   ssh_public_key      = "ssh-rsa AAAAB3N... your-ssh-key"
   ```

3. **Update Ansible inventory**:
   The IP address will be automatically updated during deployment, but you can modify other settings in `ansible/inventory/hosts.yml` if needed.

## Deployment

1. **Initialize Terraform**:
   ```bash
   cd terraform/environments/dev
   terraform init
   ```

2. **Validate the Terraform plan**:
   ```bash
   terraform plan
   ```

3. **Deploy the infrastructure**:
   ```bash
   terraform apply -auto-approve
   ```

4. **Run Ansible playbook** to configure SQL Server:
   ```bash
   cd ../../../ansible
   ansible-playbook -i inventory/hosts.yml playbooks/configure_sql_server.yml
   ```

Alternatively, you can use the deployment script which handles both steps:

```bash
./scripts/deploy.sh
```

## Connection Details

After successful deployment, you can connect to:

1. **SQL Server**:
   - **Server**: The public IP address (shown in the deployment output)
   - **Authentication**: Windows Authentication
   - **Username**: azureuser
   - **Password**: The password specified in terraform.tfvars

2. **Windows VM (via RDP)**:
   - **Host**: The public IP address (shown in the deployment output)
   - **Username**: azureuser
   - **Password**: The password specified in terraform.tfvars

## Clean Up

To destroy all created resources:

```bash
cd terraform/environments/dev
terraform destroy -auto-approve
```

## Advanced Configuration

### Customizing VM Size

To modify the VM specifications, update the `vm_size` value in `terraform.tfvars`. Available options include:

- `Standard_B1s`: 1 vCPU, 1 GB RAM (minimum for development)
- `Standard_B2s`: 2 vCPU, 4 GB RAM (recommended for better performance)
- `Standard_B4ms`: 4 vCPU, 16 GB RAM (for more intensive workloads)

### Customizing Network Configuration

Edit the `main.tf` file to modify:
- Virtual Network address space
- Subnet configuration
- Network Security Group rules
