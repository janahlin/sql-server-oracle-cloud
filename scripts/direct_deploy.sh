#!/bin/bash
# Direct deployment script for SQL Server on Oracle Cloud
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
if [ -z "$OCI_TENANCY_OCID" ] || [ -z "$OCI_USER_OCID" ] || [ -z "$OCI_FINGERPRINT" ]; then
  echo -e "${RED}Error: Required OCI environment variables not set.${NC}"
  echo "Please set the following environment variables:"
  echo "  - OCI_TENANCY_OCID"
  echo "  - OCI_USER_OCID"
  echo "  - OCI_FINGERPRINT"
  echo "  - OCI_PRIVATE_KEY_PATH (defaults to ~/.oci/oci_api_key.pem)"
  echo "  - OCI_REGION (defaults to eu-stockholm-1)"
  exit 1
fi

# Set default values for optional variables
OCI_PRIVATE_KEY_PATH="${OCI_PRIVATE_KEY_PATH:-~/.oci/oci_api_key.pem}"
OCI_REGION="${OCI_REGION:-eu-stockholm-1}"
OCI_COMPARTMENT_ID="${OCI_COMPARTMENT_ID:-$OCI_TENANCY_OCID}"
AVAILABILITY_DOMAIN="${AVAILABILITY_DOMAIN:-GiQi:EU-STOCKHOLM-1-AD-1}"
SHAPE="${SHAPE:-VM.Standard.E2.1.Micro}"  # Using Free Tier eligible shape

# Create the basic infrastructure with all variables on command line
echo -e "${GREEN}Creating infrastructure using secure environment variables...${NC}"
terraform apply -auto-approve \
  -var="tenancy_ocid=$OCI_TENANCY_OCID" \
  -var="user_ocid=$OCI_USER_OCID" \
  -var="fingerprint=$OCI_FINGERPRINT" \
  -var="private_key_path=$OCI_PRIVATE_KEY_PATH" \
  -var="region=$OCI_REGION" \
  -var="compartment_id=$OCI_COMPARTMENT_ID" \
  -var="availability_domain=$AVAILABILITY_DOMAIN" \
  -var="windows_image_id=ocid1.image.oc1.eu-stockholm-1.aaaaaaaavvubpflzqzb3i3fgw2rj72jsomhxubi4g7mjgp5jdofokqrbkn5q" \
  -var="ssh_public_key=$(cat ~/.ssh/id_rsa.pub)" \
  -var="shape=$SHAPE"

# Get output
section "Deployment Output"
terraform output

echo ""
echo -e "${GREEN}Deployment completed.${NC}"
echo "If successfully deployed, use the IP address above to connect to your Windows VM with SQL Server."
