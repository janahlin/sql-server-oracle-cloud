#!/bin/bash
# Script to modify deploy_infrastructure.yml for debugging

# Back up the original file
cp ansible/playbooks/deploy_infrastructure.yml ansible/playbooks/deploy_infrastructure.yml.bak

# Remove the no_log option to see the actual error
sed -i 's/no_log: true/no_log: false/' ansible/playbooks/deploy_infrastructure.yml

echo "Modified deployment playbook to show actual errors."
echo "Run ansible-playbook again with:"
echo "cd ansible && ansible-playbook site.yml"
echo ""
echo "Once you've resolved the issue, restore the original file with:"
echo "mv ansible/playbooks/deploy_infrastructure.yml.bak ansible/playbooks/deploy_infrastructure.yml" 