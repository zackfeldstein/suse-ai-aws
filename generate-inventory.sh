#!/bin/bash

# Generate Ansible inventory from Terraform outputs
echo "Generating Ansible inventory from Terraform outputs..."

# Get Terraform outputs
terraform output -raw ansible_inventory > ansible/inventory.ini

# Get Ansible variables
terraform output -json ansible_vars > ansible/group_vars/terraform_vars.json

# Convert JSON to YAML for easier reading
cat ansible/group_vars/terraform_vars.json | python3 -c "
import sys, yaml, json
try:
    data = json.load(sys.stdin)
    yaml.dump(data, sys.stdout, default_flow_style=False)
except Exception as e:
    print(f'Error: {e}', file=sys.stderr)
    sys.exit(1)
" > ansible/group_vars/terraform_vars.yml 2>/dev/null || echo "Note: Could not convert JSON to YAML (python3-yaml not installed)"

echo "Generated files:"
echo "  - ansible/inventory.ini"
echo "  - ansible/group_vars/terraform_vars.json"
echo "  - ansible/group_vars/terraform_vars.yml (if python3-yaml available)"

echo ""
echo "Inventory contents:"
cat ansible/inventory.ini

echo ""
echo "You can now run Ansible playbooks with:"
echo "  cd ansible"
echo "  ansible-playbook -i inventory.ini site.yml"
echo ""
echo "Note: This setup uses only built-in Ansible modules - no galaxy collections needed!"
