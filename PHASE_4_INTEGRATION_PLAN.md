# Phase 4: Backend Integration Testing

## Overview
Phase 4 focuses on connecting the Flutter frontend to the Spring Boot backend API, ensuring all endpoints are properly integrated and tested end-to-end.

## Phases

### Phase 4A: Authentication API Integration ⚡ IN PROGRESS
**Objective:** Implement login/signup flow with JWT token storage and automatic token refresh

#### Tasks:
1. ✅ **API Service Foundation**
   - [x] HTTP client setup with headers, timeouts, error handling
   - [x] Token management (set, get, clear tokens)
   - [x] Auth endpoints: login, signup, refresh, logout
   - [ ] Integrate with secure_storage for JWT persistence
   - [ ] Implement automatic token refresh on 401

2. ⚡ **Secure Token Storage**
   - [ ] Setup flutter_secure_storage plugin
   - [ ] Create TokenStorageService for persistence
   - [ ] Load tokens on app startup
   - [ ] Handle token expiration gracefully

3. ⚡ **Auth Provider Integration**
   - [ ] Create AuthProvider (Riverpod)
   - [ ] Implement login/signup state management
   - [ ] Auto-refresh tokens before expiration
   - [ ] Handle 401 responses and re-authentication

4. ⚡ **UI Integration**
   - [ ] Update LoginScreen to use real API
   - [ ] Update SignupScreen to use real API
   - [ ] Add loading states and error messages
   - [ ] Test login flow end-to-end

---

### Phase 4B: Chat API Integration
**Objective:** Connect ChatListScreen to real chat data from backend

#### Tasks:
1. **Chat Provider**
   - [ ] Create ChatProvider (Riverpod) with FutureProvider
   - [ ] Implement getChats(), getChat(), createDirectChat(), createGroupChat()
   - [ ] Handle chat list updates and real-time changes
   - [ ] Implement pagination/infinite scroll

2. **Chat List Screen**
   - [ ] Connect to ChatProvider instead of mock data
   - [ ] Implement pull-to-refresh for data reload
   - [ ] Show loading/error states
   - [ ] Handle chat deletion, archiving, muting

3. **Chat Actions**
   - [ ] Create chat context menu (archive, mute, delete)
   - [ ] Implement search functionality
   - [ ] Add filters (unread, archived, etc.)

---

### Phase 4C: Message API Integration
**Objective:** Connect ChatMessageScreen to real messages with send/receive

#### Tasks:
1. **Message Provider**
   - [ ] Create MessageProvider (Riverpod)
   - [ ] Implement getMessages(), sendMessage(), deleteMessage()
   - [ ] Implement pagination for message history
   - [ ] Handle message delivery status updates

2. **Message Handling**
   - [ ] Send messages with real encryption
   - [ ] Receive messages from API
   - [ ] Update message status (sending → sent → delivered → read)
   - [ ] Handle failed message resend

3. **UI Updates**
   - [ ] Connect ChatMessageScreen to MessageProvider
   - [ ] Show real delivery status indicators
   - [ ] Implement message actions (delete, copy, etc.)
   - [ ] Add typing indicators (if implemented)

---

### Phase 4D: WebSocket Real-time Integration
**Objective:** Setup WebSocket for real-time message updates

#### Tasks:
1. **WebSocket Setup**
   - [ ] Create WebSocketService with auto-reconnect
   - [ ] Implement connection lifecycle (connect, disconnect, reconnect)
   - [ ] Handle heartbeats/pings

2. **Event Streaming**
   - [ ] Subscribe to message events
   - [ ] Subscribe to chat updates
   - [ ] Subscribe to presence changes (online/offline)
   - [ ] Update UI in real-time

3. **Integration**
   - [ ] Merge WebSocket and HTTP data sources
   - [ ] Ensure message consistency

---

### Phase 4E: End-to-End Encryption
**Objective:** Implement real E2E encryption for messages

