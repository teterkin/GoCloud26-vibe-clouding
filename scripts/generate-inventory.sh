#!/bin/bash
# Создаёт inventory.ini из terraform output

set -e

echo "=== Генерация inventory.ini ==="

# Проверяем workspace
WORKSPACE=$(terraform workspace show)
echo "Текущий workspace: $WORKSPACE"

# Получаем IP
VM_IP=$(terraform output -raw external_ip)
echo "IP ВМ: $VM_IP"

# SSH ключ (по умолчанию или из параметра)
SSH_KEY="${1:-~/.ssh/id_ed25519}"

# Определяем окружение по workspace
if [ "$WORKSPACE" = "test" ]; then
    ENV_NAME="test"
elif [ "$WORKSPACE" = "prod" ]; then
    ENV_NAME="prod"
else
    echo "Ошибка: неизвестный workspace $WORKSPACE"
    exit 1
fi

# Создаём inventory.ini
cat > ansible/inventory.ini << EOF
[${ENV_NAME}]
${ENV_NAME} ansible_host=${VM_IP} ansible_user=ubuntu ansible_ssh_private_key_file=${SSH_KEY}

[all:vars]
ansible_python_interpreter=/usr/bin/python3
EOF

echo "Создан файл ansible/inventory.ini"
echo ""
echo "Содержимое:"
cat ansible/inventory.ini