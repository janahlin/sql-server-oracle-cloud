#!/bin/bash
# Temporarily modify playbook to show the actual error

# Back up the original file
cp ansible/playbooks/deploy_infrastructure.yml ansible/playbooks/deploy_infrastructure.yml.backup

# Remove no_log: true to see the actual error
sed -i 's/no_log: true/no_log: false/' ansible/playbooks/deploy_infrastructure.yml

echo "Modified playbook to show actual error. Run the deployment again:"
echo "./scripts/deploy.sh"
echo
echo "After checking the error, restore the original playbook with:"
echo "mv ansible/playbooks/deploy_infrastructure.yml.backup ansible/playbooks/deploy_infrastructure.yml"