#### Tasks:
1. **RSA/AES Encryption**
   - [ ] Generate user RSA key pair on signup
   - [ ] Encrypt messages with recipient's RSA public key
   - [ ] Decrypt messages with user's RSA private key
   - [ ] Store encrypted private key securely

2. **Group Chat Encryption**
   - [ ] Generate shared AES key for group
   - [ ] Encrypt with AES before sending
   - [ ] Decrypt received messages

3. **Key Management**
   - [ ] Key rotation
   - [ ] Revoking compromised keys
   - [ ] Recovery codes

---

## Backend Endpoints Reference

### Authentication
```
POST   /api/auth/register         - Register new user
POST   /api/auth/login            - Login
POST   /api/auth/refresh          - Refresh token
POST   /api/auth/change-password  - Change password
GET    /api/auth/me               - Get current user
```

### Chats
```
GET    /api/chats                 - Get all chats
GET    /api/chats/{id}            - Get chat by ID
POST   /api/chats/direct          - Create direct chat
POST   /api/chats/group           - Create group chat
PUT    /api/chats/{id}            - Update chat
PUT    /api/chats/{id}/archive    - Archive chat
PUT    /api/chats/{id}/unarchive  - Unarchive chat
PUT    /api/chats/{id}/mute       - Mute chat
PUT    /api/chats/{id}/unmute     - Unmute chat
DELETE /api/chats/{id}            - Delete chat
```

### Messages
```
GET    /api/chats/{id}/messages                 - Get messages
POST   /api/chats/{id}/messages                 - Send message
PUT    /api/chats/{id}/messages/{msgId}/read   - Mark as read
PUT    /api/chats/{id}/messages/read-all       - Mark all as read
DELETE /api/chats/{id}/messages/{msgId}        - Delete message
GET    /api/chats/{id}/messages/search         - Search messages
```

### Users
```
GET    /api/users/me              - Get current user
GET    /api/users/{id}            - Get user by ID
PUT    /api/users/me              - Update profile
GET    /api/users/search          - Search users
```

### Keys
```
POST   /api/keys/generate         - Generate key pair
POST   /api/keys/rotate           - Rotate keys
GET    /api/keys/status           - Get key status
```

---

## Implementation Checklist

### Phase 4A - Authentication
- [ ] Secure storage setup
- [ ] Auto token refresh implementation
- [ ] Login screen integration
- [ ] Signup screen integration
- [ ] Token error handling
- [ ] End-to-end login flow test

### Phase 4B - Chats
- [ ] Chat provider implementation
- [ ] Chat list loading
- [ ] Chat creation
- [ ] Chat actions (archive, delete, etc.)
- [ ] Chat search and filtering
- [ ] End-to-end chat flow test

### Phase 4C - Messages
- [ ] Message provider implementation
- [ ] Message loading (pagination)
- [ ] Message sending
- [ ] Message deletion
- [ ] Delivery status tracking
- [ ] End-to-end message flow test

### Phase 4D - WebSocket
- [ ] WebSocket service implementation
- [ ] Real-time event handling
- [ ] Connection management
- [ ] Message streaming
- [ ] End-to-end real-time test

### Phase 4E - Encryption
- [ ] RSA key pair generation
- [ ] Message encryption
- [ ] Message decryption
- [ ] Group chat encryption
- [ ] Key rotation
- [ ] End-to-end encryption test

---

## Testing Strategy

1. **Unit Tests**
   - API service methods
   - Encryption/decryption logic
   - State management providers

2. **Widget Tests**
   - UI components with mock data
   - State changes and updates
   - Error handling UI

3. **Integration Tests**
   - Full login flow
   - Message send/receive
   - Real-time updates

4. **Manual Testing**
   - Backend server running locally
   - Two devices/simulators
   - End-to-end message exchange

---

## Status
- **Phase 4A**: IN PROGRESS (Setup secure storage & token refresh)
- **Phase 4B**: NOT STARTED
- **Phase 4C**: NOT STARTED
- **Phase 4D**: NOT STARTED
- **Phase 4E**: NOT STARTED

**Last Updated**: Phase 4 Initiation
