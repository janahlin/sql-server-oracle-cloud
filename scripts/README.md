# Scripts Directory

This directory contains scripts to help deploy, manage, and troubleshoot the SQL Server on Azure deployment.

## Core Scripts

| Script | Description |
|--------|-------------|
| `deploy.sh` | Main deployment script that handles prerequisites and runs the Ansible playbook to deploy SQL Server to Azure |
| `direct_deploy.sh` | Alternative deployment script that directly uses Terraform without Ansible, useful for troubleshooting |
| `check_environment.sh` | Validates the environment, prerequisites, and project structure before deployment |
| `test_deployment.sh` | Runs comprehensive tests to validate the deployment configuration before actual deployment |
| `generate_tfvars.py` | Python script to convert Ansible vault variables to Terraform tfvars |

## Utility Scripts

| Script | Description |
|--------|-------------|
| `lint.sh` | Runs linting checks on Terraform and Ansible code |
| `ansible-lint-ci.sh` | Specialized linting for Ansible in CI environments |
| `update_vault.sh` | Updates the Ansible vault with new Azure credentials or values |

## Usage Examples

### Standard Deployment
```bash
# Check environment first
./scripts/check_environment.sh

# Update vault with Azure credentials
./scripts/update_vault.sh

# Generate Terraform variables from Ansible vault
python3 ./scripts/generate_tfvars.py

# Deploy SQL Server to Azure
./scripts/deploy.sh
```

### Testing Only
```bash
# Run comprehensive tests without deploying
./scripts/test_deployment.sh
```

### Troubleshooting
```bash
# If having issues with Ansible, try direct deployment
./scripts/direct_deploy.sh
```

## Notes

- All scripts should be run from the repository root directory
- Make sure to set proper Azure credentials before running any deployment script
- Ensure you have enough quota in your Azure subscription for the VM size specified (default is Standard_B1s)
