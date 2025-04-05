#!/bin/bash
# Environment check script for SQL Server on Oracle Cloud
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

# Function to check command availability
check_command() {
    if command -v "$1" &> /dev/null; then
        echo -e "${GREEN}✓ $1 installed${NC}"
        return 0
    else
        echo -e "${RED}✗ $1 not installed${NC}"
        return 1
    fi
}

# Function to check file existence
check_file() {
    if [ -f "$1" ]; then
        echo -e "${GREEN}✓ File exists: $1${NC}"
        return 0
    else
        echo -e "${RED}✗ File missing: $1${NC}"
        return 1
    fi
}

# Function to check directory existence
check_dir() {
    if [ -d "$1" ]; then
        echo -e "${GREEN}✓ Directory exists: $1${NC}"
        return 0
    else
        echo -e "${RED}✗ Directory missing: $1${NC}"
        return 1
    fi
}

# Ensure we're in the repository root
if ! (check_dir "terraform" && check_dir "ansible"); then
    echo -e "${RED}Error: This script must be run from the repository root${NC}"
    exit 1
fi

section "Checking Software Prerequisites"

PREREQS_MET=true

# Check for required software
check_command "terraform" || PREREQS_MET=false
check_command "ansible-playbook" || PREREQS_MET=false
check_command "ansible-vault" || PREREQS_MET=false

# Optional but recommended tools
if check_command "oci"; then
    # Try to verify OCI CLI configuration
    if oci iam compartment list --query 'data[0].id' --output table &> /dev/null; then
        echo -e "${GREEN}✓ OCI CLI correctly configured${NC}"
    else
        echo -e "${YELLOW}⚠ OCI CLI installed but not properly configured${NC}"
        echo "Run 'oci setup config' to configure"
    fi
else
    echo -e "${YELLOW}⚠ OCI CLI not installed (optional)${NC}"
    echo "Consider installing with: pip install oci-cli"
fi

check_command "jq" || echo -e "${YELLOW}⚠ jq not installed (optional)${NC}"

section "Checking Project Structure"

# Check core directories
check_dir "terraform/environments/dev" || PREREQS_MET=false
check_dir "terraform/modules" || PREREQS_MET=false
check_dir "ansible/playbooks" || PREREQS_MET=false
check_dir "ansible/roles" || PREREQS_MET=false
check_dir "ansible/group_vars/all" || PREREQS_MET=false

# Check critical files
check_file "terraform/environments/dev/main.tf" || PREREQS_MET=false
check_file "terraform/environments/dev/variables.tf" || PREREQS_MET=false
check_file "ansible/site.yml" || PREREQS_MET=false
check_file "ansible/ansible.cfg" || PREREQS_MET=false

# Check for sensitive files
if ! check_file "ansible/group_vars/all/vault.yml"; then
    echo -e "${YELLOW}⚠ Vault file not found. Run deploy.sh to create it.${NC}"
fi

if ! check_file "ansible/.vault_pass.txt"; then
    echo -e "${YELLOW}⚠ Vault password file not found. Run deploy.sh to create it.${NC}"
fi

# Check Terraform configuration
section "Checking Terraform Configuration"
cd terraform/environments/dev
terraform validate
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Terraform configuration is valid${NC}"
else
    echo -e "${RED}✗ Terraform configuration has errors${NC}"
    PREREQS_MET=false
fi
cd - > /dev/null

# Check for Free Tier compliance
section "Checking Free Tier Compliance"
TERRAFORM_VARS_FILE="terraform/environments/dev/terraform.tfvars.json"
if [ -f "$TERRAFORM_VARS_FILE" ]; then
    if grep -q '"shape": "VM.Standard.E2.1.Micro"' "$TERRAFORM_VARS_FILE"; then
        echo -e "${GREEN}✓ Using Free Tier eligible shape (VM.Standard.E2.1.Micro)${NC}"
    else
        echo -e "${YELLOW}⚠ Not using Free Tier eligible shape${NC}"
        echo "Run ./scripts/update_tfvars.sh to update"
    fi
else
    echo -e "${YELLOW}⚠ No terraform.tfvars.json found${NC}"
    echo "Run ./scripts/update_tfvars.sh to create one"
fi

# Check Ansible configuration
section "Checking Ansible Configuration"
cd ansible
if ansible-playbook site.yml --syntax-check &> /dev/null; then
    echo -e "${GREEN}✓ Ansible playbook syntax is valid${NC}"
else
    echo -e "${RED}✗ Ansible playbook has syntax errors${NC}"
    PREREQS_MET=false
fi
cd - > /dev/null

# Summary
section "Environment Check Summary"
if [ "$PREREQS_MET" = true ]; then
    echo -e "${GREEN}All critical checks passed!${NC}"
    echo -e "You can proceed with deployment by running:"
    echo -e "  ./scripts/deploy.sh"
else
    echo -e "${RED}Some critical checks failed. Please fix the issues before deploying.${NC}"
    exit 1
fi
