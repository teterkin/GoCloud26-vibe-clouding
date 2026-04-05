# Сценарий воркшопа: Вайб-кодинг в Terraform

## Вступление (2 минуты)

**Ведущий**: "Добро пожаловать на воркшоп! За следующие 20 минут мы развернём квиз-приложение в облаке Cloud.ru — от промпта в нейросети до работающего приложения."

**Цели воркшопа:**
- Сгенерировать Terraform-код с помощью нейросети
- Создать идентичные test/prod окружения одной командой
- Освоить безопасное изменение конфигурации через Git workflow с Ansible
- Автоматически развернуть приложение без ручной настройки серверов

---

## Часть 1: Генерация Terraform-кода нейросетью (5 минут)

### Что делает ведущий

1. **Открывает нейросеть** (ChatGPT/GigaChat/Claude)
2. **Показывает промпт**:

```
Создай Terraform-код для развёртывания ВМ в облаке Cloud.ru Evolution:
- Провайдер: cloud.ru с endpoint api.cloud.ru
- Проект: использовать переменные
- VPC с подсетью
- Security group с правилами для SSH (22) и HTTP (80/443/5000)
- Ubuntu 22.04 ВМ с минимальными ресурсами
- Output: IP адрес, имя ВМ
- Используй locals для настроек
```

3. **Демонстрирует результат** — готовый `.tf` файл

### Что делают участники

- Наблюдают процесс генерации
- Записывают ключевые моменты промптинга

---

## Часть 2: Создание test/prod окружений (5 минут)

### Архитектура с workspaces

```
terraform/
├── terraform.tf           # Основная конфигурация
├── variables.tf           # Переменные
├── test.tfvars            # Настройки тестового
├── prod.tfvars            # Настройки продакшн
└── secrets.tfvars         # Секреты (не в git)
```

### Настройка переменных

**test.tfvars:**
```hcl
environment = "test"
vm_name      = "quiz-test"
flavor       = "gen-1-1"
zone         = "ru.AZ-1"
```

**prod.tfvars:**
```hcl
environment = "prod"
vm_name      = "quiz-prod"
flavor       = "gen-1-1"
zone         = "ru.AZ-1"
```

### Команды для создания окружений

> **Что такое workspaces:** Изолированные состояния (tfstate) для разных окружений. Один код — разные ВМ. State хранится локально в директории `terraform.tfstate.d/` (test/ и prod/ поддиректории).

> **⚠️ ВАЖНО:** Перед каждым `terraform apply` обязательно проверяйте текущий workspace командой `terraform workspace show`. Если работаете с test — сначала переключитесь: `terraform workspace select test`. Применение к неправильному workspace может привести к созданию ресурсов в не том окружении или ошибкам "already exists".

```bash
# 1. Инициализация
terraform init

# 2. Тестовое окружение
terraform workspace new test
terraform apply -var-file="test.tfvars" -var-file="secrets.tfvars"

# 3. Продакшн окружение
terraform workspace new prod  
terraform apply -var-file="prod.tfvars" -var-file="secrets.tfvars"

# 4. Переключение между окружениями
terraform workspace select test
terraform workspace select prod
```

**Команды для управления:**
```bash
terraform workspace list    # посмотреть все workspaces
terraform workspace show   # какой сейчас активен (ОБЯЗАТЕЛЬНО проверять перед apply!)
terraform workspace select test  # переключиться на test
terraform workspace select prod # переключиться на prod
```

### Деплой приложения

> **⚠️ ВАЖНО:** После создания ВМ Ubuntu выполняет полное обновление дистрибутива. Это занимает **3-5 минут**! Прежде чем подключаться по SSH и устанавливать пакеты через Ansible, обязательно дождитесь завершения обновления.

```bash
# Переключаемся на test и проверяем
terraform workspace select test
terraform workspace show  # должно показать: test

# Получаем IP test VM
terraform output external_ip  # проверим, что это test

# Сохраняем IP в переменную
TEST_IP=$(terraform output -raw external_ip)

# Деплой в test
ansible-playbook -i "${TEST_IP}," ansible/playbook.yml \
  -u ubuntu --private-key ~/.ssh/id_ed25519 \
  -e app_environment=test
```

