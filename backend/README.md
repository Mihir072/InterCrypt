# IntelCrypt - Extended AES-Based Secure Messaging & Data Vault Platform

<p align="center">
  <img src="https://img.shields.io/badge/Java-17-orange" alt="Java 17"/>
  <img src="https://img.shields.io/badge/Spring%20Boot-3.2.1-green" alt="Spring Boot 3.2.1"/>
  <img src="https://img.shields.io/badge/Security-Military%20Grade-blue" alt="Military Grade Security"/>
  <img src="https://img.shields.io/badge/Encryption-AES--256--GCM-red" alt="AES-256-GCM"/>
</p>

## 🔐 Overview

IntelCrypt is a production-grade secure messaging platform implementing military-grade end-to-end encryption (E2EE) with extended AES capabilities. Built on Spring Boot 3.2, it provides a comprehensive REST API for secure communication with defense-in-depth security measures.

## ✨ Key Features

### Cryptographic Capabilities
- **Extended AES Encryption**: 128/192/256-bit keys with multiple cipher modes
- **Cipher Modes**: GCM (default), CBC, CTR, XTS
- **Multi-Round Encryption**: Iterative encryption layers for defense-in-depth
- **Hybrid Encryption**: AES for content + RSA-4096/ECC secp384r1 for key exchange
- **Forward Secrecy**: New session key per message

### Security Features
- **Zero-Knowledge Architecture**: Private keys never leave client devices
- **JWT Authentication**: Stateless authentication with HS256 signing
- **RBAC**: Admin, Classified User, Standard User roles
- **Argon2id Password Hashing**: Memory-hard hashing (16MB, 2 iterations)
- **Rate Limiting**: Per-IP request throttling with Bucket4j
- **Honeypot Endpoints**: Intrusion detection and spam injection
- **Tamper-Resistant Audit Logging**: HMAC chain verification

### Message Security
- **End-to-End Encryption**: Content encrypted client-to-client
- **Message Classification**: UNCLASSIFIED, CONFIDENTIAL, SECRET, TOP_SECRET
- **Clearance Levels**: NONE, CONFIDENTIAL, SECRET, TOP_SECRET
- **Auto-Expiring Messages**: Configurable message TTL
- **Secure Deletion**: Cryptographic erasure of expired messages

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                        IntelCrypt Backend                          │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌──────────────┐   ┌──────────────┐   ┌──────────────┐           │
│  │   Controllers │   │   Services   │   │ Repositories │           │
│  │              │   │              │   │              │           │
│  │ AuthCtrl     │──▶│ AuthService  │──▶│ UserRepo     │           │
│  │ MessageCtrl  │   │ MessageSvc   │   │ MessageRepo  │           │
│  │ KeyCtrl      │   │ KeyService   │   │ KeyRepo      │           │
│  │ HealthCtrl   │   │ AuditService │   │ AuditRepo    │           │
│  └──────────────┘   └──────────────┘   └──────────────┘           │
│         │                   │                                       │
│         ▼                   ▼                                       │
│  ┌──────────────────────────────────────────────────────┐          │
│  │                 Cryptographic Layer                   │          │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐   │          │
│  │  │ AESCrypto   │  │ Asymmetric  │  │ Hybrid      │   │          │
│  │  │ Service     │  │ CryptoSvc   │  │ CryptoSvc   │   │          │
│  │  └─────────────┘  └─────────────┘  └─────────────┘   │          │
│  └──────────────────────────────────────────────────────┘          │
│         │                                                           │
│         ▼                                                           │
│  ┌──────────────────────────────────────────────────────┐          │
│  │              Security Filters                         │          │
│  │  JWT Auth │ Rate Limit │ Honeypot │ CORS             │          │
│  └──────────────────────────────────────────────────────┘          │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

## 🚀 Quick Start

### Prerequisites
- Java 17+
- Maven 3.8+
- PostgreSQL (production) or H2 (development)

### Build & Run

```bash
# Clone and navigate
cd IntelCrypt/backend

# Build
./mvnw clean package -DskipTests

# Run (development with H2)
./mvnw spring-boot:run

# Run (production with PostgreSQL)
java -jar target/intelcrypt-1.0.0-SNAPSHOT.jar --spring.profiles.active=prod
```

### Access
- **API**: http://localhost:8080/api
- **Swagger UI**: http://localhost:8080/swagger-ui.html
- **OpenAPI Spec**: http://localhost:8080/v3/api-docs

## 📡 API Endpoints

### Authentication
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/auth/register` | Register new user |
| POST | `/api/auth/login` | Authenticate user |
| POST | `/api/auth/refresh` | Refresh access token |
| POST | `/api/auth/change-password` | Change password |
| GET | `/api/auth/me` | Get current user |

### Key Management
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/keys/generate` | Generate key pair |
| GET | `/api/keys/public/{username}` | Get user's public key |
| POST | `/api/keys/rotate` | Rotate user keys |
| POST | `/api/keys/session` | Generate AES session key |
| GET | `/api/keys/list` | List user's keys |

