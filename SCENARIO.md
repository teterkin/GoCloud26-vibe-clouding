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

> **Что такое workspaces:** Изолированные состояния (tfstate) для разных окружений. Один код — разные ВМ.

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

```
1. Создаём branch    → feature/add-colors
2. Изменяем код      → ansible playbook
3. Git commit + push → Review в PR
4. Merge             → CI/CD деплоит в prod
```

#### Различия test и prod:

| Параметр | test | prod |
|----------|------|------|
| Цвета (одинаковые) | Зелёные (#11998e) | Зелёные (#11998e) |
| Flavor | gen-1-1 (1 vCPU, 1 GB RAM) | gen-1-1 (1 vCPU, 1 GB RAM) |

### Как открыть приложение

После деплоя откройте в браузере:
- **test**: `http://<TEST_VM_IP>:5000`
- **prod**: `http://<PROD_VM_IP>:5000`

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

**Шаг 3: Меняем цвет в HTML-файлах**

Цвета задаются в CSS переменных в каждом шаблоне. Основные файлы:
- `quiz-app/templates/index.html` — главная страница
- `quiz-app/templates/quiz.html` — страница вопроса
- `quiz-app/templates/answer.html` — результат ответа
- `quiz-app/templates/result.html` — итоговый результат

В каждом файле есть блок `.env-badge` с цветами:
```css
{% if app_env == 'prod' %}
background: #B91C1C;  /* красный для PROD */
color: #FFFFFF;
{% else %}
background: #1D4ED8;  /* синий для TEST */
color: #FFFFFF;
{% endif %}
```

Также градиент body можно изменить:
- Зелёный: `#11998e → #38ef7d`
- Фиолетовый: `#667eea → #764ba2`
- Тёмно-красный: `#1a1a2e → #16213e`

```bash
# Пример: меняем на фиолетовый
vim quiz-app/templates/index.html
# Найти: background: linear-gradient(135deg, #11998e
# Заменить на: background: linear-gradient(135deg, #667eea
```

**Шаг 4: Смотрим diff — видим что изменилось**
```bash
# Показать изменения в файлах
git diff

# Показать изменения конкретного файла
git diff quiz-app/templates/index.html
```

**Шаг 5: Коммитим изменения**
```bash
git add quiz-app/templates/
git commit -m "Change test colors to purple"
```

**Шаг 6: Деплоим только в test (prod не трогаем)**
```bash
# Важно: сначала проверим текущий workspace!
terraform workspace show

# Деплоим в test
ansible-playbook -i "TEST_VM_IP," ansible/playbook.yml \
  -u ubuntu --private-key ~/.ssh/id_ed25519 \
  -e app_environment=test
```

**Шаг 7: Проверяем результат**
- **test**: изменился на фиолетовый (#667eea)
- **prod**: остался зелёным (#11998e) — без изменений

Откройте оба URL в браузере — видим разницу! Это и есть GitOps в действии.

### Как это работает

1. **Ansible получает environment** из переменной
2. **Flask-приложение** читает `APP_ENV` 
3. **Шаблоны Jinja2** рендерят разные цвета

### Демонстрация

Ведущий показывает:
1. Открыть test ВМ в браузере — фиолетовые цвета
2. Открыть prod ВМ в браузере — тёмно-красные цвета
3. Показать разницу визуально

### Команды для деплоя

> **⚠️ ВАЖНО:** После создания ВМ Ubuntu выполняет полное обновление дистрибутива. Это занимает **3-5 минут**! Прежде чем подключаться по SSH и устанавливать пакеты через Ansible, обязательно дождитесь завершения обновления. Иначе `apt-get` заблокирует установку пакетов с ошибкой "dpkg lock".

```bash
# Деплой в test
ansible-playbook -i "<TEST_VM_IP>," ansible/playbook.yml \
  -u ubuntu --private-key ~/.ssh/id_ed25519 \
  -e app_environment=test

# Деплой в prod  
ansible-playbook -i "<PROD_VM_IP>," ansible/playbook.yml \
  -u ubuntu --private-key ~/.ssh/id_ed25519 \
  -e app_environment=prod
```

### Демонстрация GitOps: изменение test без prod

Покажем главное преимущество GitOps — **изолированные изменения**:

1. Меняем код приложения (например, добавляем новый вопрос в квиз)
2. Деплоим **только в test**:
   ```bash
   ansible-playbook -i "<TEST_VM_IP>," ansible/playbook.yml \
     -u ubuntu --private-key ~/.ssh/id_ed25519 \
     -e app_environment=test
   ```
3. Проверяем — test обновился, prod остался прежним
4. Убеждаемся: открываем оба URL — изменения только в test

Это ключевой момент: мы можем безопасно экспериментировать в test, не затрагивая prod.

---

## Часть 4: Полный цикл (5 минут)

> **Что такое workspaces:** Изолированные состояния (tfstate) для разных окружений. Один код — разные ВМ.

### Запуск всех команд

```bash
# 1. Создаём обе ВМ
terraform workspace new test
terraform apply -var-file="secrets.tfvars" -var-file="test.tfvars"

terraform workspace new prod
terraform apply -var-file="secrets.tfvars" -var-file="prod.tfvars"

# 2. Получаем IP адреса
TEST_IP=$(terraform workspace show test && terraform output -raw external_ip)
PROD_IP=$(terraform workspace show prod && terraform output -raw external_ip)

# 3. Деплой в test
ansible-playbook -i "${TEST_IP}," ansible/playbook.yml \
  -u ubuntu --private-key ~/.ssh/id_ed25519 -e environment=test

# 4. Деплой в prod
ansible-playbook -i "${PROD_IP}," ansible/playbook.yml \
  -u ubuntu --private-key ~/.ssh/id_ed25519 -e environment=prod
```

### Результат

- **test ВМ**: http://<test_ip>:5000 — фиолетовый квиз
- **prod ВМ**: http://<prod_ip>:5000 — тёмно-красный квиз

Визуально различимы!

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

> **Что такое workspaces:** Изолированные состояния (tfstate) для разных окружений. Один код — разные ВМ.

```bash
# Клонирование репозитория
git clone https://github.com:teterkin/GoCloud26-vibe-clouding.git
cd GoCloud26-vibe-clouding

# Настройка
cp secrets.tfvars.example secrets.tfvars
# Редактирование secrets.tfvars

# Создание инфраструктуры
terraform init
terraform workspace new test
terraform apply -var-file="secrets.tfvars" -var-file="test.tfvars"

# Деплой приложения
TEST_IP=$(terraform output -raw external_ip)
ansible-playbook -i "${TEST_IP}," ansible/playbook.yml \
  -u ubuntu -e environment=test

# Проверка
open http://${TEST_IP}:5000
```

### B. Troubleshooting

| Проблема | Решение |
|----------|----------|
| Terraform не инициализируется | Проверьте `terraform.tf` и провайдер |
| Не подключается по SSH | Проверьте security group и IP |
| Ansible не работает | Проверьте доступ по ключу: `ssh -i ~/.ssh/id_ed25519 ubuntu@IP` |
| Приложение не запускается | Проверьте логи: `journalctl -u quiz-app -n 50` |
| Цвета не меняются | Проверьте APP_ENV: `echo $APP_ENV` |
| Не работает деплой | Проверьте переменную environment: `ansible ... -e environment=test` |

### C. Различия test и prod

```
TEST:
- Фиолетовый gradient: #667eea → #764ba2  
- Light mode стиль

PROD:  
- Тёмный gradient: #1a1a2e → #16213e
- Красные акценты: #e94560
- Dark mode стиль
```

### D. Контакты

- Cloud.ru: https://console.cloud.ru
- Terraform: https://developer.hashicorp.com/terraform
- Ansible: https://docs.ansible.com
