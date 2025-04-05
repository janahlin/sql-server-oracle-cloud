#!/bin/bash

# Check if variables.tf exists and remove it
if [ -f terraform/modules/windows_vm/variables.tf ]; then
  echo "Removing duplicate variables.tf file"
  rm terraform/modules/windows_vm/variables.tf
fi

echo "Fixed duplicate variable declarations. Try running the deployment again:"
echo "./scripts/deploy.sh" 