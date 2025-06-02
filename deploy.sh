#!/bin/bash

set -e

APP_NAME="simple-web-app"
APP_USER="webuser"
APP_DIR="/var/www/app"
SERVICE_NAME="simple-web-app"
APP_PORT="5000"
NGINX_PORT="80"
PROJECT_VERSION="1.0.0"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
    exit 1
}

info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "Этот скрипт должен быть запущен с правами root (sudo)"
    fi
}

update_system() {
    log "Обновление системы..."
    apt update && apt upgrade -y
    apt install -y curl wget unzip zip git software-properties-common tree htop
}

install_java() {
    log "Установка OpenJDK 11..."
    apt install -y openjdk-11-jdk
    
    JAVA_HOME="/usr/lib/jvm/java-11-openjdk-amd64"
    echo "export JAVA_HOME=$JAVA_HOME" >> /etc/environment
    echo "export PATH=\$PATH:\$JAVA_HOME/bin" >> /etc/environment
    
    if java -version 2>&1 | grep -q "openjdk version"; then
        log "Java успешно установлена"
        java -version
    else
        error "Ошибка установки Java"
    fi
}

install_maven() {
    log "Установка Maven..."
    apt install -y maven
    
    if mvn -version 2>&1 | grep -q "Apache Maven"; then
        log "Maven успешно установлен"
        mvn -version
    else
        error "Ошибка установки Maven"
    fi
}

create_app_user() {
    log "Создание пользователя $APP_USER..."
    if ! id "$APP_USER" &>/dev/null; then
        useradd -r -m -U -d /home/$APP_USER -s /bin/bash $APP_USER
        log "Пользователь $APP_USER создан"
    else
        warn "Пользователь $APP_USER уже существует"
    fi
}

create_directories() {
    log "Создание необходимых директорий..."
    mkdir -p $APP_DIR
    mkdir -p /home/$APP_USER/source
    chmod 755 $APP_DIR
    chown -R $APP_USER:$APP_USER /home/$APP_USER
    chown -R $APP_USER:$APP_USER $APP_DIR
}

create_spring_boot_project() {
    log "Создание Spring Boot проекта локально..."
    
    PROJECT_DIR="/home/$APP_USER/source/$APP_NAME"
    
    if [ -d "$PROJECT_DIR" ]; then
        rm -rf "$PROJECT_DIR"
    fi
    
    sudo -u $APP_USER mkdir -p "$PROJECT_DIR"
    sudo -u $APP_USER mkdir -p "$PROJECT_DIR/src/main/java/com/example"
    sudo -u $APP_USER mkdir -p "$PROJECT_DIR/src/main/java/com/example/model"
    sudo -u $APP_USER mkdir -p "$PROJECT_DIR/src/main/java/com/example/controller"
    sudo -u $APP_USER mkdir -p "$PROJECT_DIR/src/main/java/com/example/service"
    sudo -u $APP_USER mkdir -p "$PROJECT_DIR/src/main/resources"
    sudo -u $APP_USER mkdir -p "$PROJECT_DIR/src/test/java/com/example"
    
    sudo -u $APP_USER cat > "$PROJECT_DIR/pom.xml" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 
         https://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    
    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>2.7.0</version>
        <relativePath/>
    </parent>
    
    <groupId>com.example</groupId>
    <artifactId>$APP_NAME</artifactId>
    <version>$PROJECT_VERSION</version>
    <packaging>jar</packaging>
    <name>Simple Web Application</name>
    <description>Simple Spring Boot Web Application</description>
    
    <properties>
        <java.version>11</java.version>
    </properties>
    
    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-actuator</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-validation</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
            <scope>test</scope>
        </dependency>
    </dependencies>
    
    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
            </plugin>
        </plugins>
    </build>
</project>
EOF

    sudo -u $APP_USER cat > "$PROJECT_DIR/src/main/java/com/example/Application.java" << 'EOF'
package com.example;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class Application {
    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }
}
EOF

    sudo -u $APP_USER cat > "$PROJECT_DIR/src/main/java/com/example/model/Product.java" << 'EOF'
