#!/bin/bash
# Deployment script for SQL Server on Oracle Cloud
set -e

# Color codes for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print section headers
section() {
    echo -e "\n${BLUE}===== $1 =====${NC}\n"
}

# Ensure we're in the repository root
if [ ! -d "terraform" ] || [ ! -d "ansible" ]; then
    echo -e "${RED}Error: This script must be run from the repository root${NC}"
    exit 1
fi

section "Checking Prerequisites"

# Check if ansible is installed
if ! command -v ansible-playbook &> /dev/null; then
    echo -e "${RED}Error: ansible-playbook command not found${NC}"
    echo "Please install Ansible with: pip install ansible"
    exit 1
fi

# Check if terraform is installed
if ! command -v terraform &> /dev/null; then
    echo -e "${RED}Error: terraform command not found${NC}"
    echo "Please install Terraform from https://www.terraform.io/downloads.html"
    exit 1
fi

# Check if oci CLI is configured
if ! command -v oci &> /dev/null; then
    echo -e "${YELLOW}Warning: oci command not found${NC}"
    echo "Consider installing OCI CLI for easier troubleshooting: pip install oci-cli"
fi

# Check if vault password file exists
if [ ! -f "ansible/.vault_pass.txt" ]; then
    echo -e "${YELLOW}Vault password file not found. Creating it now...${NC}"
    echo -n "Enter a secure password for the Ansible Vault: "
    read -s VAULT_PASSWORD
    echo
    
    echo "$VAULT_PASSWORD" > ansible/.vault_pass.txt
    chmod 600 ansible/.vault_pass.txt
    echo -e "${GREEN}Vault password file created${NC}"
fi

# Check if vault file exists
if [ ! -f "ansible/group_vars/all/vault.yml" ]; then
    section "Creating Vault File"
    echo -e "${YELLOW}Vault file not found. You'll need to create it with your credentials.${NC}"
    echo "The vault file should contain your OCI credentials and other sensitive data."
    echo "A template will be opened for you to edit."
    
    # Create a template vault file
    TMP_VAULT=$(mktemp)
    cat > "$TMP_VAULT" << EOF
---
# Oracle Cloud credentials
vault_oci_tenancy_ocid: "ocid1.tenancy.oc1..xxxxxxxxxxxx"
vault_oci_user_ocid: "ocid1.user.oc1..xxxxxxxxxxxx"
vault_oci_fingerprint: "xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx"
vault_oci_private_key_path: "~/.oci/oci_api_key.pem"

# Windows VM credentials - please use a strong password
vault_windows_admin_password: "Yp4sv!A8YmNFaR#wZ7E6"
vault_ssh_private_key_path: "~/.ssh/id_rsa"
vault_ssh_public_key: "$(cat ~/.ssh/id_rsa.pub 2>/dev/null || echo 'ssh-rsa AAAAB...your_public_key_here')"
EOF
    
    # Create the encrypted vault file
    ansible-vault encrypt "$TMP_VAULT" --output="ansible/group_vars/all/vault.yml" --vault-password-file=ansible/.vault_pass.txt
    
    # Open the file for editing
    echo -e "${YELLOW}Please edit the vault file with your actual credentials${NC}"
    if command -v ansible-vault &> /dev/null; then
        ansible-vault edit ansible/group_vars/all/vault.yml --vault-password-file=ansible/.vault_pass.txt
    else
        echo -e "${RED}ansible-vault command not found.${NC}"
        echo "Please manually edit ansible/group_vars/all/vault.yml with your credentials."
        echo "You can use: ansible-vault edit ansible/group_vars/all/vault.yml --vault-password-file=ansible/.vault_pass.txt"
    fi
    
    # Clean up
    rm "$TMP_VAULT"
fi

# Ensure infrastructure uses Free Tier eligible shape
section "Verifying Configuration"

# Check for Free Tier VM shape
TERRAFORM_VARS_FILE="terraform/environments/dev/terraform.tfvars.json"
if [ -f "$TERRAFORM_VARS_FILE" ]; then
    if ! grep -q "VM.Standard.E2.1.Micro" "$TERRAFORM_VARS_FILE"; then
        echo -e "${YELLOW}Warning: Your Terraform configuration may not be using a Free Tier eligible shape.${NC}"
        echo "Recommended: Edit $TERRAFORM_VARS_FILE to set shape to VM.Standard.E2.1.Micro"
    fi
fi

section "Running Deployment"

# Navigate to ansible directory
cd ansible

# Run the deployment
echo -e "${GREEN}Starting deployment...${NC}"
ansible-playbook site.yml --vault-password-file=.vault_pass.txt

# Check deployment status
if [ $? -eq 0 ]; then
    section "Deployment Complete"
    echo -e "${GREEN}SQL Server has been successfully deployed to Oracle Cloud!${NC}"
    
    # Get the Windows VM IP if available
    if [ -f "inventory/hosts" ]; then
        VM_IP=$(grep -A1 windows inventory/hosts 2>/dev/null | tail -1 || echo "")
        if [ -n "$VM_IP" ]; then
            echo -e "SQL Server is available at: ${GREEN}$VM_IP${NC}"
            echo -e "Connect using:"
            echo -e "  - SQL Server Management Studio"
            echo -e "  - sqlcmd -S $VM_IP -U sa -P <password>"
            echo -e "  - RDP to $VM_IP (Administrator/your-windows-password)"
            
            # Security reminder
            echo -e "\n${YELLOW}Important Security Note:${NC}"
            echo -e "Remember that your SQL Server is exposed to the internet."
            echo -e "Consider implementing additional security measures:"
            echo -e "  - Use a VPN for access"
            echo -e "  - Implement Network Security Groups to restrict access"
            echo -e "  - Enable SQL Server login auditing"
        else
            echo -e "${YELLOW}Unable to find Windows VM IP in inventory file.${NC}"
        fi
    else
        echo -e "${YELLOW}Inventory file not found. Check deployment logs for connection details.${NC}"
    fi
    
    echo -e "\n${BLUE}Recommendation:${NC} Create a snapshot or backup of your VM for disaster recovery."
else
    section "Deployment Failed"
    echo -e "${RED}Deployment encountered errors. Please check the logs above.${NC}"
    echo -e "Common issues:"
    echo -e "  - OCI credentials not correctly configured"
    echo -e "  - Service limits reached in your Oracle Cloud account"
    echo -e "  - Network connectivity issues"
    echo -e "\nTry running the test script first: ./scripts/test_deployment.sh"
    exit 1
fi 