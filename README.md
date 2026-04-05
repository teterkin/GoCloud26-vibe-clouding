# Воркшоп: Вайб-кодинг в Terraform

От промпта в нейросети до работающего квиз-приложения в облаке Cloud.ru за 20 минут.

## Цель воркшопа

За 20 минут вы развернёте квиз-приложение в облаке Cloud.ru:
- Сгенерируете Terraform-код с помощью нейросети
- Создадите идентичные test/prod окружения одной командой
- Освоите безопасное изменение инфраструктуры через Git workflow
- Автоматически развернёте приложение без ручной настройки серверов

## Краткий план

| Часть | Время | Что делаем |
|-------|-------|------------|
| 1. Вступление | 2 мин | Знакомство, цели |
| 2. Terraform + AI | 5 мин | Генерируем код нейросетью |
| 3. Test/Prod | 5 мин | Создаём окружения через workspaces |
| 4. GitOps + Ansible | 5 мин | Деплоим, показываем разницу цветов |
| 5. Итоги | 3 мин | Результаты, что дальше |

## Что вы получите

- Навыки IaC (Infrastructure as Code)
- Понимание, как сократить часы ручной работы до 20 минут
- Готовый репозиторий с Terraform-кодом и Ansible-плейбуками
- Знание Git workflow для безопасных изменений инфраструктуры

## Архитектура решения

```
┌─────────────────────────────────────────────────────────────────┐
│                        Cloud.ru Cloud                           │
│                                                                 │
│  ┌─────────────────────────┐     ┌─────────────────────────┐  │
│  │      test ВМ (AZ-1)      │     │      prod ВМ (AZ-1)      │  │
│  │   1 vCPU, 1 GB RAM       │     │   1 vCPU, 1 GB RAM       │  │
│  │                         │     │                         │  │
│  │  ┌───────────────────┐  │     │  ┌───────────────────┐  │  │
│  │  │  Flask App        │  │     │  │  Flask App        │  │  │
│  │  │  + systemd        │  │     │  │  + systemd        │  │  │
│  │  │  + ufw firewall   │  │     │  │  + ufw firewall   │  │  │
│  │  └───────────────────┘  │     │  └───────────────────┘  │  │
│  │         :5000           │     │         :5000           │  │
│  └──────────┬──────────────┘     └──────────┬──────────────┘  │
│             │                               │                  │
│             └───────────────┬───────────────┘                  │
│                             │                                  │
│                     Внешний IP                                  │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                    Git Repository                               │
│                                                                 │
│  main ──────────────────────► prod (prod.tfvars)              │
│    │                                                         │
│    └── feature/change-test-colors ──► test (test.tfvars)      │
│                                                                 │
│  GitOps: изолированные изменения через ветки                   │
└─────────────────────────────────────────────────────────────────┘
```

**Компоненты:**
- **Terraform**: создаёт VPC, подсеть, security groups, VM
- **Ansible**: деплоит Flask-приложение, создаёт systemd-сервис
- **Git**: версионирование, ветки для изолированных изменений
- **Flask**: веб-приложение квиза (без Docker, запускается напрямую)

## Требования для участия

### Обязательно

1. **Личный ноутбук** с SSH-клиентом (терминал macOS/Linux или Putty/Windows Terminal для Windows)
2. **Аккаунт Cloud.ru Free Tier** — бесплатный доступ к облачным ресурсам
   - Регистрация: https://console.cloud.ru
   - Бесплатный лимит: достаточно для тестовых ВМ

3. **Free Tier VM в Cloud.ru** — виртуальная машина, с которой вы будете запускать все команды
   - Создаётся заранее в облаке Cloud.ru
   - Минимальные требования: 1 CPU, 1 GB RAM, Ubuntu 22.04
   - Нужен SSH-доступ к этой ВМ

4. **Terraform** (версия 1.14.0 или выше)
   - Установите Terraform с официального сайта Hashicorp: https://developer.hashicorp.com/terraform/install
   - Если не удается скачать Terraform с сайта Hashicorp, скачайте дистрибутив Terraform из зеркала Cloud.ru: https://cloud.ru/docs/terraform/ug/topics/overview__terraform-download

5. **SSH-ключ** (рекомендуется)
   ```bash
   # Создание SSH-ключа (если нет)
   ssh-keygen -t ed25519 -C "your_email@example.com"
   ```

### Рекомендуется (для продвинутых)

- **Ansible** (для автоматизации приложения)
  ```bash
  # macOS
  brew install ansible

  # Linux
  sudo apt-get install ansible  # Debian/Ubuntu
  sudo yum install ansible      # RHEL/CentOS
  ```
- **opencode** (AI-ассистент для разработки)
  - Установка: https://opencode.ai
- **Git** — для работы с версиями
- **Доступ к нейросети** (ChatGPT, GigaChat, Claude) — для генерации кода

## Подготовка к воркшопу

### 1. Регистрация в Cloud.ru

1. Перейдите на https://console.cloud.ru
2. Создайте аккаунт (или войдите, если есть)
3. Создайте проект, если ещё не создан

### 2. Создание сервисного аккаунта

1. В консоли Cloud.ru перейдите: **Управление доступом → Сервисные аккаунты**
2. Нажмите **Создать сервисный аккаунт**
3. Задайте имя (например, `terraform-deploy`)
4. Назначьте роль **Администратор** или **Участник**
5. Сохраните ID сервисного аккаунта

### 3. Получение ключа доступа

1. В консоли Cloud.ru перейдите: **Управление доступом → Ключи доступа**
2. Нажмите **Создать ключ**
3. Выберите сервисный аккаунт (созданный на шаге 2)
4. Сохраните:
   - `auth_key_id` — ID ключа
   - `auth_secret` — секрет ключа

