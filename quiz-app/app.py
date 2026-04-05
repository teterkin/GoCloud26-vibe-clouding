from flask import Flask, render_template, request, session, redirect, url_for
import random
import os

app = Flask(__name__)
app.secret_key = os.environ.get('APP_SECRET_KEY', 'cloud-computing-quiz-2024')

app.config['STATIC_FOLDER'] = 'static'

app_env = os.environ.get('APP_ENV', 'test')

QUESTIONS = [
    {
        "id": 1,
        "question": "Что такое Cloud Computing (облачные вычисления) по определению NIST?",
        "options": [
            "Локальный хостинг на собственных серверах компании",
            "Модель обеспечения удобного сетевого доступа по требованию к общему пулу вычислительных ресурсов",
            "Технология передачи данных через спутниковую связь",
            "Аутсорсинг IT-услуг в другую компанию"
        ],
        "correct": 1,
        "explanation": "По NIST: облачные вычисления — это модель обеспечения удобного сетевого доступа по требованию к общему пулу вычислительных ресурсов (сети, серверы, хранилища, приложения, сервисы)."
    },
    {
        "id": 2,
        "question": "Какие пять основных характеристик облачных вычислений определены NIST?",
        "options": [
            "Виртуализация, контейнеризация, микросервисы, API, DevOps",
            "Самообслуживание по требованию, универсальный сетевой доступ, пулирование ресурсов, эластичность, измеряемость услуг",
            "IaaS, PaaS, SaaS, DaaS, FaaS",
            "SSH доступ, VPN туннелирование, резервное копирование, мониторинг, логирование"
        ],
        "correct": 1,
        "explanation": "NIST определяет 5 essential characteristics: Self-service on demand, Broad network access, Resource pooling, Rapid elasticity, Measured service."
    },
    {
        "id": 3,
        "question": "Что означает модель развёртывания 'Private Cloud' (частное облако)?",
        "options": [
            "Облако, доступное всем желающим без ограничений",
            "Облачная инфраструктура, предназначенная для использования одной организацией",
            "Облако, размещённое у третьего провайдера",
            "Локальный сервер без доступа к интернету"
        ],
        "correct": 1,
        "explanation": "Private cloud — облачная инфраструктура, предназначенная для использования одной организацией (или несколькими, но с общими требованиями безопасности)."
    },
    {
        "id": 4,
        "question": "Какие три основные модели обслуживания (service models) в облачных вычислениях?",
        "options": [
            "Basic, Standard, Premium",
            "IaaS, PaaS, SaaS",
            "Public, Private, Hybrid",
            "Compute, Storage, Network"
        ],
        "correct": 1,
        "explanation": "Три основные модели: IaaS (Infrastructure as a Service), PaaS (Platform as a Service), SaaS (Software as a Service)."
    },
    {
        "id": 5,
        "question": "Что такое 'Public Cloud' (публичное облако)?",
        "options": [
            "Облако, доступное только госструктурам",
            "Облачная инфраструктура, доступная для широкой публики",
            "Облако, размещённое в открытых дата-центрах",
            "Общедоступные API сервисы"
        ],
        "correct": 1,
        "explanation": "Public cloud — облачная инфраструктура, доступная для широкой публики или большой промышленной группы и принадлежащая провайдеру облачных услуг."
    },
    {
        "id": 6,
        "question": "Что характеризует 'Hybrid Cloud' (гибридное облако)?",
        "options": [
            "Использование только двух облачных провайдеров",
            "Комбинация двух или более различных облачных инфраструктур, остающихся уникальными сущностями",
            "Облако с двумя типами виртуализации",
            "Миграция данных между ЦОД"
        ],
        "correct": 1,
        "explanation": "Hybrid cloud — комбинация двух или более различных облачных инфраструктур (public, private или community), объединённых технологиями, позволяющими переносить данные и приложения."
    },
    {
        "id": 7,
        "question": "В чём ключевое преимущество 'SaaS' (Software as a Service)?",
        "options": [
            "Полный контроль над инфраструктурой",
            "Пользователь получает доступ к приложениям через интернет без необходимости их установки и обслуживания",
            "Максимальная кастомизация кода",
            "Отсутствие затрат на лицензии"
        ],
        "correct": 1,
        "explanation": "SaaS предоставляет приложения через интернет — пользователю не нужно устанавливать, обслуживать или обновлять ПО. Примеры: Gmail, Salesforce, Microsoft 365."
    },
    {
        "id": 8,
        "question": "Что такое 'Community Cloud' (облако сообщества)?",
        "options": [
            "Облако, созданное волонтёрами",
            "Облачная инфраструктура, предназначенная для использования конкретным сообществом потребителей",
            "Публичное облако с открытым исходным кодом",
            "Облако для разработки open-source проектов"
        ],
        "correct": 1,
        "explanation": "Community cloud — облачная инфраструктура, предназначенная для использования конкретным сообществом потребителей (например, госструктуры, медицинские организации)."
    },
    {
        "id": 9,
        "question": "Что означает 'Resource Pooling' (пулирование ресурсов)?",
        "options": [
            "Фиксированное распределение ресурсов для каждого пользователя",
            "Провайдер объединяет физические и виртуальные ресурсы для обслуживания множества клиентов",
            "Создание резервных копий ресурсов",
            "Ограничение использования ресурсов"
        ],
        "correct": 1,
        "explanation": "Resource pooling — провайдер объединяет физические и виртуальные ресурсы в пул для динамического распределения между потребителями согласно их потребностям."
    },
    {
        "id": 10,
        "question": "Что такое 'Elasticity' (эластичность) в контексте облачных вычислений?",
        "options": [
            "Способность автоматически увеличивать и уменьшать ресурсы по требованию",
            "Устойчивость к высоким нагрузкам",
            "Гибкость в выборе провайдера",
            "Возможность масштабирования только вверх"
        ],
        "correct": 0,
        "explanation": "Elasticity — способность быстро увеличивать или уменьшать ресурсы (масштабировать) в соответствии с потребностями, часто автоматически."
    }
]

