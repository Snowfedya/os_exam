# os_exam
> Простое REST API приложение на Spring Boot для демонстрации навыков администрирования Linux систем

## 📖 Описание проекта

**Simple Web Application** - это демонстрационное REST API приложение, созданное для зачёта по администрированию операционных систем. Приложение реализует полноценный веб-сервис с управлением продуктами и пользователями, развёрнутый на Linux сервере с использованием современного стека технологий.

### Основные возможности

- ✅ **REST API** с полным CRUD функционалом
- ✅ **Health Check** система для мониторинга
- ✅ **Валидация данных** с помощью Bean Validation
- ✅ **Управление продуктами** (создание, чтение, обновление, удаление)
- ✅ **Управление пользователями** с валидацией email
- ✅ **In-memory хранение** данных для демонстрации
- ✅ **Systemd интеграция** для управления службой
- ✅ **Nginx reverse proxy** для production развертывания

## 🏗️ Архитектура

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│     Client      │───▶│   Nginx (80)    │───▶│ Spring Boot App │
│   (Browser/     │    │ Reverse Proxy   │    │     (5000)      │
│    curl/etc)    │    └─────────────────┘    └─────────────────┘
└─────────────────┘                                      │
                                                         ▼
                                              ┌─────────────────┐
                                              │   In-Memory     │
                                              │   Data Store    │
                                              └─────────────────┘
```

### Слоистая архитектура приложения

```
┌─────────────────────────────────────────────────────────────┐
│                    Controller Layer                         │
│          (REST Endpoints, HTTP Processing)                  │
├─────────────────────────────────────────────────────────────┤
│                     Service Layer                           │
│             (Business Logic, Data Validation)               │
├─────────────────────────────────────────────────────────────┤
│                     Model Layer                             │
│                (Data Models, Entities)                      │
└─────────────────────────────────────────────────────────────┘
```

## 🛠️ Технологии

| Компонент | Технология | Версия | Назначение |
|-----------|------------|---------|------------|
| **Backend** | Java | 11 | Основной язык программирования |
| **Framework** | Spring Boot | 2.7.0 | Веб-фреймворк и DI контейнер |
| **Build Tool** | Maven | 3.6+ | Сборка и управление зависимостями |
| **Web Server** | Embedded Tomcat | 9.x | Встроенный веб-сервер |
| **Reverse Proxy** | Nginx | 1.18+ | Reverse proxy и load balancer |
| **OS** | Ubuntu Linux | 20.04+ | Операционная система |
| **Process Manager** | systemd | - | Управление жизненным циклом приложения |
| **Validation** | Hibernate Validator | 6.x | Валидация данных |
| **Monitoring** | Spring Actuator | 2.7.0 | Health checks и метрики |

## 📁 Структура проекта

```
simple-web-app/
├── src/
│   ├── main/
│   │   ├── java/com/example/
│   │   │   ├── Application.java                 # 🚀 Главный класс приложения
│   │   │   ├── controller/                      # 🎮 REST API контроллеры
│   │   │   │   ├── HealthController.java        # ❤️ Health check endpoints
│   │   │   │   ├── ProductController.java       # 📦 Products API
│   │   │   │   └── UserController.java          # 👤 Users API
│   │   │   ├── service/                         # ⚙️ Бизнес-логика
│   │   │   │   ├── ProductService.java          # 📦 Сервис продуктов
│   │   │   │   └── UserService.java             # 👤 Сервис пользователей
│   │   │   └── model/                           # 🗃️ Модели данных
│   │   │       ├── Product.java                 # 📦 Модель продукта
│   │   │       └── User.java                    # 👤 Модель пользователя
│   │   └── resources/
│   │       └── application.properties           # ⚙️ Конфигурация приложения
│   └── test/                                    # 🧪 Тесты (будущие)
├── target/                                      # 📦 Собранные артефакты
├── pom.xml                                      # 📋 Maven конфигурация
└── README.md                                    # 📖 Этот файл
```

## 🚀 Установка и запуск

### Автоматическая установка

Используйте предоставленный bash скрипт для полной автоматической установки:

```bash
# Скачайте и запустите скрипт развертывания
chmod +x deploy-local.sh
sudo ./deploy-local.sh
```

### Ручная установка

#### Предварительные требования

```bash
# Обновление системы
sudo apt update && sudo apt upgrade -y

