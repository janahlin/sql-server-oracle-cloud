#!/bin/bash

# SQL Server VM Management Script
# This script helps manage the SQL Server VM to save costs

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# Resource group and VM name
RESOURCE_GROUP="sql-server-rg"
VM_NAME="sqlserver-dev"

# Check prerequisites
if ! command -v az &> /dev/null; then
    echo -e "${RED}Azure CLI is not installed. Please install it and try again.${NC}"
    echo "Visit: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi

# Check Azure login status
az account show &> /dev/null
if [ $? -ne 0 ]; then
    echo -e "${YELLOW}Not logged in to Azure. Please login:${NC}"
    az login
    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to login to Azure. Exiting.${NC}"
        exit 1
    fi
fi

# Function to display usage information
function show_usage {
    echo -e "${YELLOW}SQL Server VM Management Script${NC}"
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  start     - Start the SQL Server VM"
    echo "  stop      - Stop the SQL Server VM (deallocates to save costs)"
    echo "  status    - Check the current status of the VM"
    echo "  schedule  - Set up an auto-shutdown schedule"
    echo "  help      - Display this help message"
    echo ""
    echo "Example: $0 stop"
}

# Function to start the VM
function start_vm {
    echo -e "${YELLOW}Starting SQL Server VM...${NC}"
    az vm start --resource-group $RESOURCE_GROUP --name $VM_NAME
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}VM started successfully!${NC}"
        # Display connection information
        $SCRIPT_DIR/get_connection_info.sh
    else
        echo -e "${RED}Failed to start VM.${NC}"
    fi
}

# Function to stop the VM
function stop_vm {
    echo -e "${YELLOW}Stopping SQL Server VM (deallocating)...${NC}"
    az vm deallocate --resource-group $RESOURCE_GROUP --name $VM_NAME
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}VM stopped and deallocated successfully!${NC}"
        echo -e "${GREEN}No compute charges will be incurred until you start it again.${NC}"
    else
        echo -e "${RED}Failed to stop VM.${NC}"
    fi
}

# Function to check VM status
function check_status {
    echo -e "${YELLOW}Checking SQL Server VM status...${NC}"
    STATUS=$(az vm show -g $RESOURCE_GROUP -n $VM_NAME --query "powerState" -o tsv)

    if [ -z "$STATUS" ]; then
        echo -e "${RED}Failed to get VM status. VM might not exist.${NC}"
        exit 1
    fi

    echo -e "${GREEN}VM Status: $STATUS${NC}"

    if [[ "$STATUS" == "VM running" ]]; then
        # Display connection information if VM is running
        $SCRIPT_DIR/get_connection_info.sh

        # Calculate running time and estimated cost
        echo -e "${YELLOW}Cost Information:${NC}"
        echo -e "Standard_B2s costs approximately $0.0416/hour"
        echo -e "Remember to stop the VM when not in use to save costs"
    elif [[ "$STATUS" == "VM deallocated" ]]; then
        echo -e "${GREEN}VM is deallocated. No compute charges are being incurred.${NC}"
        echo -e "Use '$0 start' to start the VM when needed."
    fi
}

# Function to set up auto-shutdown schedule
function set_schedule {
    echo -e "${YELLOW}Setting up auto-shutdown schedule...${NC}"
    read -p "Enter shutdown time (24-hour format, e.g., 1900 for 7 PM): " SHUTDOWN_TIME
    read -p "Enter timezone (e.g., UTC, Pacific Standard Time): " TIMEZONE

    az vm auto-shutdown -g $RESOURCE_GROUP -n $VM_NAME --time $SHUTDOWN_TIME --timezone "$TIMEZONE"

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Auto-shutdown schedule set successfully!${NC}"
        echo -e "VM will automatically shut down at $SHUTDOWN_TIME $TIMEZONE daily"
    else
        echo -e "${RED}Failed to set auto-shutdown schedule.${NC}"
    fi
}

# Main script logic
case "$1" in
    start)
        start_vm
        ;;
    stop)
        stop_vm
        ;;
    status)
        check_status
        ;;
    schedule)
        set_schedule
        ;;
    help|--help|-h)
        show_usage
        ;;
    *)
        show_usage
        exit 1
        ;;
esac

exit 0
