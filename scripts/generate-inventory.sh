#!/bin/bash
# Создаёт inventory.ini для обоих окружений (test и prod)

set -e

echo "=== Генерация inventory.ini ==="

# SSH ключ (по умолчанию или из параметра)
SSH_KEY="${1:-~/.ssh/id_ed25519}"

# Сохраняем текущий workspace
ORIGINAL_WORKSPACE=$(terraform workspace show)
echo "Исходный workspace: $ORIGINAL_WORKSPACE"

# Получаем IP test VM
terraform workspace select test > /dev/null 2>&1
TEST_IP=$(terraform output -raw external_ip)
echo "test IP: $TEST_IP"

# Получаем IP prod VM
terraform workspace select prod > /dev/null 2>&1
PROD_IP=$(terraform output -raw external_ip)
echo "prod IP: $PROD_IP"

# Возвращаемся в исходный workspace
terraform workspace select "$ORIGINAL_WORKSPACE" > /dev/null 2>&1

# Создаём inventory.ini
cat > ansible/inventory.ini << EOF
[test]
test ansible_host=${TEST_IP} ansible_user=ubuntu ansible_ssh_private_key_file=${SSH_KEY}

[prod]
prod ansible_host=${PROD_IP} ansible_user=ubuntu ansible_ssh_private_key_file=${SSH_KEY}

[all:vars]
ansible_python_interpreter=/usr/bin/python3
EOF

echo ""
echo "Создан файл ansible/inventory.ini"
echo ""
echo "Содержимое:"
cat ansible/inventory.ini
