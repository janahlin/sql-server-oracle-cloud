# Scripts Directory

This directory contains scripts to help deploy, manage, and troubleshoot the SQL Server on Oracle Cloud Free Tier deployment.

## Core Scripts

| Script | Description |
|--------|-------------|
| `deploy.sh` | Main deployment script that handles prerequisites and runs the Ansible playbook to deploy SQL Server to Oracle Cloud |
| `direct_deploy.sh` | Alternative deployment script that directly uses Terraform without Ansible, useful for troubleshooting |
| `check_environment.sh` | Validates the environment, prerequisites, and project structure before deployment |
| `test_deployment.sh` | Runs comprehensive tests to validate the deployment configuration before actual deployment |
| `update_tfvars.sh` | Updates Terraform variables to use Free Tier eligible shape (VM.Standard.E2.1.Micro) |

## Utility Scripts

| Script | Description |
|--------|-------------|
| `lint.sh` | Runs linting checks on Terraform and Ansible code |
| `ansible-lint-ci.sh` | Specialized linting for Ansible in CI environments |
| `update_vault.sh` | Updates the Ansible vault with new credentials or values |

## Usage Examples

### Standard Deployment
```bash
# Check environment first
./scripts/check_environment.sh

# Ensure using Free Tier shape
./scripts/update_tfvars.sh

# Deploy SQL Server to Oracle Cloud
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
- The backup directory contains older scripts that are kept for reference but not actively used
- Make sure to set proper credentials before running any deployment script
- Always use the Free Tier eligible shape (VM.Standard.E2.1.Micro) to avoid unexpected charges