package com.example.model;

import javax.validation.constraints.NotBlank;
import javax.validation.constraints.NotNull;
import javax.validation.constraints.Positive;

public class Product {
    private Long id;
    
    @NotBlank(message = "Name is required")
    private String name;
    
    @NotNull(message = "Price is required")
    @Positive(message = "Price must be positive")
    private Double price;
    
    private String description;
    
    public Product() {}
    
    public Product(Long id, String name, Double price) {
        this.id = id;
        this.name = name;
        this.price = price;
    }
    
    public Product(Long id, String name, Double price, String description) {
        this.id = id;
        this.name = name;
        this.price = price;
        this.description = description;
    }
    
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    
    public Double getPrice() { return price; }
    public void setPrice(Double price) { this.price = price; }
    
    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
}
EOF

    sudo -u $APP_USER cat > "$PROJECT_DIR/src/main/java/com/example/model/User.java" << 'EOF'
package com.example.model;

import javax.validation.constraints.Email;
import javax.validation.constraints.NotBlank;

public class User {
    private Long id;
    
    @NotBlank(message = "Name is required")
    private String name;
    
    @NotBlank(message = "Email is required")
    @Email(message = "Email should be valid")
    private String email;
    
    private String phone;
    
    public User() {}
    
    public User(Long id, String name, String email) {
        this.id = id;
        this.name = name;
        this.email = email;
    }
    
    public User(Long id, String name, String email, String phone) {
        this.id = id;
        this.name = name;
        this.email = email;
        this.phone = phone;
    }
    
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    
    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }
    
    public String getPhone() { return phone; }
    public void setPhone(String phone) { this.phone = phone; }
}
EOF

    sudo -u $APP_USER cat > "$PROJECT_DIR/src/main/java/com/example/service/ProductService.java" << 'EOF'
package com.example.service;

import com.example.model.Product;
import org.springframework.stereotype.Service;
import java.util.*;
import java.util.concurrent.atomic.AtomicLong;

@Service
public class ProductService {
    private final AtomicLong counter = new AtomicLong(4);
    private final List<Product> products = new ArrayList<>(Arrays.asList(
        new Product(1L, "Laptop", 999.99, "High-performance laptop"),
        new Product(2L, "Phone", 599.99, "Latest smartphone"),
        new Product(3L, "Tablet", 399.99, "Lightweight tablet")
    ));
    
    public List<Product> getAllProducts() {
        return new ArrayList<>(products);
    }
    
    public Optional<Product> getProductById(Long id) {
        return products.stream()
            .filter(p -> p.getId().equals(id))
            .findFirst();
    }
    
    public Product createProduct(Product product) {
        product.setId(counter.getAndIncrement());
        products.add(product);
        return product;
    }
    
    public Product updateProduct(Long id, Product updatedProduct) {
        for (int i = 0; i < products.size(); i++) {
            Product product = products.get(i);
            if (product.getId().equals(id)) {
                updatedProduct.setId(id);
                products.set(i, updatedProduct);
                return updatedProduct;
            }
        }
        return null;
    }
    
    public boolean deleteProduct(Long id) {
        return products.removeIf(p -> p.getId().equals(id));
    }
}
EOF

    sudo -u $APP_USER cat > "$PROJECT_DIR/src/main/java/com/example/service/UserService.java" << 'EOF'
package com.example.service;

import com.example.model.User;
import org.springframework.stereotype.Service;
import java.util.*;
import java.util.concurrent.atomic.AtomicLong;

@Service
public class UserService {
    private final AtomicLong counter = new AtomicLong(4);
    private final List<User> users = new ArrayList<>(Arrays.asList(
        new User(1L, "John Doe", "john@example.com", "+1234567890"),
        new User(2L, "Jane Smith", "jane@example.com", "+0987654321"),
        new User(3L, "Bob Johnson", "bob@example.com", "+1122334455")
    ));
    
