# E2E Руководство: AI-промпты для развёртывания

Это руководство для продвинутых участников воркшопа. Здесь собраны оптимальные промпты для генерации Terraform и Ansible кода через нейросети.

---

## Часть 1: Генерация Terraform-кода для ВМ

### Базовый промпт для ВМ

```
Создай Terraform-код для развёртывания виртуальной машины в облаке Cloud.ru Evolution.

Требования:
1. Используй провайдер cloud.ru с официальным провайдером
2. Создай VPC с именем "quiz-vpc"
3. Создай подсеть с CIDR "192.168.1.0/24"
4. Создай security group с правилами:
   - входящий SSH (порт 22) с моего IP
   - входящий HTTP (порт 80)
   - входящий HTTPS (порт 443)
   - весь исходящий трафик
5. Используй образ Ubuntu 22.04
6. ВМ должна иметь публичный IP
7. Настрой cloud-init для создания пользователя с моим SSH-ключом
8. Выведи external_ip, internal_ip, vm_name

Используй:
- locals для настроек
- переменные для project_id, auth_key_id, auth_secret
- output для вывода информации о ВМ
```

### Продвинутый промпт с workspaces

```
Расширь предыдущий код для поддержки workspaces (test и prod):

1. Добавь переменную environment со значением по умолчанию "test"
2. Создай два файла tfvars:
   - test.tfvars: flavor = "gen-1-1", vm_name = "quiz-test"
   - prod.tfvars: flavor = "gen-2-2", vm_name = "quiz-prod"
3. Используй имена ресурсов с префиксом environment: "${var.environment}-quiz-vm"
4. Настрой разные зоны доступности:
   - test: ru.AZ-1
   - prod: ru.AZ-2
5. Добавь remote backend для хранения state в S3 (или оставь локальным для workshop)

Выведи: external_ip, vm_name, environment, zone
```

### Промпт для модульной структуры

```
Создай модульную структуру Terraform:

modules/
├── vpc/
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── security/
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
└── vm/
    ├── main.tf
    ├── variables.tf
    └── outputs.tf

Главный файл должен использовать эти модули с возможностью выбора environment.

Требования к модулям:
- vpc: создаёт VPC + подсеть
- security: создаёт security group с настраиваемыми правилами
- vm: создаёт ВМ с диском, сетевым интерфейсом, cloud-init
```

---

## Часть 2: Генерация Ansible-плейбука

### Базовый промпт для Flask-приложения

```
Создай Ansible-плейбук для развёртывания Flask-приложения на Ubuntu 22.04.

Требования:
1. Установи Python 3 и pip
2. Установи Flask
3. Создай директорию /opt/quiz-app
4. Скопируй файлы приложения в эту директорию
5. Создай systemd сервис для Flask-приложения
6. Запусти сервис и добавь в автозапуск
7. Открой порт 5000 в ufw
8. Используй переменные для:
   - app_dir (по умолчанию /opt/quiz-app)
   - app_port (по умолчанию 5000)
   - app_user (по умолчанию ubuntu)

Плейбук должен быть идемпотентным (запускаться много раз без ошибок).
```

### Продвинутый промпт с Docker

```
Создай Ansible-плейбук для развёртывания Flask-приложения через Docker.

Требования:
1. Установи Docker
2. Установи Docker Compose
3. Создай файл docker-compose.yml:
   - сервис app на базе python:3.11-slim
   - проброс порта 5000
   - монтирование volume для кода
   - restart policy
4. Создай Dockerfile в приложении
5. Создай systemd сервис для docker-compose
6. Настрой nginx как reverse proxy (опционально)

Используй переменные для версий и путей.
```

### Промпт для полного стека

```
Создай Ansible-плейбук для полного развёртывания стека LAMP/LEMP:
- Linux (Ubuntu 22.04)
- Nginx как reverse proxy
- Python/Flask приложение
- Мониторинг через prometheus node_exporter

Структура:
- roles/
│   ├── common/        # Базовые настройки
│   ├── nginx/         # Nginx конфигурация
│   ├── python/        # Python и Flask
│   └── monitor/       # Мониторинг

Используй handlers для перезапуска сервисов.
```

---

## Часть 3: Промпты для GitOps

### CI/CD Pipeline

