#!/bin/bash

echo "Testing Ansible setup (local playbooks only)..."

# Check if Ansible is installed
if ! command -v ansible &> /dev/null; then
    echo "❌ Ansible is not installed. Please install it first:"
    echo "   brew install ansible (macOS)"
    echo "   sudo apt install ansible (Ubuntu/Debian)"
    echo "   sudo yum install ansible (RHEL/CentOS)"
    exit 1
fi

echo "✅ Ansible is installed: $(ansible --version | head -1)"

# Check if inventory exists
if [ ! -f "ansible/inventory.ini" ]; then
    echo "❌ Inventory file not found. Run './generate-inventory.sh' first."
    exit 1
fi

echo "✅ Inventory file exists"

# Test syntax of all playbooks
echo "🔍 Testing playbook syntax..."

cd ansible

# Test main playbook
if ansible-playbook --syntax-check -i inventory.ini site.yml; then
    echo "✅ Main playbook syntax is valid"
else
    echo "❌ Main playbook syntax error"
    exit 1
fi

# Test individual playbooks
for playbook in playbooks/*.yml; do
    if [ -f "$playbook" ]; then
        echo "  Testing $(basename $playbook)..."
        if ansible-playbook --syntax-check "$playbook"; then
            echo "  ✅ $(basename $playbook) syntax is valid"
        else
            echo "  ❌ $(basename $playbook) syntax error"
            exit 1
        fi
    fi
done

echo ""
echo "🎉 All playbooks are syntactically correct!"
echo ""
echo "Next steps:"
echo "1. Test connectivity: ansible -i inventory.ini all -m ping"
echo "2. Run playbooks: ansible-playbook -i inventory.ini site.yml"
echo ""
echo "Note: No ansible-galaxy collections needed - everything uses built-in modules!"