# Установка Java 11
sudo apt install openjdk-11-jdk -y

# Установка Maven
sudo apt install maven -y

# Проверка установки
java -version
mvn -version
```

#### Сборка проекта

```bash
# Клонирование проекта (или создание локально)
mkdir -p /home/$(whoami)/app
cd /home/$(whoami)/app

# Сборка приложения
mvn clean package -DskipTests

# Копирование в production директорию
sudo cp target/simple-web-app-1.0.0.jar /var/www/app/
```

#### Настройка systemd службы

```bash
# Создание службы
sudo nano /etc/systemd/system/simple-web-app.service
```

```ini
[Unit]
Description=Spring Boot Simple Web Application
After=network.target

[Service]
Type=simple
User=webuser
Group=webuser
ExecStart=/usr/bin/java -jar /var/www/app/simple-web-app-1.0.0.jar
Restart=always
RestartSec=10
Environment=JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64

[Install]
WantedBy=multi-user.target
```

```bash
# Запуск службы
sudo systemctl daemon-reload
sudo systemctl enable simple-web-app
sudo systemctl start simple-web-app
```

## 📚 API документация

### Base URL
- **Production**: `http://localhost`
- **Development**: `http://localhost:5000`

### Health Check API

#### GET /api/health
Базовая проверка состояния приложения.

**Запрос:**
```bash
curl http://localhost/api/health
```

**Ответ:**
```json
{
  "status": "UP",
  "timestamp": "2025-06-02T15:26:00",
  "service": "Simple Web App",
  "version": "1.0.0",
  "port": 5000
}
```

#### GET /api/health/detailed
Детальная информация о системе.

**Ответ:**
```json
{
  "status": "UP",
  "timestamp": "2025-06-02T15:26:00",
  "service": "Simple Web App",
  "version": "1.0.0",
  "port": 5000,
  "system": {
    "java_version": "11.0.19",
    "os_name": "Linux",
    "available_processors": 4,
    "max_memory": 1073741824
  }
}
```

### Products API

#### GET /api/products
Получить список всех продуктов.

```bash
curl http://localhost/api/products
```

**Ответ:**
```json
[
  {
    "id": 1,
    "name": "Laptop",
    "price": 999.99,
    "description": "High-performance laptop"
  },
  {
    "id": 2,
    "name": "Phone",
    "price": 599.99,
    "description": "Latest smartphone"
  }
]
```

#### GET /api/products/{id}
Получить продукт по ID.

```bash
curl http://localhost/api/products/1
```

#### POST /api/products
Создать новый продукт.

```bash
curl -X POST http://localhost/api/products \
  -H "Content-Type: application/json" \
  -d '{
    "name": "New Product",
    "price": 299.99,
    "description": "Product description"
  }'
```

#### PUT /api/products/{id}
Обновить существующий продукт.

```bash
curl -X PUT http://localhost/api/products/1 \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Updated Product",
    "price": 199.99,
    "description": "Updated description"
  }'
```

#### DELETE /api/products/{id}
Удалить продукт.

```bash
curl -X DELETE http://localhost/api/products/1
```

### Users API

#### GET /api/users
Получить список всех пользователей.

#### POST /api/users
Создать нового пользователя.

```bash
curl -X POST http://localhost/api/users \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Doe",
    "email": "john@example.com",
    "phone": "+1234567890"
  }'
```

### HTTP статус коды

| Код | Описание |
|-----|----------|
| `200 OK` | Успешный запрос |
| `201 Created` | Ресурс успешно создан |
| `204 No Content` | Ресурс успешно удалён |
| `400 Bad Request` | Некорректные данные запроса |
| `404 Not Found` | Ресурс не найден |
| `500 Internal Server Error` | Внутренняя ошибка сервера |

## 🧩 Модули приложения

### 1. Application.java - Главный класс
```java
@SpringBootApplication
public class Application {
    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }
}
```
**Назначение:** Точка входа в приложение, настройка Spring Boot контекста.

### 2. Controller Layer - REST API

#### HealthController
- **Назначение:** Мониторинг состояния приложения
- **Endpoints:** `/api/health`, `/api/health/detailed`
- **Особенности:** Не требует аутентификации, используется для health checks

#### ProductController
- **Назначение:** CRUD операции с продуктами
- **Endpoints:** Полный REST API для управления продуктами
- **Валидация:** `@Valid` аннотации для проверки входящих данных

