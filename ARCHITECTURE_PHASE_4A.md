# IntelCrypt Phase 4A: Architecture & Data Flow

## 🏗️ System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    FLUTTER APP (Frontend)                   │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              UI Layer (Screens)                      │   │
│  ├──────────────────────────────────────────────────────┤   │
│  │  • SplashScreen - App initialization & routing      │   │
│  │  • LoginScreen - User email/password entry          │   │
│  │  • SignupScreen - User registration                 │   │
│  │  • ChatListScreen - List of user's chats            │   │
│  │  • ChatMessageScreen - Message thread viewer        │   │
│  │  • ProfileScreen - User profile management          │   │
│  │  • SecurityScreen - Security settings               │   │
│  └──────────────────────────────────────────────────────┘   │
│                          ↓ (Riverpod)                       │
│  ┌──────────────────────────────────────────────────────┐   │
│  │        State Management (Riverpod Providers)        │   │
│  ├──────────────────────────────────────────────────────┤   │
│  │                                                      │   │
│  │  authProvider (StateNotifierProvider)              │   │
│  │  ├─ AuthNotifier                                    │   │
│  │  │  ├─ initialize()     → Load stored tokens        │   │
│  │  │  ├─ login()          → Call API + save tokens    │   │
│  │  │  ├─ signup()         → Call API + save tokens    │   │
│  │  │  ├─ logout()         → Clear tokens              │   │
│  │  │  └─ refreshToken()   → Refresh access token     │   │
│  │  │                                                   │   │
│  │  └─ AuthState                                       │   │
│  │     ├─ isAuthenticated: bool                        │   │
│  │     ├─ token: AuthToken                             │   │
│  │     ├─ currentUser: User?                           │   │
│  │     ├─ isLoading: bool                              │   │
│  │     ├─ error: String?                               │   │
│  │     └─ requiresMfaSetup: bool                       │   │
│  │                                                      │   │
│  │  Computed Providers                                 │   │
│  │  ├─ isAuthenticatedProvider → bool                  │   │
│  │  ├─ currentUserProvider → User?                     │   │
│  │  └─ accessTokenProvider → String?                   │   │
│  │                                                      │   │
│  └──────────────────────────────────────────────────────┘   │
│                          ↓ (HTTP)                           │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              Service Layer                          │   │
│  ├──────────────────────────────────────────────────────┤   │
│  │                                                      │   │
│  │  ApiService (Singleton)                             │   │
│  │  ├─ baseUrl: String                                 │   │
│  │  ├─ _client: http.Client                            │   │
│  │  ├─ _accessToken: String?                           │   │
│  │  ├─ _refreshToken: String?                          │   │
│  │  ├─ _secureStorage: SecureStorageService            │   │
│  │  │                                                   │   │
│  │  ├─ HTTP Methods                                    │   │
│  │  │  ├─ get(endpoint) → HTTP GET                     │   │
│  │  │  ├─ post(endpoint, data) → HTTP POST             │   │
│  │  │  ├─ put(endpoint, data) → HTTP PUT               │   │
│  │  │  └─ delete(endpoint) → HTTP DELETE               │   │
│  │  │                                                   │   │
│  │  ├─ Auth Endpoints                                  │   │
│  │  │  ├─ login(request) → AuthResponse                │   │
│  │  │  ├─ signup(request) → AuthResponse               │   │
│  │  │  ├─ refreshToken() → AuthToken                   │   │
│  │  │  ├─ logout() → void                              │   │
│  │  │  └─ getCurrentUser() → User                       │   │
│  │  │                                                   │   │
│  │  ├─ Chat Endpoints                                  │   │
│  │  │  ├─ getChats() → List<Chat>                      │   │
│  │  │  ├─ getChat(id) → Chat                           │   │
│  │  │  ├─ createDirectChat(userId) → Chat              │   │
│  │  │  └─ ... (archive, mute, delete)                  │   │
│  │  │                                                   │   │
│  │  ├─ Message Endpoints                               │   │
│  │  │  ├─ getMessages(chatId) → List<Message>          │   │
│  │  │  ├─ sendMessage(...) → Message                   │   │
│  │  │  ├─ markMessageAsRead(...) → void                │   │
│  │  │  └─ deleteMessage(...) → void                    │   │
│  │  │                                                   │   │
│  │  ├─ Token Management                                │   │
│  │  │  ├─ loadStoredTokens()                           │   │
│  │  │  ├─ setTokens(access, refresh, userId)           │   │
│  │  │  ├─ getAccessToken() → String?                   │   │
│  │  │  ├─ clearTokens()                                │   │
│  │  │  └─ hasValidToken() → bool                       │   │
│  │  │                                                   │   │
│  │  └─ Internal                                        │   │
│  │     ├─ _getHeaders() → Map<String, String>          │   │
│  │     ├─ _handleResponse() → dynamic                  │   │
│  │     │  └─ Handles 401 with auto-refresh             │   │
│  │     └─ onTokenExpired: void Function()?             │   │
│  │                                                      │   │
│  │  SecureStorageService (Singleton)                   │   │
│  │  ├─ _storage: FlutterSecureStorage                  │   │
│  │  │                                                   │   │
│  │  ├─ Token Storage                                   │   │
│  │  │  ├─ saveAccessToken(token)                       │   │
│  │  │  ├─ getAccessToken() → String?                   │   │
│  │  │  ├─ saveRefreshToken(token)                      │   │
│  │  │  ├─ getRefreshToken() → String?                  │   │
│  │  │  └─ clearTokens()                                │   │
│  │  │                                                   │   │
│  │  ├─ User Storage                                    │   │
│  │  │  ├─ saveUserId(userId)                           │   │
│  │  │  ├─ getUserId() → String?                        │   │
│  │  │  ├─ saveSessionId(sessionId)                     │   │
│  │  │  └─ getSessionId() → String?                     │   │
│  │  │                                                   │   │
│  │  ├─ Encryption Keys                                 │   │
│  │  │  ├─ saveEncryptionKey(keyId, key)                │   │
│  │  │  ├─ getEncryptionKey(keyId) → String?            │   │
│  │  │  └─ getAllEncryptionKeys() → Map                 │   │
│  │  │                                                   │   │
│  │  └─ General Purpose                                 │   │
│  │     ├─ saveValue(key, value)                        │   │
│  │     ├─ getValue(key) → String?                      │   │
│  │     └─ clearAll()                                   │   │
│  │                                                      │   │
│  └──────────────────────────────────────────────────────┘   │
│                          ↓                                  │
│  ┌──────────────────────────────────────────────────────┐   │
│  │         Encrypted Local Storage (Platform)          │   │
│  ├──────────────────────────────────────────────────────┤   │
│  │  Android: flutter_secure_storage                     │   │
│  │  ├─ Keystore: RSA_ECB_OAEP with SHA256              │   │
│  │  └─ Storage: AES_GCM_NoPadding                       │   │
│  │                                                      │   │
│  │  iOS: flutter_secure_storage                         │   │
│  │  └─ Keychain: Native iOS encryption                 │   │
│  │                                                      │   │
│  │  Windows/Linux: flutter_secure_storage               │   │
│  │  └─ Platform-specific encryption                    │   │
│  │                                                      │   │
│  │  Stored Data:                                        │   │
│  │  ├─ access_token (JWT)                              │   │
│  │  ├─ refresh_token (JWT)                             │   │
│  │  ├─ user_id (String)                                │   │
│  │  ├─ session_id (String)                             │   │
│  │  └─ encryption_key_* (RSA/AES keys)                 │   │
│  │                                                      │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                              │
└─────────────────────────────────────────────────────────────┘
                          ↓ HTTP
