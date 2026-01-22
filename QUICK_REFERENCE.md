# IntelCrypt Quick Reference

## 🚀 Quick Start Commands

```bash
# Backend Setup
cd backend
mvn clean compile
mvn spring-boot:run

# Frontend Setup
cd frontend
flutter pub get
flutter pub run build_runner build
flutter run
```

## 📱 File Organization

### Backend Files (40 total)
```
Security (7)        - Auth, Security, Filters, JWT
Services (3)        - Message, Key, User
Crypto (3)          - AES, Hybrid, Asymmetric
Configuration (1)   - CryptoConfigProperties
DTOs (2)            - Key, Message
Models (3)          - Auth, Audit, Encryption
Exception (1)       - GlobalExceptionHandler
```

### Frontend Files (Structure)
```
Models (4)          - User, Chat, Message, Auth
Services (3)        - API, Storage, Encryption
Providers (3)       - Auth, Chat, Message
Screens (7)         - Splash, Login, ChatList + 4 more
Widgets (2)         - CustomInput + reusable
Theme (1)           - Material Design 3
```

## 🔗 Key Integration Points

```
Frontend Login  →  Backend /auth/login  →  JWT Token
Frontend Chat   →  Backend /chats       →  Chat List
Frontend Send   →  Backend /messages    →  Encrypted Storage
```

## 🔐 Security Checklist

- ✅ JWT authentication
- ✅ AES-256-GCM encryption
- ✅ Secure storage (Keystore/Keychain)
- ✅ Biometric support
- ✅ Rate limiting
- ✅ Honeypot filter
- ✅ HTTPS ready
- ✅ Session management

## 📊 Important Classes

**Backend**
- `AuthService` - Authentication logic
- `ApiService` (frontend) - API communication
- `CryptoConfigProperties` - Configuration
- `SecurityConfig` - Spring Security setup

**Frontend**
- `ApiService` - REST client
- `SecureStorageService` - Encrypted storage
- `AuthNotifier` - Auth state management
- `AppTheme` - Material Design 3

## 🧪 Testing Commands

```bash
# Backend
mvn test                      # Run tests
mvn verify                    # Full build verification

# Frontend
flutter test                  # Run all tests
flutter test --coverage       # With coverage report
```

## 🐛 Common Issues

| Issue | Solution |
|-------|----------|
| Circular dependency | Use @Lazy annotation |
| Token expired | Call refreshAccessToken() |
| Build fails | Run `flutter pub get` & `flutter clean` |
| Storage encryption fails | Check Keystore/Keychain permissions |
| API 401 error | Verify JWT token in secure storage |

## 📈 Performance Tips

- Lazy load messages (pagination)
- Cache images with `cached_network_image`
- Use Riverpod selectors to avoid rebuilds
- Profile with DevTools regularly
- Batch API requests when possible

## 🔄 Code Generation

```bash
# Generate Riverpod & JSON code
flutter pub run build_runner build

# Watch for changes
flutter pub run build_runner watch

# Clean generated files
flutter pub run build_runner clean
```

## 🎨 Theme Colors

```dart
Primary:      #1565C0 (Deep Blue)
Secondary:    #00BCD4 (Cyan)
Tertiary:     #7C4DFF (Purple)
Error:        #E53935 (Red)
Success:      #43A047 (Green)
Warning:      #FFA726 (Orange)
```

## 📚 Key Endpoints

```
POST   /api/auth/login
POST   /api/auth/signup
GET    /api/chats
POST   /api/chats/direct
POST   /api/chats/{id}/messages
PUT    /api/chats/{id}/messages/{id}/read
GET    /api/users/me
GET    /api/users/search
```

## 🔑 Important Files to Edit

**Backend**
- `application.properties` - Configuration
- `SecurityConfig.java` - Security rules
- `CryptoConfigProperties.java` - Crypto settings

**Frontend**
- `lib/src/providers/auth_provider.dart` - API URL
- `lib/src/ui/theme/app_theme.dart` - Colors
- `pubspec.yaml` - Dependencies

## ⚡ Quick Debugging

```bash
# View backend logs
tail -f nohup.out

# View frontend logs
flutter logs

# Check device connection
flutter devices

# Rebuild Flutter app
flutter clean && flutter pub get
```

## 🌐 API Configuration

**Development**
```dart
baseUrl: 'http://localhost:8080/api'
```

**Production**
```dart
baseUrl: 'https://api.intelcrypt.com/api'
```

## 👥 User Roles

- `USER` - Regular user
- `ADMIN` - System administrator
- `ANALYST` - Data analyst
- `AUDITOR` - Audit access

## 📱 Supported Platforms

**Backend**
- Linux, macOS, Windows
- Docker containers
- Cloud deployment ready

**Frontend**
- Android 5.0+ (API 21+)
- iOS 9.0+
- Web (experimental)

## 🎯 Next Actions

1. [ ] Configure backend API URL in frontend
2. [ ] Build backend JAR
3. [ ] Generate Flutter code
4. [ ] Run integration tests
5. [ ] Deploy to staging
6. [ ] Load testing
7. [ ] Security audit
8. [ ] Production release

## 📞 Support Resources

- **Backend**: See `backend/README.md`
- **Frontend**: See `frontend/GETTING_STARTED.md`
- **Architecture**: See `frontend/FRONTEND_ARCHITECTURE.md`
- **Full Summary**: See `PROJECT_SUMMARY.md`

---

**Status**: ✅ Production-Ready Code Architecture
**Last Updated**: [Current Date]
**Maintained By**: IntelCrypt Development Team
