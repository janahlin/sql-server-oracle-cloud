#!/bin/bash

# Script to retrieve SQL Server connection information

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# Get VM IP from Terraform output
VM_IP=$(cd "$ROOT_DIR/terraform/environments/dev" && terraform output -raw sql_server_public_ip 2>/dev/null)

# If terraform output fails, try Azure CLI as fallback
if [ -z "$VM_IP" ]; then
    echo -e "${YELLOW}Trying to get IP address from Azure CLI...${NC}"
    VM_IP=$(az vm list-ip-addresses --resource-group sql-server-rg --name sqlserver-dev --query "[0].virtualMachine.network.publicIpAddresses[0].ipAddress" -o tsv 2>/dev/null)
fi

if [ -z "$VM_IP" ]; then
    echo -e "${YELLOW}Could not retrieve SQL Server IP address. Please ensure the VM is deployed.${NC}"
    exit 1
fi

echo -e "${GREEN}===================================================${NC}"
echo -e "${GREEN}SQL Server Connection Information${NC}"
echo -e "${GREEN}===================================================${NC}"
echo -e "${YELLOW}Public IP:${NC} $VM_IP"
echo -e "${YELLOW}SQL Server connection string:${NC} Server=$VM_IP,1433;"
echo -e "${YELLOW}RDP connection:${NC} mstsc /v:$VM_IP"
echo -e "${YELLOW}Authentication:${NC} Windows Authentication"
echo -e "${YELLOW}Default Username:${NC} azureuser"
echo -e "${YELLOW}Default Password:${NC} As specified in terraform.tfvars"
echo -e "${GREEN}===================================================${NC}"

exit 0
