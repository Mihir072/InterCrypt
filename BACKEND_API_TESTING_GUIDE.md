# Backend API Testing Guide

## 🚀 Quick Start

### Prerequisites
- Spring Boot backend running: `http://localhost:8080`
- postman/curl installed for testing
- Database initialized

### Test the Backend Endpoints

## 📡 Authentication Endpoints

### 1. Register New User

**Endpoint**: `POST /api/auth/register`

**cURL**:
```bash
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "email": "test@example.com",
    "password": "SecurePass123!"
  }'
```

**Request Body**:
```json
{
  "username": "testuser",
  "email": "test@example.com",
  "password": "SecurePass123!"
}
```

**Expected Response** (200 OK):
```json
{
  "message": "User registered successfully",
  "token": {
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "tokenType": "Bearer",
    "expiresIn": 3600,
    "issuedAt": "2024-01-15T10:30:00Z",
    "scopes": [],
    "userId": "user-123"
  },
  "userId": "user-123",
  "username": "testuser",
  "email": "test@example.com",
  "requiresMfaSetup": false,
  "sessionId": "session-456"
}
```

---

### 2. Login

**Endpoint**: `POST /api/auth/login`

**cURL**:
```bash
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "SecurePass123!",
    "rememberMe": true,
    "useBiometric": false
  }'
```

**Request Body**:
```json
{
  "email": "test@example.com",
  "password": "SecurePass123!",
  "rememberMe": true,
  "deviceId": "device-001",
  "useBiometric": false
}
```

**Expected Response** (200 OK):
```json
{
  "message": "Login successful",
  "token": {
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "tokenType": "Bearer",
    "expiresIn": 3600,
    "issuedAt": "2024-01-15T10:30:00Z",
    "scopes": [],
    "userId": "user-123"
  },
  "userId": "user-123",
  "username": "testuser",
  "email": "test@example.com",
  "requiresMfaSetup": false,
  "sessionId": "session-456"
}
```

**Save the `accessToken` for subsequent requests!**

---

### 3. Get Current User (Authenticated)

**Endpoint**: `GET /api/auth/me`

**cURL**:
```bash
curl -X GET http://localhost:8080/api/auth/me \
  -H "Authorization: Bearer {accessToken}"
```

**Replace `{accessToken}` with the token from login response**

**Expected Response** (200 OK):
```json
{
  "id": "user-123",
  "username": "testuser",
  "email": "test@example.com",
  "profileImageUrl": null,
  "roles": ["USER"],
  "clearanceLevel": "LOW",
  "isOnline": true,
  "lastSeen": "2024-01-15T10:30:00Z",
  "createdAt": "2024-01-15T10:00:00Z"
}
```

---

### 4. Refresh Token

**Endpoint**: `POST /api/auth/refresh`

**cURL**:
```bash
curl -X POST http://localhost:8080/api/auth/refresh \
  -H "Content-Type: application/json" \
  -d '{
    "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }'
```

**Expected Response** (200 OK):
```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "tokenType": "Bearer",
  "expiresIn": 3600,
  "issuedAt": "2024-01-15T10:35:00Z",
  "scopes": [],
  "userId": "user-123"
}
```

---

### 5. Logout

**Endpoint**: `POST /api/auth/logout`

**cURL**:
```bash
curl -X POST http://localhost:8080/api/auth/logout \
  -H "Authorization: Bearer {accessToken}" \
  -H "Content-Type: application/json" \
  -d '{}'
```

**Expected Response** (200 OK):
```json
{
  "message": "Logged out successfully"
}
```

---

### 6. Change Password

**Endpoint**: `POST /api/auth/change-password`

**cURL**:
```bash
curl -X POST http://localhost:8080/api/auth/change-password \
  -H "Authorization: Bearer {accessToken}" \
  -H "Content-Type: application/json" \
  -d '{
    "currentPassword": "SecurePass123!",
    "newPassword": "NewPassword456!"
  }'
```

**Expected Response** (200 OK):
```json
{
  "message": "Password changed successfully"
}
```

---

## 📱 Chat Endpoints

### 1. Get All Chats

**Endpoint**: `GET /api/chats`

**cURL**:
```bash
curl -X GET http://localhost:8080/api/chats \
  -H "Authorization: Bearer {accessToken}"
```