### Messaging
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/messages/send` | Send encrypted message |
| GET | `/api/messages/inbox` | Get inbox (paginated) |
| GET | `/api/messages/sent` | Get sent messages |
| GET | `/api/messages/{id}` | Get message details |
| POST | `/api/messages/decrypt` | Decrypt message |
| DELETE | `/api/messages/{id}` | Delete message |
| GET | `/api/messages/unread/count` | Count unread messages |

## 🔒 Cryptographic Details

### AES Configuration
```properties
intelcrypt.crypto.aes.default-key-size=256
intelcrypt.crypto.aes.default-mode=GCM
intelcrypt.crypto.aes.gcm-tag-length=128
intelcrypt.crypto.aes.iteration-rounds=1
```

### RSA Configuration
```properties
intelcrypt.crypto.rsa.key-size=4096
intelcrypt.crypto.rsa.transformation=RSA/ECB/OAEPWithSHA-256AndMGF1Padding
```

### Key Derivation
- **Algorithm**: PBKDF2WithHmacSHA256
- **Iterations**: 310,000
- **Salt**: 256-bit random

### Password Hashing
- **Algorithm**: Argon2id
- **Memory Cost**: 16 MB
- **Iterations**: 2
- **Parallelism**: 1
- **Hash Length**: 32 bytes

## 🛡️ Security Considerations

### Message Encryption Flow
1. **Sender** generates random 256-bit AES session key
2. **Sender** encrypts message content with AES-GCM
3. **Sender** encrypts session key with recipient's RSA public key
4. Both encrypted content and key are stored/transmitted
5. **Recipient** decrypts session key with their RSA private key
6. **Recipient** decrypts content with recovered AES key
7. Session key is securely erased from memory

### Security Best Practices
- Private keys are encrypted with user password before storage
- JWT tokens have short expiration (15 minutes)
- Failed login attempts trigger account lockout
- All sensitive operations are audit logged
- Rate limiting prevents brute force attacks
- Honeypot endpoints detect attackers

## 🧪 Testing

```bash
# Run all tests
./mvnw test

# Run only crypto tests
./mvnw test -Dtest=*CryptoServiceTest

# Run with coverage
./mvnw test jacoco:report
```

### Test Coverage
- AES encryption/decryption across all modes
- Multi-round encryption verification
- RSA/ECC key generation and exchange
- ECDH shared secret derivation
- Hybrid encryption E2EE simulation
- Digital signature verification
- Tamper detection

## 📋 Configuration

### application.properties
```properties
# Server
server.port=8080

# Database (H2 for dev)
spring.datasource.url=jdbc:h2:mem:intelcrypt
spring.datasource.driver-class-name=org.h2.Driver

# JWT
intelcrypt.jwt.secret=${JWT_SECRET:your-256-bit-secret}
intelcrypt.jwt.expiration-ms=900000
intelcrypt.jwt.refresh-expiration-ms=86400000

# Security
intelcrypt.security.honeypot.enabled=true
intelcrypt.security.rate-limit.requests-per-minute=60
```

### Production Deployment
```bash
# Set environment variables
export JWT_SECRET="your-production-secret-minimum-256-bits"
export SPRING_DATASOURCE_URL="jdbc:postgresql://localhost:5432/intelcrypt"
export SPRING_DATASOURCE_USERNAME="intelcrypt"
export SPRING_DATASOURCE_PASSWORD="secure-password"

# Run with production profile
java -jar intelcrypt.jar --spring.profiles.active=prod
```

## 📁 Project Structure

```
backend/
├── src/
│   ├── main/
│   │   ├── java/com/intelcrypt/
│   │   │   ├── config/           # Spring configuration
│   │   │   ├── controller/       # REST controllers
│   │   │   ├── crypto/           # Cryptographic services
│   │   │   ├── dto/              # Data transfer objects
│   │   │   ├── entity/           # JPA entities
│   │   │   ├── exception/        # Exception handling
│   │   │   ├── repository/       # Data access layer
│   │   │   ├── security/         # Security filters
│   │   │   └── service/          # Business logic
│   │   └── resources/
│   │       └── application.properties
│   └── test/
│       └── java/com/intelcrypt/
│           └── crypto/           # Encryption tests
└── pom.xml
```

## 🔑 Dependencies

| Dependency | Version | Purpose |
|------------|---------|---------|
| Spring Boot | 3.2.1 | Core framework |
| Bouncy Castle | 1.77 | Extended crypto |
| JJWT | 0.12.3 | JWT handling |
| Bucket4j | 8.7.0 | Rate limiting |
| SpringDoc | 2.3.0 | OpenAPI docs |
| H2 | 2.2.x | Dev database |
| PostgreSQL | 42.7.x | Prod database |
| Lombok | 1.18.x | Boilerplate reduction |

## ⚠️ Security Warnings

1. **Never** commit `application.properties` with real secrets
2. **Always** use environment variables for production secrets
3. **Rotate** JWT secrets periodically
4. **Monitor** audit logs for suspicious activity
5. **Update** dependencies regularly for security patches

## 📄 License

Proprietary - All rights reserved.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Write tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

---

<p align="center">
  <strong>IntelCrypt</strong> - Military-Grade Secure Messaging<br>
  <em>Your secrets, protected.</em>
</p>