```
Создай GitHub Actions workflow для Terraform и Ansible:

1. При pull request:
   - terraform init
   - terraform validate
   - terraform plan -var-file="test.tfvars"
   - ansible-playbook --check (dry-run)

2. При merge в main:
   - terraform apply -var-file="prod.tfvars" -auto-approve
   - ansible-playbook с деплоем на prod

Требования:
- Используй hashicorp/setup-terraform
- Используй ansible/ansible-lint для проверки
- Terraform должен хранить state удалённо
-Secrets храни в GitHub Secrets
```

---

## Часть 4: Примеры готовых промптов

### Комплексный промпт (всё в одном)

```
Создай полную инфраструктуру для квиз-приложения:

Terraform:
- 2 ВМ в разных зонах (test и prod)
- Общий VPC
- Security groups
- Outputs: IP адреса

Ansible:
- Плейбук для установки Flask
- Systemd сервис
- Firewall настройка

Структура файлов:
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── test.tfvars
│   └── prod.tfvars
├── ansible/
│   ├── playbook.yml
│   └── inventory.ini.j2
└── .github/
    └── workflows/
        └── ci.yml

Код должен быть готовым к использованию (production-ready).
```

### Промпт для отладки

```
Мой Terraform код не работает. Ошибка:
[Вставить ошибку]

Проверь код и исправь:
1. Провайдер cloud.ru правильно настроен?
2. Ресурсы создаются в правильном порядке (зависимости)?
3. Переменные определены?
4. Output ссылается на существующий ресурс?

Покажи исправленный код с комментариями.
```

### Промпт для оптимизации

```
Оптимизируй мой Terraform код:

1. Используй модули где нужно
2. Убери дублирование между test и prod
3. Добавь remote backend
4. Используй data source для образа
5. Добавь terraform import для существующих ресурсов

Текущий код:
[Вставить код]

Покажи оптимизированную версию.
```

---

## Часть 5: Рекомендации по промптам

### Что включать в промпт

✓ **Провайдер и версия** — какой облачный провайдер, версия Terraform
✓ **Ресурсы** — какие ресурсы нужны (VPC, VM, SG, etc.)
✓ **Параметры** — размеры, зоны, имена
✓ **Выводы** — какие outputs нужны
✓ **Структура** — модули или один файл

### Что НЕ включать

✗ Секретные данные (вместо этого — переменные)
✗ Слишком много деталей сразу (лучше пошагово)
✗ Код, который вы уже написали (если нужен рефакторинг — укажите)

### Типичные ошибки

1. **Не указан провайдер** — нейросеть может выбрать не тот
2. **Нет зависимостях** — ресурсы создаются не в том порядке
3. **Один файл для всего** — лучше разбить на модули
4. **Hardcoded значения** — используйте переменные

---

## Часть 6: Готовые шаблоны

### Terraform + Ansible шаблон

```
## Terraform часть

# Создай файл main.tf с:
# - провайдер cloud.ru
# - VPC "quiz-vpc"
# - подсеть
# - security group с SSH, HTTP, HTTPS
# - VM с cloud-init
# - outputs: external_ip, internal_ip

## Ansible часть

# Создай playbook.yml с:
# - установка Python
# - установка Flask  
# - создание директории /opt/quiz-app
# - копирование файлов
# - systemd сервис
# - запуск и enable

## Выходные данные

# Покажи команды для применения и деплоя
```

---

## Полезные ссылки

- [Terraform Provider Cloud.ru](https://registry.terraform.io/providers/cloud.ru/cloudru/latest)
- [Ansible Documentation](https://docs.ansible.com/)
- [Cloud.ru API Docs](https://cloud.ru/docs/)
- [NIST Cloud Computing](https://csrc.nist.gov/publications/detail/sp/800-145/final)

---

## Примеры ответов AI

### Пример Terraform (от AI)

```hcl
terraform {
  required_providers {
    cloudru = {
      source = "cloud.ru/cloudru"
      version = "2.0.0"
    }
  }
}

provider "cloudru" {
  project_id  = var.project_id
  auth_key_id = var.auth_key_id
  auth_secret = var.auth_secret
}

resource "cloudru_evolution_vpc_vpc" "vpc" {
  project_id = var.project_id
  name       = "quiz-vpc"
}

# ... остальные ресурсы
```

### Пример Ansible (от AI)

```yaml
---
- name: Deploy Quiz App
  hosts: all
  become: yes
  vars:
    app_dir: /opt/quiz-app
    app_port: 5000

  tasks:
    - name: Install Python and pip
      apt:
        name:
          - python3
          - python3-pip
        state: present
        update_cache: yes

    - name: Install Flask
      pip:
        name: flask
        state: present

    # ... остальные tasks
```