**Expected Response** (200 OK):
```json
[
  {
    "id": "chat-123",
    "name": "John Doe",
    "type": "DIRECT",
    "participantIds": ["user-123", "user-456"],
    "lastMessage": "See you tomorrow!",
    "lastMessageTime": "2024-01-15T09:30:00Z",
    "unreadCount": 0,
    "isArchived": false,
    "isMuted": false,
    "createdAt": "2024-01-10T15:00:00Z"
  }
]
```

---

### 2. Create Direct Chat

**Endpoint**: `POST /api/chats/direct`

**cURL**:
```bash
curl -X POST http://localhost:8080/api/chats/direct \
  -H "Authorization: Bearer {accessToken}" \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "user-456"
  }'
```

**Expected Response** (201 Created):
```json
{
  "id": "chat-789",
  "name": "John Doe",
  "type": "DIRECT",
  "participantIds": ["user-123", "user-456"],
  "lastMessage": null,
  "lastMessageTime": null,
  "unreadCount": 0,
  "isArchived": false,
  "isMuted": false,
  "createdAt": "2024-01-15T10:30:00Z"
}
```

---

## 💬 Message Endpoints

### 1. Send Message

**Endpoint**: `POST /api/chats/{chatId}/messages`

**cURL**:
```bash
curl -X POST http://localhost:8080/api/chats/chat-123/messages \
  -H "Authorization: Bearer {accessToken}" \
  -H "Content-Type: application/json" \
  -d '{
    "content": "Hello! How are you?",
    "contentEncrypted": "encryptedContent...",
    "encryption": {
      "algorithm": "RSA_AES_HYBRID",
      "encryptedKey": "...",
      "iv": "..."
    }
  }'
```

**Expected Response** (201 Created):
```json
{
  "id": "msg-123",
  "chatId": "chat-123",
  "senderId": "user-123",
  "content": "Hello! How are you?",
  "contentEncrypted": "encryptedContent...",
  "status": "SENT",
  "createdAt": "2024-01-15T10:30:00Z",
  "isDeleted": false,
  "readAt": null
}
```

---

### 2. Get Messages

**Endpoint**: `GET /api/chats/{chatId}/messages`

**cURL**:
```bash
curl -X GET "http://localhost:8080/api/chats/chat-123/messages?limit=50&beforeMessageId=msg-123" \
  -H "Authorization: Bearer {accessToken}"
```

**Query Parameters**:
- `limit` (optional, default=50): Number of messages to fetch
- `beforeMessageId` (optional): ID of message to fetch before (for pagination)

**Expected Response** (200 OK):
```json
[
  {
    "id": "msg-122",
    "chatId": "chat-123",
    "senderId": "user-456",
    "content": "Hi there!",
    "contentEncrypted": "...",
    "status": "DELIVERED",
    "createdAt": "2024-01-15T10:25:00Z",
    "isDeleted": false,
    "readAt": null
  },
  {
    "id": "msg-121",
    "chatId": "chat-123",
    "senderId": "user-123",
    "content": "Hello!",
    "contentEncrypted": "...",
    "status": "READ",
    "createdAt": "2024-01-15T10:20:00Z",
    "isDeleted": false,
    "readAt": "2024-01-15T10:22:00Z"
  }
]
```

---

### 3. Mark Message as Read

**Endpoint**: `PUT /api/chats/{chatId}/messages/{messageId}/read`

**cURL**:
```bash
curl -X PUT http://localhost:8080/api/chats/chat-123/messages/msg-122/read \
  -H "Authorization: Bearer {accessToken}" \
  -H "Content-Type: application/json" \
  -d '{}'
```

**Expected Response** (200 OK):
```json
{
  "message": "Message marked as read"
}
```

---

## 👤 User Endpoints

### 1. Search Users

**Endpoint**: `GET /api/users/search`

**cURL**:
```bash
curl -X GET "http://localhost:8080/api/users/search?q=john&limit=10" \
  -H "Authorization: Bearer {accessToken}"
```

**Query Parameters**:
- `q` (required): Search query
- `limit` (optional, default=10): Maximum results

**Expected Response** (200 OK):
```json
[
  {
    "id": "user-456",
    "username": "john_doe",
    "email": "john@example.com",
    "profileImageUrl": "https://...",
    "roles": ["USER"],
    "clearanceLevel": "LOW",
    "isOnline": true,
    "lastSeen": "2024-01-15T10:30:00Z",
    "createdAt": "2024-01-01T00:00:00Z"
  }
]
```

---

## 🔑 Key Management Endpoints

### 1. Generate Key Pair

**Endpoint**: `POST /api/keys/generate`