@app.route('/')
def index():
    session.clear()
    return render_template('index.html', app_env=app_env)

@app.route('/quiz')
def quiz():
    if 'questions' not in session:
        session['questions'] = random.sample(QUESTIONS, min(5, len(QUESTIONS)))
        session['current'] = 0
        session['score'] = 0
    
    if session['current'] >= len(session['questions']):
        return redirect(url_for('result'))
    
    q = session['questions'][session['current']]
    return render_template('quiz.html', question=q, current=session['current'] + 1, total=len(session['questions']), app_env=app_env)

@app.route('/answer', methods=['POST'])
def answer():
    if 'questions' not in session:
        return redirect(url_for('index'))
    
    selected = int(request.form.get('answer', -1))
    q = session['questions'][session['current']]
    
    correct = (selected == q['correct'])
    if correct:
        session['score'] = session.get('score', 0) + 1
    
    session['current'] = session.get('current', 0) + 1
    is_last = session['current'] >= len(session['questions'])
    
    return render_template('answer.html', 
                         question=q, 
                         selected=selected, 
                         correct=correct,
                         current=session['current'],
                         total=len(session['questions']),
                         is_last=is_last,
                         app_env=app_env)

@app.route('/result')
def result():
    score = session.get('score', 0)
    total = len(session.get('questions', []))
    
    percentage = (score / total * 100) if total > 0 else 0
    
    if percentage >= 80:
        message = "Отлично! Вы отлично разбираетесь в облачных вычислениях!"
    elif percentage >= 60:
        message = "Хорошо! У вас хорошие знания основ облачных технологий."
    else:
        message = "Продолжайте изучать облачные технологии. Скоро у вас всё получится!"
    
    return render_template('result.html', 
                         score=score, 
                         total=total, 
                         percentage=percentage,
                         message=message,
                         app_env=app_env)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