    public List<User> getAllUsers() {
        return new ArrayList<>(users);
    }
    
    public Optional<User> getUserById(Long id) {
        return users.stream()
            .filter(u -> u.getId().equals(id))
            .findFirst();
    }
    
    public User createUser(User user) {
        user.setId(counter.getAndIncrement());
        users.add(user);
        return user;
    }
    
    public User updateUser(Long id, User updatedUser) {
        for (int i = 0; i < users.size(); i++) {
            User user = users.get(i);
            if (user.getId().equals(id)) {
                updatedUser.setId(id);
                users.set(i, updatedUser);
                return updatedUser;
            }
        }
        return null;
    }
    
    public boolean deleteUser(Long id) {
        return users.removeIf(u -> u.getId().equals(id));
    }
}
EOF

    sudo -u $APP_USER cat > "$PROJECT_DIR/src/main/java/com/example/controller/ProductController.java" << 'EOF'
package com.example.controller;

import com.example.model.Product;
import com.example.service.ProductService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import javax.validation.Valid;
import java.util.List;
import java.util.Optional;

@RestController
@RequestMapping("/api/products")
@Validated
public class ProductController {
    
    @Autowired
    private ProductService productService;
    
    @GetMapping
    public ResponseEntity<List<Product>> getAllProducts() {
        List<Product> products = productService.getAllProducts();
        return ResponseEntity.ok(products);
    }
    
    @GetMapping("/{id}")
    public ResponseEntity<Product> getProductById(@PathVariable Long id) {
        Optional<Product> product = productService.getProductById(id);
        return product.map(ResponseEntity::ok)
                     .orElse(ResponseEntity.notFound().build());
    }
    
    @PostMapping
    public ResponseEntity<Product> createProduct(@Valid @RequestBody Product product) {
        Product createdProduct = productService.createProduct(product);
        return ResponseEntity.status(HttpStatus.CREATED).body(createdProduct);
    }
    
    @PutMapping("/{id}")
    public ResponseEntity<Product> updateProduct(@PathVariable Long id, 
                                               @Valid @RequestBody Product product) {
        Product updatedProduct = productService.updateProduct(id, product);
        return updatedProduct != null ? ResponseEntity.ok(updatedProduct) 
                                      : ResponseEntity.notFound().build();
    }
    
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteProduct(@PathVariable Long id) {
        boolean deleted = productService.deleteProduct(id);
        return deleted ? ResponseEntity.noContent().build() 
                       : ResponseEntity.notFound().build();
    }
}
EOF

    sudo -u $APP_USER cat > "$PROJECT_DIR/src/main/java/com/example/controller/UserController.java" << 'EOF'
package com.example.controller;

import com.example.model.User;
import com.example.service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import javax.validation.Valid;
import java.util.List;
import java.util.Optional;

@RestController
@RequestMapping("/api/users")
@Validated
public class UserController {
    
    @Autowired
    private UserService userService;
    
    @GetMapping
    public ResponseEntity<List<User>> getAllUsers() {
        List<User> users = userService.getAllUsers();
        return ResponseEntity.ok(users);
    }
    
    @GetMapping("/{id}")
    public ResponseEntity<User> getUserById(@PathVariable Long id) {
        Optional<User> user = userService.getUserById(id);
        return user.map(ResponseEntity::ok)
                   .orElse(ResponseEntity.notFound().build());
    }
    
    @PostMapping
    public ResponseEntity<User> createUser(@Valid @RequestBody User user) {
        User createdUser = userService.createUser(user);
        return ResponseEntity.status(HttpStatus.CREATED).body(createdUser);
    }
    
