# Frontend-Backend Integration Guide

**Date**: January 8, 2026  
**Status**: Ready for Integration  
**Backend**: Spring Boot 3.2.1 (Java 17) - BUILD SUCCESS  
**Frontend**: Flutter 3.10.1+ (Dart 3.10.1+) - Phase 3 Complete

---

## 🔗 Integration Overview

### Current State
- **Backend**: All 40 Java files compiled, Spring Boot ready to run
- **Frontend**: All screens implemented, navigation complete, state management ready
- **API**: Contract defined via Riverpod providers (awaiting backend endpoints)
- **Encryption**: Foundation ready (awaiting real E2E implementation)

### Integration Flow
```
Frontend (Flutter)
    ↓ HTTP + JWT
    ↓ Riverpod async providers
    ↓
Backend (Spring Boot)
    ↓ JWT verification
    ↓ Database operations
    ↓ Encryption/Decryption
    ↓
Database (PostgreSQL)
    ↓
Frontend receives data
    ↓ Update providers
    ↓ UI re-renders
```

---

## 🚀 Quick Start (Both Platforms)

### Backend Start
```bash
# Terminal 1: Backend
cd c:\Users\MIHIR\Downloads\IntelCrypt\backend

# Ensure Java 17 is available
java -version

# Run Spring Boot
mvn spring-boot:run

# Expected output:
# BUILD SUCCESS
# Tomcat started on port(s): 8080 (http)
```

### Frontend Start
```bash
# Terminal 2: Frontend
cd c:\Users\MIHIR\Downloads\IntelCrypt\frontend

# Run Flutter
flutter run

# Expected output:
# Flutter app starts
# Shows SplashScreen → Navigation to LoginScreen (no token)
```

---

## 🔌 API Endpoints to Implement

### Authentication
```http
POST /api/auth/register
POST /api/auth/login
POST /api/auth/refresh-token
POST /api/auth/logout
GET  /api/auth/verify
```

### Messages
```http
GET    /api/messages/chats/{chatId}           # Get messages in chat
POST   /api/messages                            # Send message
PUT    /api/messages/{messageId}                # Update message
DELETE /api/messages/{messageId}                # Delete message
GET    /api/messages/{messageId}/decrypt        # Decrypt message
POST   /api/messages/{messageId}/mark-as-read   # Mark as read
```

### Chats
```http
GET    /api/chats                   # Get user's chats
POST   /api/chats                   # Create new chat
GET    /api/chats/{chatId}          # Get chat details
PUT    /api/chats/{chatId}          # Update chat
DELETE /api/chats/{chatId}          # Delete/archive chat
POST   /api/chats/{chatId}/mute     # Mute chat
POST   /api/chats/{chatId}/unmute   # Unmute chat
```

### Keys
```http
GET    /api/keys/public/{userId}     # Get user's public key
POST   /api/keys/rotate              # Rotate encryption keys
GET    /api/keys/recovery-codes      # Get recovery codes
POST   /api/keys/recovery-codes      # Generate new recovery codes
POST   /api/keys/verify              # Verify key ownership
```

### Users
```http
GET    /api/users/profile             # Get current user
PUT    /api/users/profile             # Update profile
GET    /api/users/profile/avatar      # Get user avatar
POST   /api/users/profile/avatar      # Upload avatar
GET    /api/users/audit-log           # Get security audit log
```

---

## 📡 Frontend-Backend Data Flow

### User Login Flow
```dart
// Frontend: login_screen.dart
1. User enters email/password
2. Call: await authService.login(email, password)
   ↓
// Backend: AuthController
3. POST /api/auth/login → verify credentials
4. Generate JWT token
5. Return { token, userId, expiresIn }
   ↓
// Frontend: auth_provider.dart
6. Store token in SecureStorageService
7. Save to authTokenProvider state
8. Navigate to ChatListScreen
   ↓
// Backend: JWT Filter
9. All subsequent requests include Authorization header
10. Filter verifies JWT token is valid
```

### Message Send Flow
```dart
// Frontend: chat_message_screen.dart
1. User types message, taps Send
2. Create optimistic message (status: pending)
3. Add to local messageListProvider
4. UI updates immediately
5. Call: messageService.sendMessage(...)
   ↓
// Backend: MessageController
6. POST /api/messages with encrypted content
7. Verify user has access to chat
8. Store message in database
9. Encrypt content with AES key
10. Return { messageId, timestamp, status: sent }
    ↓
// Frontend: message_provider.dart
11. Update optimistic message with real ID and timestamp
12. Change status from pending → sent
13. UI updates to show "sent" indicator
    ↓
14. (WebSocket setup for real-time updates)
15. Other users receive message via WebSocket
16. Update their messageListProvider
17. Their UI updates automatically
```