**cURL**:
```bash
curl -X POST http://localhost:8080/api/keys/generate \
  -H "Authorization: Bearer {accessToken}" \
  -H "Content-Type: application/json" \
  -d '{}'
```

**Expected Response** (201 Created):
```json
{
  "keyId": "key-123",
  "algorithm": "RSA_2048",
  "publicKey": "-----BEGIN PUBLIC KEY-----...",
  "keyStatus": "ACTIVE",
  "generatedAt": "2024-01-15T10:30:00Z"
}
```

---

## ⚠️ Error Responses

### 401 Unauthorized
```json
{
  "timestamp": "2024-01-15T10:30:00Z",
  "status": 401,
  "error": "Unauthorized",
  "message": "Invalid or expired token"
}
```

### 400 Bad Request
```json
{
  "timestamp": "2024-01-15T10:30:00Z",
  "status": 400,
  "error": "Bad Request",
  "message": "Invalid email format",
  "details": {
    "field": "email",
    "rejectedValue": "invalid-email"
  }
}
```

### 403 Forbidden
```json
{
  "timestamp": "2024-01-15T10:30:00Z",
  "status": 403,
  "error": "Forbidden",
  "message": "Access denied"
}
```

### 404 Not Found
```json
{
  "timestamp": "2024-01-15T10:30:00Z",
  "status": 404,
  "error": "Not Found",
  "message": "User not found"
}
```

---

## 🧪 Testing Workflow

### Complete Flow

1. **Register User**
   ```bash
   POST /api/auth/register
   → Get accessToken and refreshToken
   ```

2. **Verify Login Works**
   ```bash
   POST /api/auth/login
   → Get new tokens
   ```

3. **Get Current User**
   ```bash
   GET /api/auth/me (with accessToken)
   → Verify token is valid
   ```

4. **Search for Another User**
   ```bash
   GET /api/users/search?q=testuser
   → Find a user to chat with
   ```

5. **Create Direct Chat**
   ```bash
   POST /api/chats/direct
   → Create chat with found user
   ```

6. **Send Message**
   ```bash
   POST /api/chats/{chatId}/messages
   → Send encrypted message
   ```

7. **Get Messages**
   ```bash
   GET /api/chats/{chatId}/messages
   → Verify message appears
   ```

8. **Mark as Read**
   ```bash
   PUT /api/chats/{chatId}/messages/{msgId}/read
   → Update message status
   ```

9. **Refresh Token**
   ```bash
   POST /api/auth/refresh
   → Get new token before expiry
   ```

10. **Logout**
    ```bash
    POST /api/auth/logout
    → Clear session
    ```

---

## 📋 Postman Collection

Create a Postman collection with these requests for easy testing:

1. Register → Get Token
2. Login → Get Token  
3. Get Current User
4. Search Users
5. Create Chat
6. Send Message
7. Get Messages
8. Mark Read
9. Refresh Token
10. Logout

Set Postman variable `{{token}}` = `response.token.accessToken`

Use in headers: `Authorization: Bearer {{token}}`

---

## ✅ All Endpoints Status

### Authentication (5/5)
- ✅ POST   /api/auth/register
- ✅ POST   /api/auth/login
- ✅ GET    /api/auth/me
- ✅ POST   /api/auth/refresh
- ✅ POST   /api/auth/logout
- ⚠️ POST   /api/auth/change-password (needs testing)

### Chats (8/8)
- ⚠️ GET    /api/chats
- ⚠️ POST   /api/chats/direct
- ⚠️ POST   /api/chats/group
- ⚠️ PUT    /api/chats/{id}
- ⚠️ PUT    /api/chats/{id}/archive
- ⚠️ DELETE /api/chats/{id}

### Messages (5/5)
- ⚠️ GET    /api/chats/{id}/messages
- ⚠️ POST   /api/chats/{id}/messages
- ⚠️ PUT    /api/chats/{id}/messages/{id}/read
- ⚠️ DELETE /api/chats/{id}/messages/{id}
- ⚠️ GET    /api/chats/{id}/messages/search

### Users (2/2)
- ⚠️ GET    /api/users/me
- ⚠️ GET    /api/users/search

### Keys (3/3)
- ⚠️ POST   /api/keys/generate
- ⚠️ POST   /api/keys/rotate
- ⚠️ GET    /api/keys/status

---

**Legend**:
- ✅ Verified working
- ⚠️ Needs testing with actual data
- ❌ Not implemented

