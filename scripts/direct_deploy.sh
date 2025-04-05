#!/bin/bash
# Direct deployment script for SQL Server on Azure
set -e

# Color codes for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Function to print section headers
section() {
    echo -e "\n${YELLOW}===== $1 =====${NC}\n"
}

# Change to the dev environment directory
cd terraform/environments/dev

# First, let's try to remove or rename the problematic tfvars file
if [ -f terraform.tfvars.json ]; then
  echo "Renaming terraform.tfvars.json to avoid permission issues"
  mv terraform.tfvars.json terraform.tfvars.json.bak 2>/dev/null || echo "Could not rename file, continuing anyway"
fi

section "Initializing Terraform"
# Initialize Terraform
terraform init

section "Creating Infrastructure"
# Check for required variables
if [ -z "$AZURE_SUBSCRIPTION_ID" ] || [ -z "$AZURE_TENANT_ID" ] || [ -z "$AZURE_CLIENT_ID" ] || [ -z "$AZURE_CLIENT_SECRET" ]; then
  echo -e "${RED}Error: Required Azure environment variables not set.${NC}"
  echo "Please set the following environment variables:"
  echo "  - AZURE_SUBSCRIPTION_ID"
  echo "  - AZURE_TENANT_ID"
  echo "  - AZURE_CLIENT_ID"
  echo "  - AZURE_CLIENT_SECRET"
  echo "  - AZURE_LOCATION (defaults to westeurope)"
  exit 1
fi

# Set default values for optional variables
AZURE_LOCATION="${AZURE_LOCATION:-westeurope}"
AZURE_RESOURCE_GROUP="${AZURE_RESOURCE_GROUP:-sql-server-rg}"
AZURE_VM_SIZE="${AZURE_VM_SIZE:-Standard_B1s}"
AZURE_ADMIN_USERNAME="${AZURE_ADMIN_USERNAME:-azureuser}"
AZURE_ADMIN_PASSWORD="${AZURE_ADMIN_PASSWORD:-YourSecurePassword123!}"

# Create the basic infrastructure with all variables on command line
echo -e "${GREEN}Creating infrastructure using secure environment variables...${NC}"
terraform apply -auto-approve \
  -var="subscription_id=$AZURE_SUBSCRIPTION_ID" \
  -var="tenant_id=$AZURE_TENANT_ID" \
  -var="client_id=$AZURE_CLIENT_ID" \
  -var="client_secret=$AZURE_CLIENT_SECRET" \
  -var="location=$AZURE_LOCATION" \
  -var="resource_group_name=$AZURE_RESOURCE_GROUP" \
  -var="vm_size=$AZURE_VM_SIZE" \
  -var="admin_username=$AZURE_ADMIN_USERNAME" \
  -var="admin_password=$AZURE_ADMIN_PASSWORD" \
  -var="ssh_public_key=$(cat ~/.ssh/id_rsa.pub)"

# Get output
section "Deployment Output"
terraform output

echo ""
echo -e "${GREEN}Deployment completed.${NC}"
echo "If successfully deployed, use the IP address above to connect to your Windows VM with SQL Server."