┌─────────────────────────────────────────────────────────────┐
│            SPRING BOOT BACKEND (Backend)                    │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              Security Layer                         │   │
│  ├──────────────────────────────────────────────────────┤   │
│  │  JwtAuthenticationFilter                             │   │
│  │  ├─ Extracts "Authorization: Bearer {token}"        │   │
│  │  ├─ Validates JWT signature & expiry                │   │
│  │  └─ Sets SecurityContext with UserPrincipal          │   │
│  │                                                      │   │
│  │  SecurityConfig                                      │   │
│  │  ├─ CORS configuration                              │   │
│  │  ├─ Filter ordering                                 │   │
│  │  └─ Public/Protected endpoints                      │   │
│  │                                                      │   │
│  └──────────────────────────────────────────────────────┘   │
│                          ↓                                  │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              Controller Layer                        │   │
│  ├──────────────────────────────────────────────────────┤   │
│  │  AuthController                                      │   │
│  │  ├─ @PostMapping("/register")                       │   │
│  │  ├─ @PostMapping("/login")                          │   │
│  │  ├─ @PostMapping("/refresh")                        │   │
│  │  ├─ @GetMapping("/me")                              │   │
│  │  ├─ @PostMapping("/logout")                         │   │
│  │  └─ @PostMapping("/change-password")                │   │
│  │                                                      │   │
│  │  ChatController                                      │   │
│  │  ├─ @GetMapping("/chats")                           │   │
│  │  ├─ @PostMapping("/chats/direct")                   │   │
│  │  ├─ @PostMapping("/chats/group")                    │   │
│  │  └─ ... (update, archive, delete)                   │   │
│  │                                                      │   │
│  │  MessageController                                  │   │
│  │  ├─ @GetMapping("/chats/{id}/messages")             │   │
│  │  ├─ @PostMapping("/chats/{id}/messages")            │   │
│  │  ├─ @PutMapping("/chats/{id}/messages/{id}/read")   │   │
│  │  └─ ... (delete, search)                            │   │
│  │                                                      │   │
│  │  UserController                                     │   │
│  │  ├─ @GetMapping("/users/me")                        │   │
│  │  ├─ @GetMapping("/users/{id}")                      │   │
│  │  └─ @GetMapping("/users/search")                    │   │
│  │                                                      │   │
│  └──────────────────────────────────────────────────────┘   │
│                          ↓                                  │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              Service Layer                          │   │
│  ├──────────────────────────────────────────────────────┤   │
│  │  AuthService                                         │   │
│  │  ├─ register(request)                               │   │
│  │  ├─ login(request)                                  │   │
│  │  ├─ refreshToken(refreshToken)                      │   │
│  │  ├─ logout()                                        │   │
│  │  ├─ getCurrentUser()                                │   │
│  │  └─ changePassword()                                │   │
│  │                                                      │   │
│  │  JwtTokenService                                    │   │
│  │  ├─ generateToken(user)                             │   │
│  │  ├─ generateRefreshToken(user)                      │   │
│  │  ├─ validateToken(token)                            │   │
│  │  ├─ getClaimsFromToken(token)                       │   │
│  │  └─ isTokenExpired(token)                           │   │
│  │                                                      │   │
│  │  ChatService                                        │   │
│  │  └─ (Chat management methods)                       │   │
│  │                                                      │   │
│  │  MessageService                                     │   │
│  │  └─ (Message management methods)                    │   │
│  │                                                      │   │
│  └──────────────────────────────────────────────────────┘   │
│                          ↓                                  │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              Repository Layer (JPA)                 │   │
│  ├──────────────────────────────────────────────────────┤   │
│  │  UserRepository                                      │   │
│  │  ChatRepository                                      │   │
│  │  MessageRepository                                  │   │
│  │  AuditLogRepository                                 │   │
│  │                                                      │   │
│  └──────────────────────────────────────────────────────┘   │
│                          ↓                                  │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              Database Layer                         │   │
│  ├──────────────────────────────────────────────────────┤   │
│  │  H2 Database (Development)                           │   │
│  │  ├─ user (id, username, email, password_hash, ...)  │   │
│  │  ├─ chat (id, type, name, created_at, ...)          │   │
│  │  ├─ message (id, chat_id, sender_id, content, ...)  │   │
│  │  └─ audit_log (id, user_id, action, timestamp, ...)│   │
│  │                                                      │   │
│  │  PostgreSQL (Production)                            │   │
│  │  └─ Same schema as H2                               │   │
│  │                                                      │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔄 Authentication Flow Sequence

