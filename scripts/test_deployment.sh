#!/bin/bash
# Comprehensive test script for SQL Server on Azure deployment
set -e

# Color codes for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Track overall test status
TESTS_PASSED=true

# Function to print section headers
section() {
    echo -e "\n${YELLOW}===== $1 =====${NC}\n"
}

# Function to check success/failure
check_result() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ $1${NC}"
    else
        echo -e "${RED}✗ $1${NC}"
        TESTS_PASSED=false
        if [ "$2" == "fatal" ]; then
            echo -e "${RED}Fatal error, cannot continue tests${NC}"
            exit 1
        fi
    fi
}

# Function to check if a file exists
check_file() {
    if [ -f "$1" ]; then
        echo -e "${GREEN}✓ File exists: $1${NC}"
    else
        echo -e "${RED}✗ File missing: $1${NC}"
        TESTS_PASSED=false
    fi
}

# Ensure we're in the repository root
if [ ! -d "terraform" ] || [ ! -d "ansible" ]; then
    echo -e "${RED}Error: This script must be run from the repository root${NC}"
    exit 1
fi

section "Checking Directory Structure"
directories=(
    "terraform/environments/dev"
    "ansible/playbooks"
    "ansible/roles"
    "ansible/group_vars/all"
)

for dir in "${directories[@]}"; do
    if [ -d "$dir" ]; then
        echo -e "${GREEN}✓ Directory exists: $dir${NC}"
    else
        echo -e "${RED}✗ Directory missing: $dir${NC}"
        TESTS_PASSED=false
    fi
done

section "Checking Critical Files"
files=(
    "terraform/environments/dev/main.tf"
    "terraform/environments/dev/variables.tf"
    "terraform/environments/dev/terraform.tfvars"
    "ansible/site.yml"
    "ansible/playbooks/deploy_infrastructure.yml"
    "ansible/playbooks/setup_sql_server.yml"
    "ansible/ansible.cfg"
    "ansible/group_vars/all/vars.yml"
    "ansible/group_vars/all/vault.yml"
)

for file in "${files[@]}"; do
    check_file "$file"
done

section "Checking Terraform Configuration"
cd terraform/environments/dev
echo "Running terraform validate..."
terraform validate
check_result "Terraform validation" "fatal"

# Check Terraform plan readiness
if [ -f "terraform.tfvars" ]; then
    echo "Running terraform plan..."
    terraform plan -no-color > /tmp/tf_plan_output 2>&1 || true

    if grep -q "Error:" /tmp/tf_plan_output; then
        echo -e "${RED}✗ Terraform plan has errors${NC}"
        grep -A 2 "Error:" /tmp/tf_plan_output
        TESTS_PASSED=false
    else
        echo -e "${GREEN}✓ Terraform plan produced no errors${NC}"
    fi
else
    echo -e "${YELLOW}⚠ terraform.tfvars not found, skipping terraform plan${NC}"
fi
cd - > /dev/null

section "Checking Ansible Playbook Syntax"
cd ansible
if [ -f "site.yml" ]; then
    echo "Running ansible-playbook syntax check..."
    ansible-playbook site.yml --syntax-check
    check_result "Ansible playbook syntax check"
else
    echo -e "${RED}✗ site.yml not found in ansible directory${NC}"
    TESTS_PASSED=false
fi
cd - > /dev/null

section "Checking Azure CLI Configuration"
if command -v az &> /dev/null; then
    echo "Azure CLI installed, checking configuration..."
    az account show &> /dev/null
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Azure CLI correctly configured${NC}"
    else
        echo -e "${YELLOW}⚠ Azure CLI not properly configured${NC}"
        echo "Run 'az login' to log in to Azure"
    fi
else
    echo -e "${YELLOW}⚠ Azure CLI not installed${NC}"
    echo "Install Azure CLI to manage your Azure resources"
fi

section "Testing Summary"
if [ "$TESTS_PASSED" = true ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    echo -e "\nYou can now run the deployment with:"
    echo -e "  cd ansible && ansible-playbook site.yml"
else
    echo -e "${RED}Some tests failed. Please fix the issues before deploying.${NC}"
    exit 1
fi
