# SQL Server Developer Edition in Azure

This repository contains the code to deploy SQL Server Developer Edition on a Windows Server in Microsoft Azure using Terraform and Ansible.

## Architecture

The architecture consists of:

- Windows Server 2019 VM in Azure
- SQL Server Developer Edition installed on the VM
- Virtual Network with Security Groups
- Controller VM/machine to run Terraform and Ansible

For more details, see [Architecture](docs/architecture.md).

## Prerequisites

- Microsoft Azure account
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) installed
- A machine/VM to serve as a Controller with:
  - [Terraform](https://www.terraform.io/downloads.html) (v1.0.0+)
  - [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html) (v2.9+)
  - [Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)

## Quick Start

1. **Clone this repository**:
   ```
   git clone https://github.com/yourusername/sql-server-azure.git
   cd sql-server-azure
   ```

2. **Configure Azure authentication**:
   - Create a Service Principal:
     ```
     az login
     az ad sp create-for-rbac --name "sql-server-sp" --role contributor --scopes /subscriptions/{subscription-id}
     ```
   - Note the `appId` (client_id), `password` (client_secret), `tenant` (tenant_id), and your subscription ID
   - Create a `terraform.tfvars` file in the `terraform/environments/dev` directory:
     ```
     cp terraform/environments/dev/terraform.tfvars.example terraform/environments/dev/terraform.tfvars
     ```
   - Edit the file with your Azure credentials

3. **Initialize Terraform**:
   ```
   cd terraform/environments/dev
   terraform init
   ```

4. **Deploy Infrastructure**:
   ```
   terraform apply -auto-approve
   ```
   Or use Ansible:
   ```
   cd ../../../
   ansible-playbook ansible/playbooks/deploy_infrastructure.yml
   ```

5. **Configure SQL Server with Ansible**:
   ```
   ansible-playbook -i ansible/inventory/hosts ansible/site.yml
   ```

## Using Ansible Vault Variables with Terraform

This project uses Ansible Vault to securely store sensitive information. To use these variables with Terraform:

1. **Decrypt the Ansible vault file** (you'll need the vault password):
   ```
   ansible-vault decrypt ansible/group_vars/all/vault.yml
   ```

2. **Generate Terraform variables from Ansible vault**:
   ```
   ./scripts/generate_tfvars.py
   ```
   This will create a `terraform.tfvars` file in the `terraform/environments/dev` directory based on your Ansible vault variables.

3. **Re-encrypt the Ansible vault file** when done:
   ```
   ansible-vault encrypt ansible/group_vars/all/vault.yml
   ```

## Resource Allocation

Azure Standard_B1s VM:
- 1 vCPU
- 1 GB RAM
- 100 GB disk space

Windows Server 2019 with SQL Server Developer Edition requires:
- 1 CPU (minimum)
- 1 GB RAM (minimum, 2+ GB recommended for development)
- 40-60 GB disk space (Windows + SQL Server)

## Development

For development guidelines, see [Development](docs/development.md).

## Troubleshooting

For troubleshooting common issues, see [Troubleshooting](docs/troubleshooting.md).

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
