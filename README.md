# SQL Server Developer Edition in Oracle Cloud

This repository contains infrastructure as code for deploying SQL Server Developer Edition in Oracle Cloud Free Tier.

## Architecture

The architecture consists of the following components:

1. **Windows Server 2022 VM** in Oracle Cloud Free Tier
   - 2 OCPU (ARM64)
   - 8 GB RAM
   - 100 GB storage

2. **SQL Server Developer Edition**
   - Installed on Windows Server 2022
   - Configured for optimal performance in development environment

3. **Controller VM**
   - Used to run Terraform and Ansible
   - Manages deployment of infrastructure and configuration

## Prerequisites

- Oracle Cloud account with Free Tier
- Controller VM with access to Oracle Cloud
- Terraform 1.0+
- Ansible 2.9+
- Git

## Quick Start

1. Clone this repository:
   ```bash
   git clone https://github.com/your-username/sql-server-oracle-cloud.git
   cd sql-server-oracle-cloud
   ```

2. Configure Oracle Cloud authentication:
   - Create an API key in Oracle Cloud Console
   - Save the private key in `~/.oci/oci_api_key.pem`
   - Configure `~/.oci/config` with your credentials

3. Initialize Terraform:
   ```bash
   cd terraform/environments/dev
   terraform init
   ```

4. Deploy the infrastructure:
   ```bash
   terraform apply
   ```

5. Configure SQL Server with Ansible:
   ```bash
   cd ../../../ansible
   ansible-playbook -i inventory playbooks/setup_sql_server.yml
   ```

## Resource Allocation

Oracle Cloud Free Tier offers the following resources:
- 4 OCPU (ARM64)
- 24 GB RAM
- 200 GB Block Storage (2 volumes)

This deployment uses:
- 2 OCPU (50%)
- 8 GB RAM (33%)
- 100 GB Block Storage (50%)