```
┌──────────────────────────────────────────────────────────────┐
│                   USER LOGIN FLOW                            │
├──────────────────────────────────────────────────────────────┤

User        LoginScreen    ApiService    Backend    Storage
  │             │              │            │           │
  │─ Enter ──→  │              │            │           │
  │  Email/Pwd  │              │            │           │
  │             │              │            │           │
  │─ Click ──→  │              │            │           │
  │  Login      │─ login() ──→ │            │           │
  │             │              │─ POST ──→ │           │
  │             │              │ /auth/     │           │
  │             │              │  login     │           │
  │             │              │            │─ Verify  │
  │             │              │            │  Creds  │
  │             │              │            │─ Gen ──→ │
  │             │ ← Response ←│ ← JWT ←  │  Tokens│
  │             │  AuthResp    │           │      │  │
  │             │              │           │      Save│
  │             │              │ setTokens()    │
  │             │              │ + persist ───→ │
  │             │              │                 │
  │             │ isAuthenticated = true         │
  │             │                                 │
  │ ← Redirect ←┤                                 │
  │  to /chats  │                                 │
  │             │                                 │


┌──────────────────────────────────────────────────────────────┐
│            AUTHENTICATED REQUEST FLOW                        │
├──────────────────────────────────────────────────────────────┤

ChatScreen    ApiService    Backend    Database
    │             │            │           │
    │─ get() ──→  │            │           │
    │  chats      │            │           │
    │             │ Load token │           │
    │             │ from       │           │
    │             │ storage    │           │
    │             │            │           │
    │             │ GET        │           │
    │             │ /chats ──→ │           │
    │             │ + Bearer   │─ Query ──→
    │             │  token     │  DB
    │             │            │           │
    │             │            │← Results ←
    │             │ ← 200 OK ──│
    │             │  [Chat[]]  │
    │             │            │
    │ ← Chats ←───┤            │
    │             │            │


┌──────────────────────────────────────────────────────────────┐
│           TOKEN REFRESH ON 401 FLOW                          │
├──────────────────────────────────────────────────────────────┤

ChatScreen    ApiService    Backend    Storage
    │             │            │           │
    │ get()    →  │            │           │
    │             │ GET /api   │           │
    │             │ /chats ──→ │           │
    │             │            │           │
    │             │            │← 401 ←──┤
    │             │            │ (Expired)
    │             │            │
    │             │ Detect 401 │
    │             │            │
    │             │ Load       │
    │             │ refresh ──→│
    │             │ token      │
    │             │            │
    │             │ POST       │
    │             │ /auth/     │
    │             │ refresh ──→│
    │             │            │
    │             │            │← New ←──┤
    │             │            │  Tokens │
    │             │ Save new ──────────→ │
    │             │ tokens    │         Save
    │             │           │
    │             │ RETRY GET │
    │             │ /chats ──→ │
    │             │            │
    │             │            │← 200 OK ←
    │             │            │ [Chat[]]
    │ ← Chats ←───┤            │
    │             │            │
```