### Chat List Flow
```dart
// Frontend: chat_list_screen.dart
1. Widget loads → ref.watch(chatListProvider)
2. Provider calls: await chatService.getChats()
3. State: loading
   ↓
// Backend: ChatController
4. GET /api/chats
5. Verify JWT token is valid
6. Query database for user's chats
7. Return list of Chat objects
   ↓
// Frontend: models/chat_model.dart
8. Parse JSON response into Chat objects
9. Update chatListProvider state: data
10. UI renders ChatList with ChatTile widgets
```

---

## 🔐 JWT & Security Integration

### How JWT Works Currently

#### Frontend Implementation
```dart
// lib/src/services/api_service.dart
class ApiService {
  Future<Response> _request(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    // 1. Get token from secure storage
    final token = await _secureStorage.getAuthToken();
    
    // 2. Add JWT to Authorization header
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
    
    // 3. Make request with JWT
    final response = await http.post(
      Uri.parse('$_baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );
    
    // 4. Handle 401 (token expired)
    if (response.statusCode == 401) {
      // Try to refresh token
      final refreshed = await _refreshToken();
      if (!refreshed) {
        // Token can't be refreshed → log out
        await logout();
      }
      // Retry request with new token
    }
    
    return response;
  }
}
```

#### Backend Verification
```java
// backend/src/main/java/com/intelcrypt/filter/JwtAuthenticationFilter.java
@Component
public class JwtAuthenticationFilter extends OncePerRequestFilter {
    
    @Override
    protected void doFilterInternal(
        HttpServletRequest request,
        HttpServletResponse response,
        FilterChain filterChain
    ) throws ServletException, IOException {
        
        // 1. Extract JWT from Authorization header
        String bearerToken = request.getHeader("Authorization");
        if (bearerToken != null && bearerToken.startsWith("Bearer ")) {
            String token = bearerToken.substring(7);
            
            // 2. Validate JWT signature and expiration
            if (jwtTokenService.isTokenValid(token)) {
                // 3. Extract user ID from JWT payload
                String userId = jwtTokenService.getUserIdFromToken(token);
                
                // 4. Create authentication context
                Authentication auth = new UsernamePasswordAuthenticationToken(
                    userId, null, getAuthorities()
                );
                SecurityContextHolder.setContext(
                    new SecurityContextImpl(auth)
                );
            } else {
                // Invalid or expired token
                response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
                return;
            }
        }
        
        filterChain.doFilter(request, response);
    }
}
```

### JWT Refresh Flow (To Implement)
```dart
// Frontend: When 401 is received
1. Call: await authService.refreshToken()
   ↓
// Backend: AuthController
2. POST /api/auth/refresh-token
3. Verify refresh token is valid
4. Generate new JWT token
5. Return { token, expiresIn }
   ↓
// Frontend: SecureStorageService
6. Save new token
7. Retry original request
```

---

## 🔒 End-to-End Encryption Integration

### Current Setup (Ready to Connect)

#### Frontend Encryption Service
```dart
// lib/src/services/encryption_service.dart
class EncryptionService {
  // Generate RSA key pair on app first launch
  Future<void> initializeKeyPair() async {
    final keypair = await _generateRsaKeyPair();
    await _secureStorage.savePrivateKey(keypair.privateKey);
    // Public key sent to backend during registration
  }
  
  // Encrypt message before sending
  Future<String> encryptMessage(
    String plaintext,
    String recipientPublicKey,
  ) async {
    // 1. Generate random AES session key
    final aesKey = _generateAesKey();
    
    // 2. Encrypt message with AES
    final encrypted = _encryptWithAES(plaintext, aesKey);
    
    // 3. Encrypt AES key with recipient's RSA public key
    final encryptedAesKey = _encryptWithRSA(aesKey, recipientPublicKey);
    
    // 4. Return: { encryptedMessage, encryptedAesKey }
    return jsonEncode({
      'message': base64Encode(encrypted),
      'sessionKey': base64Encode(encryptedAesKey),
    });
  }
  
  // Decrypt received message
  Future<String> decryptMessage(String encryptedPayload) async {
    final json = jsonDecode(encryptedPayload);
    
    // 1. Get private key
    final privateKey = await _secureStorage.getPrivateKey();
    
    // 2. Decrypt AES key with our private key
    final encryptedAesKey = base64Decode(json['sessionKey']);
    final aesKey = _decryptWithRSA(encryptedAesKey, privateKey);
    
    // 3. Decrypt message with AES key
    final encryptedMessage = base64Decode(json['message']);
    final plaintext = _decryptWithAES(encryptedMessage, aesKey);
    
    return plaintext;
  }
}
```

