#!/bin/bash

# SQL Server on Azure Deployment Script
# This script automates the deployment of SQL Server Developer Edition on Azure

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

echo -e "${GREEN}Starting SQL Server on Azure deployment...${NC}"

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo -e "${RED}Azure CLI is not installed. Please install it and try again.${NC}"
    echo "Visit: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    echo -e "${RED}Terraform is not installed. Please install it and try again.${NC}"
    echo "Visit: https://www.terraform.io/downloads.html"
    exit 1
fi

# Check if Ansible is installed
if ! command -v ansible &> /dev/null; then
    echo -e "${RED}Ansible is not installed. Please install it and try again.${NC}"
    echo "Visit: https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html"
    exit 1
fi

# Check Azure login status
echo -e "${YELLOW}Checking Azure login status...${NC}"
az account show &> /dev/null
if [ $? -ne 0 ]; then
    echo -e "${YELLOW}Not logged in to Azure. Please login:${NC}"
    az login
    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to login to Azure. Exiting.${NC}"
        exit 1
    fi
fi

# Verify configuration files
echo -e "${YELLOW}Verifying configuration...${NC}"

# Check if terraform.tfvars exists
if [ ! -f "$ROOT_DIR/terraform/environments/dev/terraform.tfvars" ]; then
    echo -e "${RED}terraform.tfvars file is missing. Please create it in terraform/environments/dev/ directory.${NC}"
    exit 1
fi

# Deploy infrastructure with Ansible
echo -e "${YELLOW}Running deployment...${NC}"
cd "$ROOT_DIR/ansible"
ansible-playbook playbooks/deploy_infrastructure.yml

if [ $? -ne 0 ]; then
    echo -e "${RED}Infrastructure deployment failed. Check the logs above for errors.${NC}"
    exit 1
fi

# Wait a bit for the VM to fully initialize
echo -e "${YELLOW}Waiting for the VM to initialize (60 seconds)...${NC}"
sleep 60

# Configure SQL Server
echo -e "${YELLOW}Configuring SQL Server...${NC}"
ansible-playbook -i inventory/hosts.yml playbooks/configure_sql_server.yml

if [ $? -ne 0 ]; then
    echo -e "${RED}SQL Server configuration failed. Check the logs above for errors.${NC}"
    exit 1
fi

# Get VM IP address
VM_IP=$(cd "$ROOT_DIR/terraform/environments/dev" && terraform output -raw sql_server_public_ip)

echo -e "${GREEN}SQL Server has been successfully deployed to Azure!${NC}"
echo -e "${GREEN}===================================================${NC}"
echo -e "${YELLOW}Connection Information:${NC}"
echo -e "SQL Server: $VM_IP"
echo -e "Connect using SQL Server Management Studio (SSMS) or Azure Data Studio"
echo -e "Authentication: Windows Authentication"
echo -e "Default Username: azureuser"
echo -e "Default Password: As specified in terraform.tfvars"
echo -e "${GREEN}===================================================${NC}"
echo -e "${YELLOW}Security Notes:${NC}"
echo -e "1. Change the SQL Server SA password on first login"
echo -e "2. Consider implementing additional security measures for production use"
echo -e "3. Create a snapshot or backup for disaster recovery"
echo -e "${GREEN}===================================================${NC}"

exit 0