Подробнее:
- [Создание сервисного аккаунта](https://cloud.ru/docs/console_api/ug/topics/guides__service_accounts_create)
- [Получение ключа доступа](https://cloud.ru/docs/console_api/ug/topics/guides__service_accounts_key)

### 4. Создание Free Tier VM

1. Перейдите в раздел **Compute → Виртуальные машины**
2. Нажмите **Создать ВМ**
3. Выберите:
   - Образ: Ubuntu 22.04
   - Flavor: gen-1-1 (1 CPU, 1 GB RAM)
   - Зона: любая доступная
4. Настройте сеть:
   - Создайте VPC (или используйте существующую)
   - Подсеть с доступом в интернет
5. Добавьте SSH-ключ или пароль
6. После создания сохраните внешний IP адрес

Подробнее:
- https://cloud.ru/docs/virtual-machines/ug/topics/guides__create-free-tier-vm

### 5. Подключение к Free Tier VM

```bash
ssh -i ~/.ssh/id_ed25519 ubuntu@<FREE_TIER_VM_IP>
```

### 6. Клонирование репозитория

```bash
git clone https://github.com:teterkin/GoCloud26-vibe-clouding.git
cd GoCloud26-vibe-clouding
```

## Структура репозитория

```
.
├── terraform.tf          # Основная Terraform-конфигурация
├── variables.tf         # Переменные для настройки
├── test.tfvars          # Переменные для test окружения
├── prod.tfvars          # Переменные для prod окружения
├── secrets.tfvars.example  # Пример файла с секретами
├── ansible/             # Ansible-плейбуки
│   └── playbook.yml     # Развёртывание квиз-приложения
├── quiz-app/            # Исходный код квиз-приложения
│   ├── app.py           # Flask-приложение
│   ├── requirements.txt # Зависимости
│   └── templates/      # HTML-шаблоны
├── SCENARIO.md          # Сценарий воркшопа
├── E2E.md               # Продвинутое руководство (AI-промпты)
└── .gitignore          # Файлы для игнорирования Git
```

## Быстрый старт (упрощённый)

### Шаг 1: Настройка переменных

Скопируйте `secrets.tfvars.example` в `secrets.tfvars` и заполните:

```bash
cp secrets.tfvars.example secrets.tfvars
```

Отредактируйте `secrets.tfvars`:

```hcl
project_id  = "ВАШ_PROJECT_ID"      # см. раздел "Подготовка к воркшопу"
auth_key_id = "ВАШ_AUTH_KEY_ID"     # получили в п. 3
auth_secret = "ВАШ_AUTH_SECRET"     # получили в п. 3
```

**Где взять project_id:** ID проекта указан в консоли Cloud.ru (проекты → выберите проект → ID)

### Шаг 2: Инициализация Terraform

```bash
terraform init
```

### Шаг 3: Создание инфраструктуры

> **Что такое workspaces:** Изолированные состояния (tfstate) для разных окружений. Один код — разные ВМ.

> **⚠️ ВАЖНО:** Перед каждым `terraform apply` обязательно проверяйте текущий workspace командой `terraform workspace show`. Если работаете с test — сначала переключитесь: `terraform workspace select test`. Применение к неправильному workspace может привести к созданию ресурсов в не том окружении или ошибкам "already exists".

```bash
# Тестовое окружение
terraform workspace new test
terraform apply -var-file="secrets.tfvars" -var-file="test.tfvars"

# Продакшн окружение
terraform workspace new prod
terraform apply -var-file="secrets.tfvars" -var-file="prod.tfvars"
```

**Команды для управления:**
```bash
terraform workspace list    # посмотреть все workspaces
terraform workspace show   # какой сейчас активен (ОБЯЗАТЕЛЬНО проверять перед apply!)
terraform workspace select test  # переключиться на test
terraform workspace select prod # переключиться на prod
```

### Шаг 4: Развёртывание приложения

> **⚠️ ВАЖНО:** После создания ВМ Ubuntu выполняет полное обновление дистрибутива. Это занимает **3-5 минут**! Прежде чем подключаться по SSH и устанавливать пакеты через Ansible, обязательно дождитесь завершения обновления. Иначе `apt-get` заблокирует установку пакетов с ошибкой "dpkg lock".

```bash
# Получаем IP ВМ
export VM_IP=$(terraform output -raw external_ip)

# Запускаем Ansible-плейбук
ansible-playbook -i "${VM_IP}," ansible/playbook.yml -u ubuntu --private-key ~/.ssh/id_ed25519 -e app_environment=test
```

### Изменение только test (без prod)

Ключевое преимущество — изолированные изменения:

```bash
# Деплоим только в test — prod не трогаем
ansible-playbook -i "TEST_VM_IP," ansible/playbook.yml \
  -u ubuntu --private-key ~/.ssh/id_ed25519 \
  -e app_environment=test

# Проверяем: test обновился, prod остался прежним
```

## Дополнительные материалы

- [SCENARIO.md](SCENARIO.md) — Полный сценарий воркшопа
- [E2E.md](E2E.md) — Продвинутое руководство с AI-промптами
- [Документация Cloud.ru](https://cloud.ru/docs)
- [Документация Terraform](https://developer.hashicorp.com/terraform)
- [Скачивание Terraform](https://cloud.ru/docs/terraform/ug/topics/overview__terraform-download)

## Поддержка

Возникли вопросы? Обращайтесь к ведущему воркшопа.

---

**Продолжительность воркшопа**: ~20 минут  
**Уровень**: CTO, IT-директора, руководители инфраструктуры и команд разработки
