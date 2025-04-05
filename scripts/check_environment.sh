#!/bin/bash
# Environment check script for SQL Server on Azure
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
if check_command "az"; then
    # Try to verify Azure CLI configuration
    if az account show &> /dev/null; then
        echo -e "${GREEN}✓ Azure CLI correctly configured${NC}"
    else
        echo -e "${YELLOW}⚠ Azure CLI installed but not logged in${NC}"
        echo "Run 'az login' to log in to Azure"
    fi
else
    echo -e "${YELLOW}⚠ Azure CLI not installed (recommended)${NC}"
    echo "Consider installing Azure CLI for easier Azure management"
fi

check_command "jq" || echo -e "${YELLOW}⚠ jq not installed (optional but recommended)${NC}"
check_command "python3" || echo -e "${YELLOW}⚠ python3 not installed (needed for the generate_tfvars.py script)${NC}"

section "Checking Project Structure"

# Check core directories
check_dir "terraform/environments/dev" || PREREQS_MET=false
check_dir "ansible/playbooks" || PREREQS_MET=false
check_dir "ansible/roles" || PREREQS_MET=false
check_dir "ansible/group_vars/all" || PREREQS_MET=false

# Check critical files
check_file "terraform/environments/dev/main.tf" || PREREQS_MET=false
check_file "terraform/environments/dev/variables.tf" || PREREQS_MET=false
check_file "terraform/environments/dev/terraform.tfvars.template" || PREREQS_MET=false
check_file "ansible/site.yml" || PREREQS_MET=false
check_file "ansible/ansible.cfg" || PREREQS_MET=false
check_file "ansible/group_vars/all/vars.yml" || PREREQS_MET=false
check_file "scripts/generate_tfvars.py" || PREREQS_MET=false

# Check for sensitive files
if ! check_file "ansible/group_vars/all/vault.yml"; then
    echo -e "${YELLOW}⚠ Vault file not found. Run deploy.sh to create it.${NC}"
fi

if ! check_file "ansible/.vault_pass.txt"; then
    echo -e "${YELLOW}⚠ Vault password file not found. Run deploy.sh to create it.${NC}"
fi

if ! check_file "terraform/environments/dev/terraform.tfvars"; then
    echo -e "${YELLOW}⚠ terraform.tfvars not found. Run scripts/generate_tfvars.py to create it.${NC}"
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

# Check Python dependencies for generate_tfvars.py
section "Checking Python Dependencies"
if python3 -c "import yaml" &> /dev/null; then
    echo -e "${GREEN}✓ PyYAML module installed${NC}"
else
    echo -e "${YELLOW}⚠ PyYAML module not installed${NC}"
    echo "Install with: pip install pyyaml"
    PREREQS_MET=false
fi

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
