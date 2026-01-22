# IntelCrypt Frontend - Production-Ready Flutter Application

A sophisticated, enterprise-grade secure messaging client built with Flutter, featuring end-to-end encryption, Material Design 3, and comprehensive security features.

## 🏗️ Architecture Overview

The frontend follows **Clean Architecture** with clear separation of concerns:

```
lib/
├── main.dart                    # App entry point with Riverpod setup
├── src/
│   ├── models/                 # Data models and DTOs
│   │   ├── user_model.dart
│   │   ├── chat_model.dart
│   │   ├── message_model.dart
│   │   ├── auth_model.dart
│   │   └── models.dart         # Index file
│   │
│   ├── services/               # Business logic & API communication
│   │   ├── api_service.dart    # REST API client with JWT auth
│   │   ├── secure_storage_service.dart  # Encrypted local storage
│   │   ├── encryption_service.dart      # E2E encryption/decryption
│   │   └── services.dart       # Index file
│   │
│   ├── providers/              # Riverpod state management
│   │   ├── auth_provider.dart  # Authentication state & logic
│   │   ├── chat_provider.dart  # Chat list state & operations
│   │   ├── message_provider.dart # Message state & operations
│   │   └── providers.dart      # Index file
│   │
│   └── ui/                     # Presentation layer
│       ├── screens/
│       │   ├── splash_screen.dart
│       │   ├── login_screen.dart
│       │   ├── chat_list_screen.dart
│       │   ├── messaging_screen.dart    # (Placeholder)
│       │   ├── compose_screen.dart      # (Placeholder)
│       │   ├── profile_screen.dart      # (Placeholder)
│       │   ├── security_screen.dart     # (Placeholder)
│       │   └── admin_screen.dart        # (Placeholder)
│       │
│       ├── widgets/
│       │   ├── custom_input_field.dart
│       │   ├── chat_bubble.dart         # (Placeholder)
│       │   ├── message_tile.dart        # (Placeholder)
│       │   ├── encryption_indicator.dart # (Placeholder)
│       │   └── delivery_indicator.dart  # (Placeholder)
│       │
│       └── theme/
│           └── app_theme.dart           # Material Design 3 configuration
```

## 📦 Dependencies

### Core Framework
- **Flutter 3.10+** - UI framework
- **Dart 3.10+** - Programming language
- **Material Design 3** - Design system

### State Management
- **flutter_riverpod ^2.4.0** - Reactive state management
- **riverpod_annotation ^2.3.0** - Code generation support

### Networking & APIs
- **http ^1.1.0** - HTTP client
- **connectivity_plus ^5.0.0** - Connectivity monitoring
- **json_annotation ^4.8.1** - JSON serialization

### Security & Encryption
- **flutter_secure_storage ^9.0.0** - Secure local storage (Android Keystore, iOS Keychain)
- **encrypt ^4.0.0** - AES & asymmetric encryption
- **pointycastle ^3.7.0** - Cryptographic primitives
- **local_auth ^2.1.0** - Biometric authentication

### Storage & Database
- **sqflite ^2.3.0** - SQLite local database
- **hive ^2.2.0** - NoSQL local storage
- **path_provider ^2.1.0** - File system access

### UI Components
- **material_design_icons_flutter ^7.0.7296** - Material icons
- **cached_network_image ^3.3.0** - Efficient image caching
- **image_picker ^1.0.0** - File picker
- **flutter_local_notifications ^16.2.0** - Push notifications

### Utilities
- **intl ^0.19.0** - Internationalization
- **logger ^2.0.0** - Logging
- **device_info_plus ^9.1.0** - Device information
- **package_info_plus ^5.0.0** - App version info
- **share_plus ^7.2.0** - Share functionality

## 🔐 Security Features

### Authentication
- **JWT Token Management**: Access and refresh tokens stored securely
- **Biometric Support**: Fingerprint and face recognition
- **Session Management**: Track devices and active sessions
- **Auto-lock**: Session timeout after inactivity

### Encryption
- **End-to-End Encryption (E2E)**: Message content encrypted before transmission
- **AES-256-GCM**: Symmetric encryption for messages
- **Hybrid Encryption**: RSA for key exchange, AES for data
- **Key Rotation**: Automatic encryption key lifecycle management
- **Secure Key Storage**: Encryption keys stored in device secure storage

