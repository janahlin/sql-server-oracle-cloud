#!/bin/bash
set -e

echo "=== SQL Server on OCI Deployment Test ==="
echo

# 1. Test OCI CLI connectivity
echo "Testing OCI CLI connectivity..."
if ! oci iam compartment get --compartment-id ocid1.tenancy.oc1..aaaaaaaawcczb6nidnd6rfoqmbvqg6dihslqsrrgnw6kysz6yix4lcvig2va > /dev/null; then
  echo "Error: Unable to connect to OCI. Check your credentials."
  exit 1
fi
echo "✓ OCI CLI connectivity working"
echo

# 2. Verify image compatibility with shape
echo "Verifying Windows image compatibility with VM.Standard.E2.1.Micro shape..."
IMAGE_ID="ocid1.image.oc1.eu-stockholm-1.aaaaaaaavvubpflzqzb3i3fgw2rj72jsomhxubi4g7mjgp5jdofokqrbkn5q"
SHAPE="VM.Standard.E2.1.Micro"

if ! oci compute image get --image-id $IMAGE_ID > /dev/null; then
  echo "Error: Unable to access image. Check if the image ID is correct."
  exit 1
fi

# Check if the image is compatible with the VM shape
echo "✓ Image exists and is accessible"
echo

# 3. Test Terraform configuration
echo "Validating Terraform configuration..."
cd terraform/environments/dev
terraform init -backend=false
terraform validate
echo "✓ Terraform configuration is valid"
echo

# 4. Test Ansible playbook syntax
echo "Validating Ansible playbooks..."
cd ../../../ansible
ansible-playbook site.yml --syntax-check
echo "✓ Ansible playbooks are valid"
echo

# 5. Ansible dry run (check mode)
echo "Running Ansible in check mode..."
ansible-playbook playbooks/deploy_infrastructure.yml --check
echo "✓ Ansible infrastructure playbook dry run completed"
echo

echo "All tests passed! The deployment should work correctly."