---

## 📊 Token Lifecycle

```
┌────────────────────────────────────────────────────────┐
│              TOKEN LIFECYCLE                          │
├────────────────────────────────────────────────────────┤

[Generated]
    ↓
    Access Token (short-lived: 1 hour)
    Refresh Token (long-lived: 7 days)
    │
    ├─→ Stored in SecureStorage
    ├─→ Loaded in ApiService
    ├─→ Added to HTTP headers
    │
[Active]
    ↓
    Used for all authenticated requests
    │
    ├─→ Valid: Response returned
    ├─→ Expired: 401 Unauthorized
    │   ├─→ Try refreshToken()
    │   │   ├─→ Success: New tokens saved, retry request
    │   │   └─→ Failure: Clear tokens, logout, redirect to login
    │
[Expiration Path 1: Manual Logout]
    ├─→ User clicks logout
    ├─→ POST /api/auth/logout
    ├─→ clearTokens() called
    ├─→ Both tokens cleared from storage
    ├─→ Redirect to login
    │
[Expiration Path 2: Token Expiry]
    ├─→ Access token expires
    ├─→ Next API call gets 401
    ├─→ Use refresh token
    ├─→ Get new access token
    ├─→ Retry failed request
    │
[Expired/Cleared]
    ↓
    App returns to login screen
    User must re-authenticate
```

---

## 🔐 Security Layers