    @PutMapping("/{id}")
    public ResponseEntity<User> updateUser(@PathVariable Long id, 
                                         @Valid @RequestBody User user) {
        User updatedUser = userService.updateUser(id, user);
        return updatedUser != null ? ResponseEntity.ok(updatedUser) 
                                   : ResponseEntity.notFound().build();
    }
    
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteUser(@PathVariable Long id) {
        boolean deleted = userService.deleteUser(id);
        return deleted ? ResponseEntity.noContent().build() 
                       : ResponseEntity.notFound().build();
    }
}
EOF

    sudo -u $APP_USER cat > "$PROJECT_DIR/src/main/java/com/example/controller/HealthController.java" << 'EOF'
package com.example.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/health")
public class HealthController {
    
    @GetMapping
    public Map<String, Object> health() {
        Map<String, Object> status = new HashMap<>();
        status.put("status", "UP");
        status.put("timestamp", LocalDateTime.now());
        status.put("service", "Simple Web App");
        status.put("version", "1.0.0");
        status.put("port", 5000);
        return status;
    }
    
    @GetMapping("/detailed")
    public Map<String, Object> detailedHealth() {
        Map<String, Object> health = new HashMap<>();
        health.put("status", "UP");
        health.put("timestamp", LocalDateTime.now());
        health.put("service", "Simple Web App");
        health.put("version", "1.0.0");
        health.put("port", 5000);
        
        Map<String, Object> system = new HashMap<>();
        system.put("java_version", System.getProperty("java.version"));
        system.put("os_name", System.getProperty("os.name"));
        system.put("available_processors", Runtime.getRuntime().availableProcessors());
        system.put("max_memory", Runtime.getRuntime().maxMemory());
        
        health.put("system", system);
        return health;
    }
}
EOF

    sudo -u $APP_USER cat > "$PROJECT_DIR/src/main/resources/application.properties" << EOF
server.port=$APP_PORT
server.servlet.context-path=/

spring.application.name=$APP_NAME
info.app.name=$APP_NAME
info.app.version=$PROJECT_VERSION

management.endpoints.web.exposure.include=health,info,metrics
management.endpoint.health.show-details=always
management.endpoint.health.show-components=always

logging.level.com.example=INFO
logging.level.org.springframework=WARN
logging.pattern.console=%d{yyyy-MM-dd HH:mm:ss} - %msg%n

spring.mvc.throw-exception-if-no-handler-found=true
spring.web.resources.add-mappings=false
EOF

    log "Spring Boot проект создан в $PROJECT_DIR"
}

build_application() {
    log "Сборка Spring Boot приложения..."
    
    PROJECT_DIR="/home/$APP_USER/source/$APP_NAME"
    cd "$PROJECT_DIR"
    
    sudo -u $APP_USER mvn clean package -DskipTests
    
    JAR_FILE=$(find target -name "*.jar" -not -name "*sources.jar" | head -1)
    if [ -f "$JAR_FILE" ]; then
        cp "$JAR_FILE" "$APP_DIR/$APP_NAME.jar"
        chown $APP_USER:$APP_USER "$APP_DIR/$APP_NAME.jar"
        log "JAR файл скопирован в $APP_DIR"
        
        info "Размер JAR файла: $(du -h $APP_DIR/$APP_NAME.jar | cut -f1)"
        info "JAR файл: $APP_DIR/$APP_NAME.jar"
    else
        error "JAR файл не найден после сборки"
    fi
}

create_systemd_service() {
    log "Создание systemd службы..."
    
    cat > /etc/systemd/system/$SERVICE_NAME.service << EOF
[Unit]
Description=Spring Boot $APP_NAME Application
Documentation=https://spring.io/projects/spring-boot
After=network.target

[Service]
Type=simple
User=$APP_USER
Group=$APP_USER
ExecStart=/usr/bin/java -server -Xms256m -Xmx512m -jar $APP_DIR/$APP_NAME.jar
ExecStop=/bin/kill -15 \$MAINPID
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=$SERVICE_NAME
Environment=JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
Environment=SPRING_PROFILES_ACTIVE=production
Environment=JAVA_OPTS="-Dspring.profiles.active=production"

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable $SERVICE_NAME.service
    log "Systemd служба создана и включена"
}