```bash
# Переключаемся на prod и проверяем
terraform workspace select prod
terraform workspace show  # должно показать: prod

# Получаем IP prod VM
terraform output external_ip  # проверим, что это prod

# Сохраняем IP в переменную
PROD_IP=$(terraform output -raw external_ip)

# Деплой в prod
ansible-playbook -i "${PROD_IP}," ansible/playbook.yml \
  -u ubuntu --private-key ~/.ssh/id_ed25519 \
  -e app_environment=prod
```

### Результат

- **test**: `test-quiz-vm` — 1 CPU, 1 GB RAM
- **prod**: `prod-quiz-vm` — 1 vCPU, 1 GB RAM

Обе ВМ идентичной структуры и размера (gen-1-1: 1 vCPU, 1 GB RAM).

---

## Часть 3: Git workflow с Ansible (5 минут)

### Проблема

Ручные изменения на серверах — это хаос:
- Кто что изменил — непонятно
- Откат занимает часы
- Нет аудита

### Решение: GitOps с Ansible

#### Workflow:

**На воркшопе (упрощённо):**
```
1. Создаём branch    → feature/change-test-colors
2. Меняем CSS        → quiz-app/static/style.css
3. Git commit        → локально
4. Ansible деплой    → только в test
```

**В реальной жизни:**
```
1. Создаём branch    → feature/change-test-colors
2. Меняем код        → quiz-app/static/style.css
3. Git commit + push → Review в PR
4. Merge             → CI/CD деплоит в test
5. Проверка         → тестирование в test
6. CI/CD деплой     → в prod
```

#### Различия test и prod:

| Параметр | test | prod |
|----------|------|------|
| Цвета (одинаковые) | Зелёные (#11998e → #38ef7d) | Зелёные (#11998e → #38ef7d) |
| Flavor | gen-1-1 (1 vCPU, 1 GB RAM) | gen-1-1 (1 vCPU, 1 GB RAM) |

### Как открыть приложение

После деплоя откройте в браузере:
- **test**: `http://<TEST_VM_IP>:5000` — зелёный квиз
- **prod**: `http://<PROD_VM_IP>:5000` — зелёный квиз (пока цвета одинаковые)

IP ВМ можно получить:
```bash
terraform workspace select test
terraform output external_ip

terraform workspace select prod  
terraform output external_ip
```

### Демонстрация: GitOps — изменение только test

Покажем главное преимущество GitOps — **изолированные изменения**:

**Шаг 1: Изначально цвета одинаковые**
- test: зелёные (#11998e → #38ef7d)
- prod: зелёные (#11998e → #38ef7d)

**Шаг 2: Создаём ветку для изменения test**
```bash
# Переключаемся на main
git checkout main

# Создаём ветку для изменения цветов (или используем существующую)
git checkout -b feature/change-test-colors

# Если ветка уже существует:
# git checkout feature/change-test-colors
```

**Шаг 3: Меняем цвет в CSS-файле**

Основной CSS файл: `quiz-app/static/style.css`

Сейчас цвета зелёные: `#11998e → #38ef7d`

Поменяйте 2 цвета зелёного градиента на 2 цвета фиолетового:
- Было: `#11998e → #38ef7d`
- Стало: `#667eea → #764ba2`

```bash
vim quiz-app/static/style.css
# Замените #11998e на #667eea
# Замените #38ef7d на #764ba2
```

**Шаг 4: Смотрим diff — видим что изменилось**
```bash
git diff

# Показать изменения конкретного файла
git diff quiz-app/static/style.css
```

**Шаг 5: Коммитим изменения**
```bash
git add quiz-app/
git commit -m "Change test colors to purple"
```

**Шаг 6: Деплоим только в test (prod не трогаем)**

> **⚠️ ВАЖНО:** После создания ВМ Ubuntu выполняет полное обновление дистрибутива. Это занимает **3-5 минут**! Прежде чем подключаться по SSH и устанавливать пакеты через Ansible, обязательно дождитесь завершения обновления.

```bash
# Получаем IP test VM
terraform workspace select test
TEST_VM_IP=$(terraform output -raw external_ip)
echo $TEST_VM_IP

# Деплоим в test
ansible-playbook -i "${TEST_VM_IP}," ansible/playbook.yml \
  -u ubuntu --private-key ~/.ssh/id_ed25519 \
  -e app_environment=test
```

**Шаг 7: Проверяем результат**
- **test**: http://<TEST_VM_IP>:5000 — изменился на фиолетовый (#667eea)
- **prod**: http://<PROD_VM_IP>:5000 — остался зелёным (#11998e → #38ef7d) — без изменений

Откройте оба URL в браузере — видим разницу! Это и есть GitOps в действии.

### Как это работает

Цвета приложения задаются в двух местах:

1. **В CSS файле (`quiz-app/static/style.css`)** — общие стили для всех окружений:
   - Градиент фона `body`
   - Градиент кнопок `.btn`
   - Градиент прогресс-бара `.progress-bar`
   - Градиент круга результатов `.score-circle`
   
   Это статические цвета — одинаковые для test и prod.

2. **В HTML шаблонах** — цвета badge (плашки) с надписью TEST/PROD:
   - TEST: синий фон (#1D4ED8), белый текст
   - PROD: красный фон (#B91C1C), белый текст
   
   Эти цвета динамические — определяются переменной `app_env` через Jinja2.

**Workflow:**
1. Ansible получает `app_environment` из переменной
2. Передаёт в Flask через переменную окружения `APP_ENV`
3. Flask рендерит шаблоны с `app_env` →  badge: TEST или PROD
4. Общие CSS стили применяются ко всем окружениям одинаково

---

## Завершение (3 минуты)

### Итоги

Участники научились:
1. ✓ Генерировать Terraform-код через AI
2. ✓ Создавать идентичные окружения через workspaces
3. ✓ Управлять конфигурацией через Git + Ansible
4. ✓ Развёртывать приложения с разными environments
5. ✓ Визуально различать test и prod

### Результат

**За 20 минут** вместо ручной настройки (2-4 часа) участники получили:
- Две готовые ВМ (test + prod)
- Работающее квиз-приложение с разными цветами
- Понимание полного цикла IaC + GitOps

### Что дальше

- [E2E.md](E2E.md) — Продвинутое руководство с промптами
- [Документация Cloud.ru](https://cloud.ru/docs)
- [Документация Terraform](https://developer.hashicorp.com/terraform)
- [Документация Ansible](https://docs.ansible.com)

---

## Приложения

### A. Команды для быстрого старта

```bash
# 1. Подготовка
git clone <REPO_URL>
cd <REPO_NAME>
cp secrets.tfvars.example secrets.tfvars
# 编辑 secrets.tfvars: project_id, auth_key_id, auth_secret

# 2. Terraform
terraform init
terraform workspace new test
terraform apply -var-file="secrets.tfvars" -var-file="test.tfvars"
terraform workspace new prod
terraform apply -var-file="secrets.tfvars" -var-file="prod.tfvars"

# 3. Деплой в test
terraform workspace select test
terraform workspace show  # проверить: test
TEST_IP=$(terraform output -raw external_ip)
ansible-playbook -i "${TEST_IP}," ansible/playbook.yml \
  -u ubuntu --private-key ~/.ssh/id_ed25519 -e app_environment=test

# 4. Деплой в prod
terraform workspace select prod
terraform workspace show  # проверить: prod
PROD_IP=$(terraform output -raw external_ip)
ansible-playbook -i "${PROD_IP}," ansible/playbook.yml \
  -u ubuntu --private-key ~/.ssh/id_ed25519 -e app_environment=prod

# 5. Проверка
open http://${TEST_IP}:5000  # test
open http://${PROD_IP}:5000  # prod
```

### B. Troubleshooting

| Проблема | Решение |
|----------|----------|
| Terraform не инициализируется | Проверьте `terraform.tf` и провайдер |
| Не подключается по SSH | Проверьте security group и IP |
| Ansible не работает | Проверьте доступ по ключу: `ssh -i ~/.ssh/id_ed25519 ubuntu@IP` |
| Приложение не запускается | Проверьте логи: `journalctl -u quiz-app -n 50` |
| Цвета не меняются | Проверьте APP_ENV: `echo $APP_ENV` |
| Не работает деплой | Проверьте переменную app_environment: `ansible ... -e app_environment=test` |