```
┌─────────────────────────────────────────┐
│        Application Security             │
├─────────────────────────────────────────┤

Layer 1: Transport Security
├─ HTTPS only (enforced in prod)
├─ TLS 1.2+ encryption
└─ Certificate pinning (optional)

Layer 2: Token Security
├─ JWT tokens signed with secret key
├─ HS256 algorithm
├─ Token expiry (1 hour access, 7 days refresh)
└─ Tokens only in Authorization header

Layer 3: Storage Security
├─ Android: RSA_ECB_OAEPwithSHA256 + AES_GCM_NoPadding
├─ iOS: Keychain encryption
└─ Never stored in SharedPreferences

Layer 4: Session Security
├─ Device ID tracking
├─ IP address logging
├─ User agent tracking
└─ Automatic logout on suspicious activity

Layer 5: Password Security
├─ Bcrypt hashing (backend)
├─ Minimum 8 characters required
├─ Can't reuse last 5 passwords
└─ Automatic expiry every 90 days

Layer 6: API Security
├─ Rate limiting (100 requests/minute)
├─ CORS enabled only for frontend domain
├─ Input validation on all endpoints
└─ SQL injection prevention (JPA)

└─ Result: Defense in depth approach
```

---

## 📈 Data Model Relationships

```
┌──────────────────────────────────────────────────┐
│          DATA MODEL RELATIONSHIPS                │
├──────────────────────────────────────────────────┤

User
├─ id: UUID
├─ username: String (unique)
├─ email: String (unique)
├─ password_hash: String
├─ roles: [ADMIN, USER, MOD]
├─ clearance_level: String
├─ created_at: DateTime
└─ Relationships
   ├─ has_many: Chat (as creator)
   ├─ has_many: Message (as sender)
   ├─ has_many: Session
   └─ has_many: AuditLog

Chat
├─ id: UUID
├─ type: [DIRECT, GROUP]
├─ name: String (for groups)
├─ description: String
├─ created_at: DateTime
├─ is_archived: Boolean
├─ is_muted: Boolean
└─ Relationships
   ├─ has_many: Message
   ├─ has_many: ChatParticipant
   ├─ belongs_to: User (creator)
   └─ has_many: User (through ChatParticipant)

ChatParticipant
├─ chat_id: UUID
├─ user_id: UUID
├─ joined_at: DateTime
├─ last_read_message_id: UUID
└─ Relationships
   ├─ belongs_to: Chat
   └─ belongs_to: User

Message
├─ id: UUID
├─ chat_id: UUID
├─ sender_id: UUID
├─ content: String (plain)
├─ content_encrypted: String (encrypted)
├─ status: [PENDING, SENT, DELIVERED, READ]
├─ created_at: DateTime
├─ read_at: DateTime
├─ is_deleted: Boolean
├─ expires_at: DateTime (for self-destructing)
└─ Relationships
   ├─ belongs_to: Chat
   └─ belongs_to: User (sender)

MessageEncryption
├─ message_id: UUID
├─ algorithm: String (RSA_AES_HYBRID)
├─ encrypted_key: String
├─ iv: String
└─ Relationships
   └─ belongs_to: Message

Session
├─ id: UUID
├─ user_id: UUID
├─ device_id: String
├─ device_name: String
├─ ip_address: String
├─ user_agent: String
├─ created_at: DateTime
├─ last_activity_at: DateTime
├─ expires_at: DateTime
└─ Relationships
   └─ belongs_to: User

AuditLog
├─ id: UUID
├─ user_id: UUID
├─ action: String
├─ resource_type: String
├─ resource_id: UUID
├─ changes: JSON
├─ ip_address: String
├─ timestamp: DateTime
└─ Relationships
   └─ belongs_to: User
```

---

## ✅ Architecture Quality Checklist

- ✅ **Separation of Concerns**: ApiService handles HTTP, SecureStorageService handles storage
- ✅ **Single Responsibility**: Each class has one clear purpose
- ✅ **Dependency Injection**: Services injected into providers
- ✅ **Error Handling**: Comprehensive exception handling
- ✅ **Type Safety**: Full type annotations throughout
- ✅ **State Management**: Centralized auth state with Riverpod
- ✅ **Security**: Multi-layered security approach
- ✅ **Scalability**: Can be extended for Phase 4B, 4C, 4D, 4E
- ✅ **Testability**: Services are mockable and testable
- ✅ **Documentation**: Well-documented with examples

---

**Architecture Version**: 1.0
**Last Updated**: Phase 4A Infrastructure Complete
**Status**: Production Ready ✅