#### Backend Key Exchange
```java
// backend/src/main/java/com/intelcrypt/service/KeyService.java
@Service
public class KeyService {
    
    // User uploads their public key during registration
    public void savePublicKey(String userId, String publicKeyPem) {
        EncryptionKey key = new EncryptionKey();
        key.setUserId(userId);
        key.setPublicKeyPem(publicKeyPem);
        key.setKeyType(KeyType.RSA_4096);
        key.setCreatedAt(LocalDateTime.now());
        encryptionKeyRepository.save(key);
    }
    
    // Retrieve recipient's public key
    public String getPublicKey(String userId) {
        return encryptionKeyRepository
            .findByUserId(userId)
            .map(EncryptionKey::getPublicKeyPem)
            .orElseThrow(() -> new KeyNotFoundException("User " + userId));
    }
    
    // Store encrypted message
    public void storeEncryptedMessage(
        String senderId,
        String recipientId,
        String encryptedContent
    ) {
        Message message = new Message();
        message.setSenderId(senderId);
        message.setRecipientId(recipientId);
        message.setEncryptedContent(encryptedContent);
        message.setTimestamp(LocalDateTime.now());
        messageRepository.save(message);
    }
}
```

---

## 📊 Database Schema (Reference)

### Key Tables in Backend
```sql
-- Users table
CREATE TABLE users (
    id UUID PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(255),
    avatar_url VARCHAR(1000),
    created_at TIMESTAMP NOT NULL
);

-- Encryption keys
CREATE TABLE encryption_keys (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id),
    public_key_pem TEXT NOT NULL,
    key_type VARCHAR(50) NOT NULL,
    created_at TIMESTAMP NOT NULL,
    rotated_at TIMESTAMP
);

-- Messages
CREATE TABLE messages (
    id UUID PRIMARY KEY,
    chat_id UUID NOT NULL,
    sender_id UUID NOT NULL REFERENCES users(id),
    encrypted_content TEXT NOT NULL,
    delivery_status VARCHAR(50) DEFAULT 'pending',
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMP NOT NULL
);

-- Chats
CREATE TABLE chats (
    id UUID PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    is_group BOOLEAN DEFAULT false,
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL
);

-- Chat participants
CREATE TABLE chat_participants (
    id UUID PRIMARY KEY,
    chat_id UUID NOT NULL REFERENCES chats(id),
    user_id UUID NOT NULL REFERENCES users(id),
    joined_at TIMESTAMP NOT NULL,
    muted_until TIMESTAMP
);

-- Audit log
CREATE TABLE audit_log (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id),
    event_type VARCHAR(100) NOT NULL,
    event_details TEXT,
    created_at TIMESTAMP NOT NULL
);
```

---

## 🔧 Implementation Checklist

### Phase 4A: Authentication Integration (3-4 hours)
- [ ] Connect LoginScreen to `/api/auth/login` endpoint
- [ ] Connect registration to `/api/auth/register` endpoint
- [ ] Implement JWT token refresh flow
- [ ] Test biometric authentication flow
- [ ] Verify SplashScreen auto-routing works with real tokens
- [ ] Test logout functionality
- [ ] Add token expiration handling
- [ ] Test 401 error handling and re-login

### Phase 4B: Message API Integration (4-5 hours)
- [ ] Connect ChatListScreen to `/api/chats` endpoint
- [ ] Implement chatListProvider with real API
- [ ] Connect ChatMessageScreen to `/api/messages/chats/{chatId}`
- [ ] Implement message send to `/api/messages` endpoint
- [ ] Add optimistic updates to real backend responses
- [ ] Implement message delete (`DELETE /api/messages/{id}`)
- [ ] Add delivery status updates (pending → sent → delivered)
- [ ] Setup WebSocket for real-time message updates

### Phase 4C: User Profile & Security (2-3 hours)
- [ ] Connect ProfileScreen to `/api/users/profile`
- [ ] Implement profile update endpoint
- [ ] Connect SecurityScreen to `/api/keys` endpoints
- [ ] Implement key rotation flow
- [ ] Add recovery code generation
- [ ] Setup audit log display
- [ ] Test session management endpoints

### Phase 4D: End-to-End Encryption (3-4 hours)
- [ ] Implement real RSA key generation in EncryptionService
- [ ] Implement real AES encryption for messages
- [ ] Test message encryption before sending
- [ ] Test message decryption after receiving
- [ ] Verify key exchange during registration
- [ ] Add encrypted payload in message send
- [ ] Test decryption of received messages
- [ ] Verify fingerprint matching