### Data Protection
- **No Plaintext Storage**: All sensitive data encrypted at rest
- **Masked Display**: Message previews and user emails masked in UI
- **Secure Logging**: Sensitive data excluded from logs
- **Automatic Cleanup**: Session tokens cleared on logout
- **Screenshot Detection**: Warnings for security-sensitive screens

## 🎨 UI/UX Design

### Material Design 3 Implementation
- **Light & Dark Themes**: Full theme support with security-focused colors
- **Minimalist Design**: Clean, professional appearance
- **Smooth Animations**: Polished transitions between screens
- **Responsive Layout**: Optimized for mobile and tablet

### Color Palette
- **Primary**: Deep Blue (#1565C0) - Trust & Security
- **Secondary**: Cyan (#00BCD4) - Innovation
- **Tertiary**: Purple (#7C4DFF) - Privacy
- **Encryption Indicators**:
  - Green (#43A047) - High encryption
  - Orange (#FFA726) - Medium encryption
  - Red (#E53935) - Low encryption
  - Gray (#9E9E9E) - No encryption

### Key Screens

#### Splash Screen
- Branding with animated logo
- Loading indicator during initialization
- Minimal information display

#### Login Screen
- Email and password fields
- Remember me option
- Biometric login button
- Forgot password link
- Sign up navigation

#### Chat List Screen
- Conversation list with avatars
- Real-time unread badges
- Classification level indicators
- Swipe actions (archive/delete)
- Search functionality
- Last message preview (masked)
- Online status indicators

#### Messaging Screen (Placeholder)
- Message thread with E2E indicators
- Message bubbles with delivery status
- Auto-load previous messages
- Self-destructing message UI
- Attachment display
- Typing indicators
- Read receipts

#### Compose Screen (Placeholder)
- File picker with encryption progress
- Message length counter
- Attachment preview
- Send/schedule options

#### Profile Screen (Placeholder)
- User profile information
- Clearance level display
- Key regeneration options
- Settings management
- Device management

#### Security Screen (Placeholder)
- Encryption level selector
- Key fingerprint verification
- Audit logs
- Activity alerts
- Session management

#### Admin Screen (Placeholder)
- User management (admin only)
- Audit logs (admin only)
- System configuration (admin only)
- Role-based UI elements

## 📱 State Management (Riverpod)

### Auth Provider (`auth_provider.dart`)
Manages user authentication state and session lifecycle.

**State**:
```dart
AuthState {
  bool isAuthenticated
  AuthToken? token
  User? currentUser
  bool isLoading
  String? error
  DateTime? lastRefresh
  bool requiresMfaSetup
  Session? activeSession
}
```

**Notifier Methods**:
- `initialize()` - Load stored tokens and restore session
- `login(email, password)` - Authenticate user
- `signup(username, email, password, confirmPassword)` - Register new account
- `refreshAccessToken()` - Refresh expired tokens
- `logout()` - Clear session and stored tokens
- `changePassword(currentPassword, newPassword)` - Update password
- `updateProfile(...)` - Modify user profile

### Chat Provider (`chat_provider.dart`)
Manages chat list and conversation operations.

**State**:
```dart
ChatListState {
  List<Chat> chats
  bool isLoading
  String? error
  String searchQuery
  int totalUnread
  DateTime? lastFetch
}
```

**Notifier Methods**:
- `fetchChats()` - Load all conversations
- `createDirectChat(userId)` - Start 1-on-1 chat
- `createGroupChat(name, participantIds, description)` - Create group
- `archiveChat(chatId)` - Archive conversation
- `muteChat(chatId, duration)` - Mute notifications
- `deleteChat(chatId)` - Remove conversation
- `setSearchQuery(query)` - Filter chats

### Message Provider (`message_provider.dart`)
Manages message list and message operations.

**State**:
```dart
MessageListState {
  Map<String, List<Message>> messagesByChat
  bool isLoading
  String? error
  String? activeChat
  int pageSize
}
```

**Notifier Methods**:
- `fetchMessages(chatId)` - Load message thread
- `loadMoreMessages(chatId)` - Pagination
- `sendMessage(chatId, content, encrypted, ...)` - Send encrypted message
- `markAsRead(chatId, messageId)` - Mark read
- `markAllAsRead(chatId)` - Mark thread read
- `deleteMessage(chatId, messageId)` - Remove message
- `searchMessages(chatId, query)` - Full-text search

## 🔌 API Integration

### Endpoints (Backend)

**Authentication**
- `POST /auth/login` - User login
- `POST /auth/signup` - User registration
- `POST /auth/refresh` - Token refresh
- `POST /auth/logout` - Session logout
- `POST /auth/change-password` - Update password

**Chats**
- `GET /chats` - List conversations
- `POST /chats/direct` - Create DM
- `POST /chats/group` - Create group
- `PUT /chats/{id}` - Update chat
- `DELETE /chats/{id}` - Delete chat

**Messages**
- `GET /chats/{id}/messages` - Fetch messages
- `POST /chats/{id}/messages` - Send message
- `PUT /chats/{id}/messages/{msgId}/read` - Mark read
- `DELETE /chats/{id}/messages/{msgId}` - Delete message

**Users**
- `GET /users/me` - Current user profile
- `GET /users/{id}` - User details
- `PUT /users/me` - Update profile
- `GET /users/search?q=` - Search users

## 💾 Local Storage Strategy

### Secure Storage (Encrypted)
- **Access Tokens**: JWT access token
- **Refresh Tokens**: Long-lived refresh token
- **Encryption Keys**: Message encryption keys
- **Session ID**: Active session identifier
- **Device ID**: Unique device identifier
- **Biometric Settings**: Enrollment status

### SQLite Database
- **Message Cache**: Recent messages for offline access
- **Chat Metadata**: Conversation information
- **User Cache**: Known user profiles
- **Encryption Status**: Key versioning and rotation

### Hive (NoSQL)
- **User Preferences**: App settings
- **Chat Sorting**: Conversation order
- **Drafts**: Unsent message content
- **Local Search Index**: Fast message searching

## 🧪 Testing Strategy

### Unit Tests
- API service mock responses
- Encryption/decryption logic
- Data model parsing
- Validation functions

### Widget Tests
- Custom input field behavior
- Chat list tile interactions
- Theme application
- Error state rendering

### Integration Tests
- Login flow
- Chat creation
- Message sending
- Session management

## 📊 Performance Optimization

### UI Performance
- Lazy loading of message lists
- Pagination for large datasets
- Image caching and resizing
- Widget rebuild optimization with Riverpod

### Network Optimization
- Request batching
- Connection pooling
- Automatic retry with exponential backoff
- Bandwidth-aware loading

### Memory Management
- Dispose of controllers properly
- Limit cached messages in memory
- Clean up file handles
- Efficient collection handling

## 🚀 Deployment

### Build Requirements
- Flutter SDK 3.10.1+
- Dart 3.10.1+
- Android SDK (for Android build)
- Xcode (for iOS build)

### Build Commands

**Debug Build**
```bash
flutter pub get
flutter run -d [device-id]
```

**Release Build (Android)**
```bash
flutter build apk --release
flutter build aab --release
```

**Release Build (iOS)**
```bash
flutter build ios --release
```

### Configuration Files
- `android/app/build.gradle` - Android configuration
- `ios/Runner.xcodeproj` - iOS configuration
- `pubspec.yaml` - Dependencies and versioning

## 📝 Code Generation

Generate code files with:
```bash
flutter pub run build_runner build
flutter pub run build_runner watch  # Continuous generation
```

This generates:
- Riverpod providers (`.g.dart` files)
- JSON serialization code
- Hive adapters

## 🔄 Future Enhancements

- [ ] Video/audio calls integration
- [ ] Voice messaging
- [ ] Message reactions/emoji
- [ ] Animated stickers
- [ ] File sharing with progress
- [ ] Link previews
- [ ] AI-powered search
- [ ] Message translation
- [ ] Advanced user blocking
- [ ] Channel management UI
- [ ] 2FA/MFA setup screen
- [ ] Backup/restore functionality

## 📄 License

This project is proprietary and confidential for IntelCrypt classified messaging system.

## 👥 Team

Built for secure enterprise communications.