#### UserController
- **Назначение:** Управление пользователями
- **Особенности:** Email валидация, телефонные номера опционально

### 3. Service Layer - Бизнес-логика

#### ProductService
```java
@Service
public class ProductService {
    private final AtomicLong counter = new AtomicLong(4);
    private final List products = new ArrayList<>();
    
    // CRUD методы...
}
```
**Особенности:**
- Thread-safe генерация ID с помощью `AtomicLong`
- In-memory хранение с `ArrayList`
- Иммутабельность возвращаемых коллекций

#### UserService
Аналогичная структура для управления пользователями.

### 4. Model Layer - Модели данных

#### Product
```java
public class Product {
    private Long id;
    @NotBlank(message = "Name is required")
    private String name;
    @NotNull @Positive
    private Double price;
    private String description;
}
```

#### User
```java
public class User {
    private Long id;
    @NotBlank(message = "Name is required")
    private String name;
    @Email(message = "Email should be valid")
    private String email;
    private String phone;
}
```

**Валидация:**
- `@NotBlank` - проверка на пустые строки
- `@NotNull` - проверка на null значения
- `@Positive` - положительные числа
- `@Email` - валидация email формата

## ⚙️ Конфигурация

### application.properties
```properties
# Конфигурация сервера
server.port=5000
server.servlet.context-path=/

# Информация о приложении
spring.application.name=simple-web-app
info.app.name=simple-web-app
info.app.version=1.0.0

# Actuator endpoints
management.endpoints.web.exposure.include=health,info,metrics
management.endpoint.health.show-details=always

# Логирование
logging.level.com.example=INFO
logging.level.org.springframework=WARN
logging.pattern.console=%d{yyyy-MM-dd HH:mm:ss} - %msg%n
```

### Nginx конфигурация
```nginx
upstream simple-web-app {
    server localhost:5000;
}

server {
    listen 80;
    server_name localhost;
    
    location / {
        proxy_pass http://simple-web-app;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    location /api/health {
        proxy_pass http://simple-web-app/api/health;
        access_log off;
    }
}
```

## 🔍 Диагностика и Troubleshooting

### Проверка состояния службы

```bash
# Статус приложения
sudo systemctl status simple-web-app

# Логи приложения
sudo journalctl -u simple-web-app -f

# Последние 100 строк логов
sudo journalctl -u simple-web-app -n 100
```

### Проверка сетевых соединений

```bash
# Проверка прослушиваемых портов
sudo netstat -tulpn | grep -E "(5000|80)"

# Проверка процессов Java
ps aux | grep java

# Проверка доступности портов
curl -I http://localhost:5000/api/health
curl -I http://localhost/api/health
```

### Диагностика Nginx

```bash
# Статус Nginx
sudo systemctl status nginx

# Проверка конфигурации
sudo nginx -t

# Логи Nginx
sudo tail -f /var/log/nginx/simple-web-app_access.log
sudo tail -f /var/log/nginx/simple-web-app_error.log
```

### Распространённые проблемы и решения

#### Проблема: Приложение не запускается

**Диагностика:**
```bash
sudo journalctl -u simple-web-app --since "10 minutes ago"
```

**Возможные причины:**
- Порт 5000 уже занят
- Неправильные права доступа к JAR файлу
- Отсутствует Java

**Решение:**
```bash
# Проверить занятые порты
sudo lsof -i :5000

# Проверить права доступа
ls -la /var/www/app/simple-web-app.jar

# Переустановить Java
sudo apt install openjdk-11-jdk -y
```

#### Проблема: 502 Bad Gateway от Nginx

**Диагностика:**
```bash
curl http://localhost:5000/api/health
sudo nginx -t
```

**Решение:**
```bash
# Перезапустить приложение
sudo systemctl restart simple-web-app

# Проверить конфигурацию Nginx
sudo nginx -t && sudo systemctl reload nginx
```

### Мониторинг производительности

```bash
# Использование памяти Java процессом
ps -o pid,ppid,cmd,%mem,%cpu -p $(pgrep java)

# Дисковое пространство
df -h

# Системная нагрузка
htop
```

## 🧪 Тестирование

### Автоматический тест скрипт

Создан скрипт `/home/webuser/test-api.sh` для комплексного тестирования:

```bash
sudo -u webuser /home/webuser/test-api.sh
```

### Ручное тестирование

#### Базовые тесты работоспособности
```bash
# Health check
curl -s http://localhost/api/health | jq .

# Получение данных
curl -s http://localhost/api/products | jq .
curl -s http://localhost/api/users | jq .
```

#### Тесты CRUD операций
```bash
# Создание продукта
curl -X POST http://localhost/api/products \
  -H "Content-Type: application/json" \
  -d '{"name":"Test Product","price":99.99}' | jq .

# Получение созданного продукта
curl -s http://localhost/api/products/4 | jq .

# Обновление продукта
curl -X PUT http://localhost/api/products/4 \
  -H "Content-Type: application/json" \
  -d '{"name":"Updated Product","price":149.99}' | jq .
```

#### Тесты валидации
```bash
# Тест некорректных данных
curl -X POST http://localhost/api/products \
  -H "Content-Type: application/json" \
  -d '{"name":"","price":-10}' -w "\nStatus: %{http_code}\n"
```

### Нагрузочное тестирование

```bash
# Простой нагрузочный тест с помощью ab
sudo apt install apache2-utils -y
ab -n 1000 -c 10 http://localhost/api/health
```

## 🚢 Развертывание

### Production развертывание

#### 1. Подготовка сервера
```bash
# Обновление и установка зависимостей
sudo apt update && sudo apt upgrade -y
sudo apt install openjdk-11-jdk maven nginx -y
```

#### 2. Настройка пользователя
```bash
# Создание пользователя для приложения
sudo useradd -r -m -U -d /home/webuser -s /bin/bash webuser
```

#### 3. Развертывание приложения
```bash
# Сборка и копирование
mvn clean package -DskipTests
sudo cp target/simple-web-app-*.jar /var/www/app/
sudo chown webuser:webuser /var/www/app/simple-web-app-*.jar
```

#### 4. Настройка автозапуска
```bash
sudo systemctl enable simple-web-app
sudo systemctl enable nginx
```

### Docker развертывание (опционально)

```dockerfile
FROM openjdk:11-jre-slim

WORKDIR /app
COPY target/simple-web-app-*.jar app.jar

EXPOSE 5000

USER 1000:1000
ENTRYPOINT ["java", "-jar", "app.jar"]
```

```bash
# Сборка и запуск Docker контейнера
docker build -t simple-web-app .
docker run -p 5000:5000 simple-web-app
```

## 📊 Мониторинг

### Health Checks

Приложение предоставляет несколько endpoints для мониторинга:

- `/api/health` - базовая проверка
- `/api/health/detailed` - детальная информация
- `/actuator/health` - Spring Actuator health check

### Логирование

**Конфигурация логирования:**
```properties
logging.level.com.example=INFO
logging.level.org.springframework=WARN
logging.pattern.console=%d{yyyy-MM-dd HH:mm:ss} - %msg%n
```

**Просмотр логов:**
```bash
# Логи приложения
sudo journalctl -u simple-web-app -f

# Логи Nginx
sudo tail -f /var/log/nginx/simple-web-app_access.log
```

### Метрики

Доступные метрики через Spring Actuator:
- Memory usage
- CPU usage  
- HTTP request metrics
- JVM metrics

```bash
curl http://localhost:5000/actuator/metrics
```

## 👨‍💻 Разработка

### Локальная разработка

```bash
# Запуск в режиме разработки
mvn spring-boot:run

# Запуск с профилем разработки
mvn spring-boot:run -Dspring-boot.run.profiles=dev
```

### Структура кода

- Следуйте принципам SOLID
- Используйте dependency injection через `@Autowired`
- Валидируйте входящие данные с помощью Bean Validation
- Обрабатывайте исключения через `@ExceptionHandler`

---

## 📝 Примечания для зачёта

Этот проект демонстрирует:
- ✅ Создание веб-приложения на Java
- ✅ Развертывание на Linux сервере
- ✅ Настройку systemd службы
- ✅ Конфигурацию Nginx reverse proxy
- ✅ Управление процессами и службами
- ✅ Мониторинг и диагностику системы

**Команды для демонстрации на зачёте:**
```bash
sudo systemctl status simple-web-app
curl http://localhost/api/health
curl http://localhost/api/products
sudo journalctl -u simple-web-app -n 20
history | tail -20
```