### Phase 4E: Testing & Bug Fixes (2-3 hours)
- [ ] End-to-end login flow
- [ ] Send and receive messages
- [ ] Check encryption/decryption correctness
- [ ] Test error handling (network, 401, 500, etc.)
- [ ] Test on real Android/iOS devices
- [ ] Performance testing with 1000+ messages
- [ ] Security audit of JWT handling
- [ ] Test key rotation under load

---

## 🌐 API Response Examples

### Login Response
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "refresh_token_here",
  "userId": "550e8400-e29b-41d4-a716-446655440000",
  "email": "user@example.com",
  "name": "John Doe",
  "expiresIn": 3600
}
```

### Get Chats Response
```json
{
  "chats": [
    {
      "id": "chat-123",
      "name": "Alice",
      "avatar": "https://...",
      "lastMessage": "See you tomorrow!",
      "lastMessageTime": "2026-01-08T10:30:00Z",
      "unreadCount": 2,
      "isGroup": false,
      "mutedUntil": null
    }
  ]
}
```

### Send Message Response
```json
{
  "id": "msg-456",
  "chatId": "chat-123",
  "senderId": "user-789",
  "encryptedContent": "{...}",
  "deliveryStatus": "sent",
  "timestamp": "2026-01-08T10:31:00Z",
  "isRead": false
}
```

### Get Messages Response
```json
{
  "messages": [
    {
      "id": "msg-456",
      "chatId": "chat-123",
      "senderId": "user-789",
      "senderName": "Alice",
      "encryptedContent": "{...}",
      "deliveryStatus": "delivered",
      "isRead": true,
      "timestamp": "2026-01-08T10:31:00Z",
      "attachments": []
    }
  ]
}
```

---

## 🛠️ Troubleshooting Guide

### Common Issues & Solutions

#### 401 Unauthorized Errors
**Problem**: All API calls return 401  
**Solutions**:
1. Check JWT is being sent in Authorization header
2. Verify token hasn't expired
3. Test token refresh endpoint
4. Clear secure storage and re-login

#### Message Not Encrypted
**Problem**: Messages appear in plain text in database  
**Solutions**:
1. Verify EncryptionService.encryptMessage() is called
2. Check recipient public key is fetched correctly
3. Verify RSA encryption is working
4. Check AES key generation

#### WebSocket Not Receiving Updates
**Problem**: New messages don't appear automatically  
**Solutions**:
1. Implement WebSocket endpoint in backend
2. Connect Flutter app to WebSocket after login
3. Subscribe to chat channel: `/messages/{chatId}`
4. Update messageListProvider on new message received

#### Biometric Auth Not Working
**Problem**: "Biometric not available" on Android  
**Solutions**:
1. Add permissions in AndroidManifest.xml:
   ```xml
   <uses-permission android:name="android.permission.USE_BIOMETRIC" />
   ```
2. Implement platform channel for biometric calls
3. Test on device with biometric hardware

---

## 📝 Next Steps (Recommended Order)

### Immediate (Today)
1. Start backend on `mvn spring-boot:run`
2. Start frontend on `flutter run`
3. Test basic navigation without API

### Short-term (This week)
1. Implement authentication API integration
2. Connect message API
3. Test send/receive messages
4. Setup WebSocket for real-time

### Medium-term (Next week)
1. End-to-end encryption integration
2. Profile and security APIs
3. Comprehensive testing
4. Performance optimization

### Long-term (Following weeks)
1. Advanced features (groups, file sharing)
2. Voice/video calling
3. Notifications
4. Analytics
5. Production deployment

---

## 📚 Reference Documentation

**Backend Documentation**:
- [Spring Boot 3.2 Docs](https://docs.spring.io/spring-boot/docs/current/reference/html/)
- [Spring Security](https://docs.spring.io/spring-security/reference/index.html)
- [JWT (jjwt)](https://github.com/jwtk/jjwt)

**Frontend Documentation**:
- [Flutter Docs](https://flutter.dev/docs)
- [Riverpod](https://riverpod.dev)
- [GoRouter](https://pub.dev/packages/go_router)
- [HTTP Package](https://pub.dev/packages/http)

**Encryption**:
- [Bouncy Castle (Java)](https://www.bouncycastle.org/java.html)
- [PointyCastle (Dart)](https://pub.dev/packages/pointycastle)

---

**Integration Guide Generated**: January 8, 2026  
**Status**: ✅ **Ready to Begin Backend Integration**  
**Estimated Time to Full Integration**: 15-20 hours  
**Priority**: 🔴 **HIGH** - Blocks feature verification and E2E testing
