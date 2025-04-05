#!/bin/bash
# Update Terraform variables to use Free Tier eligible shape
set -e

# Color codes for output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Updating Terraform variables to use Free Tier eligible shape...${NC}"

# Parse the existing terraform.tfvars.json file
if [ -f terraform/environments/dev/terraform.tfvars.json ]; then
  # Change the shape to VM.Standard.E2.1.Micro (Free Tier eligible)
  if command -v jq &> /dev/null; then
    jq '.shape = "VM.Standard.E2.1.Micro"' terraform/environments/dev/terraform.tfvars.json > /tmp/terraform.tfvars.json
    mv /tmp/terraform.tfvars.json terraform/environments/dev/terraform.tfvars.json
    echo -e "${GREEN}Updated shape in terraform.tfvars.json to VM.Standard.E2.1.Micro (Free Tier eligible)${NC}"
  else
    echo "jq command not found, trying alternate method"
    # Backup the original file
    cp terraform/environments/dev/terraform.tfvars.json terraform/environments/dev/terraform.tfvars.json.bak
    # Use sed to replace shape (might be less reliable than jq)
    sed -i 's/"shape": "VM.Standard[^"]*"/"shape": "VM.Standard.E2.1.Micro"/' terraform/environments/dev/terraform.tfvars.json
    echo -e "${GREEN}Updated shape in terraform.tfvars.json${NC}"
  fi
else
  echo -e "${YELLOW}No terraform.tfvars.json found in terraform/environments/dev/${NC}"
  
  # Create a basic tfvars file with correct shape
  echo -e "Creating a basic terraform.tfvars.json file..."
  cat > terraform/environments/dev/terraform.tfvars.json << EOF
{
  "shape": "VM.Standard.E2.1.Micro"
}
EOF
  echo -e "${GREEN}Created new terraform.tfvars.json with Free Tier eligible shape${NC}"
fi

echo -e "${GREEN}Done.${NC} You can now run the deployment script to deploy your infrastructure.