setup_nginx() {
    log "Установка и настройка Nginx..."
    apt install -y nginx
    
    cat > /etc/nginx/sites-available/$APP_NAME << EOF
upstream $APP_NAME {
    server localhost:$APP_PORT;
}

server {
    listen $NGINX_PORT;
    listen [::]:$NGINX_PORT;
    server_name localhost _;
    
    access_log /var/log/nginx/${APP_NAME}_access.log;
    error_log /var/log/nginx/${APP_NAME}_error.log;
    
    location / {
        proxy_pass http://$APP_NAME;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-Port \$server_port;
        
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
    
    location /api/health {
        proxy_pass http://$APP_NAME/api/health;
        proxy_set_header Host \$host;
        access_log off;
    }
    
    location /nginx-status {
        stub_status on;
        access_log off;
        allow 127.0.0.1;
        deny all;
    }
}
EOF

    ln -sf /etc/nginx/sites-available/$APP_NAME /etc/nginx/sites-enabled/
    rm -f /etc/nginx/sites-enabled/default
    
    nginx -t
    systemctl restart nginx
    systemctl enable nginx
    
    log "Nginx настроен и запущен"
}

setup_firewall() {
    log "Настройка UFW файрвола..."
    ufw --force enable
    ufw allow ssh
    ufw allow $NGINX_PORT
    ufw allow $APP_PORT
    ufw --force reload
    ufw status
    log "Файрвол настроен"
}

start_application() {
    log "Запуск приложения..."
    systemctl start $SERVICE_NAME.service
    
    info "Ожидание запуска приложения..."
    sleep 15
    
    if systemctl is-active --quiet $SERVICE_NAME.service; then
        log "Приложение успешно запущено"
    else
        error "Ошибка запуска приложения. Проверьте логи: journalctl -u $SERVICE_NAME.service"
    fi
}

test_deployment() {
    log "Тестирование развертывания..."
    
    for i in {1..10}; do
        if curl -s http://localhost:$APP_PORT/api/health > /dev/null; then
            log "Health check через приложение успешен"
            break
        elif [ $i -eq 10 ]; then
            error "Health check через приложение не прошел"
        else
            warn "Попытка $i/10 health check через приложение..."
            sleep 3
        fi
    done
    
    if curl -s http://localhost/api/health > /dev/null; then
        log "Nginx reverse proxy работает"
    else
        warn "Nginx reverse proxy может не работать"
    fi
    
    info "Тестирование API endpoints..."
    
    if curl -s http://localhost/api/products > /dev/null; then
        log "Products API работает"
    else
        warn "Products API может не работать"
    fi
    
    if curl -s http://localhost/api/users > /dev/null; then
        log "Users API работает"
    else
        warn "Users API может не работать"
    fi
}

create_test_script() {
    log "Создание скрипта для тестирования API..."
    
    cat > /home/$APP_USER/test-api.sh << 'EOF'
#!/bin/bash

echo "=== Тестирование Spring Boot API ==="
echo

echo "1. Health Check:"
curl -s http://localhost/api/health | python3 -m json.tool 2>/dev/null || curl -s http://localhost/api/health
echo -e "\n"

echo "2. Products API:"
echo "GET /api/products:"
curl -s http://localhost/api/products | python3 -m json.tool 2>/dev/null || curl -s http://localhost/api/products
echo -e "\n"

echo "GET /api/products/1:"
curl -s http://localhost/api/products/1 | python3 -m json.tool 2>/dev/null || curl -s http://localhost/api/products/1
echo -e "\n"

echo "3. Users API:"
echo "GET /api/users:"
curl -s http://localhost/api/users | python3 -m json.tool 2>/dev/null || curl -s http://localhost/api/users
echo -e "\n"

echo "GET /api/users/1:"
curl -s http://localhost/api/users/1 | python3 -m json.tool 2>/dev/null || curl -s http://localhost/api/users/1
echo -e "\n"

echo "4. Detailed Health:"
curl -s http://localhost/api/health/detailed | python3 -m json.tool 2>/dev/null || curl -s http://localhost/api/health/detailed
echo
EOF

    chmod +x /home/$APP_USER/test-api.sh
    chown $APP_USER:$APP_USER /home/$APP_USER/test-api.sh
    
    log "Скрипт тестирования создан: /home/$APP_USER/test-api.sh"
}

show_deployment_info() {
    log "Развертывание завершено успешно!"
    echo
    echo "=============================================="
    echo "    ИНФОРМАЦИЯ О РАЗВЕРТЫВАНИИ"
    echo "=============================================="
    echo "Приложение: $APP_NAME"
    echo "Версия: $PROJECT_VERSION"
    echo "Пользователь: $APP_USER"
    echo "Директория приложения: $APP_DIR"
    echo "Директория исходников: /home/$APP_USER/source/$APP_NAME"
    echo "Порт приложения: $APP_PORT"
    echo "Nginx порт: $NGINX_PORT"
    echo
    echo "=============================================="
    echo "    УПРАВЛЕНИЕ СЛУЖБОЙ"
    echo "=============================================="
    echo "Статус:      sudo systemctl status $SERVICE_NAME"
    echo "Запуск:      sudo systemctl start $SERVICE_NAME"
    echo "Остановка:   sudo systemctl stop $SERVICE_NAME"
    echo "Перезапуск:  sudo systemctl restart $SERVICE_NAME"
    echo "Логи:        sudo journalctl -u $SERVICE_NAME -f"
    echo
    echo "=============================================="
    echo "    ТЕСТИРОВАНИЕ API"
    echo "=============================================="
    echo "Health Check:    curl http://localhost/api/health"
    echo "Products API:    curl http://localhost/api/products"
    echo "Users API:       curl http://localhost/api/users"
    echo "Detailed Health: curl http://localhost/api/health/detailed"
    echo
    echo "Скрипт тестирования: /home/$APP_USER/test-api.sh"
    echo "Запуск: sudo -u $APP_USER /home/$APP_USER/test-api.sh"
    echo
    echo "=============================================="
    echo "    ПРЯМОЙ ДОСТУП К ПРИЛОЖЕНИЮ"
    echo "=============================================="
    echo "Через Nginx:     http://localhost:$NGINX_PORT"
    echo "Напрямую:        http://localhost:$APP_PORT"
    echo
    echo "=============================================="
    echo "    IP АДРЕСА СЕРВЕРА"
    echo "=============================================="
    ip addr show | grep 'inet ' | grep -v '127.0.0.1' | awk '{print "Внешний IP: " $2}' | cut -d/ -f1
    echo "Локальный IP:    127.0.0.1"
    echo
    echo "=============================================="
    echo "    ФАЙЛЫ ПРОЕКТА"
    echo "=============================================="
    echo "JAR файл:        $APP_DIR/$APP_NAME.jar"
    echo "Конфигурация:    /etc/systemd/system/$SERVICE_NAME.service"
    echo "Nginx конфиг:    /etc/nginx/sites-available/$APP_NAME"
    echo "Логи Nginx:      /var/log/nginx/${APP_NAME}_*.log"
    echo
}

main() {
    log "Начало автоматического развертывания Spring Boot приложения (локально)"
    
    check_root
    update_system
    install_java
    install_maven
    create_app_user
    create_directories
    create_spring_boot_project
    build_application
    create_systemd_service
    setup_nginx
    setup_firewall
    start_application
    test_deployment
    create_test_script
    show_deployment_info
    
    log "Развертывание завершено успешно!"
    echo
    info "Для тестирования запустите: sudo -u $APP_USER /home/$APP_USER/test-api.sh"
}

main "$@"

