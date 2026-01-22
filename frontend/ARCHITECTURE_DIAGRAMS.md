# IntelCrypt - Visual Architecture & Data Flow

---

## 📊 Application Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                         INTELCRYPT APPLICATION                       │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌──────────────────────── PRESENTATION LAYER ───────────────────┐ │
│  │                                                                │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │ │
│  │  │   Screens    │  │   Widgets    │  │    Theme     │       │ │
│  │  ├──────────────┤  ├──────────────┤  ├──────────────┤       │ │
│  │  │• SplashScreen│  │• ChatTile    │  │• Material 3  │       │ │
│  │  │• LoginScreen │  │• MsgBubble   │  │• Light/Dark  │       │ │
│  │  │• ChatList    │  │• InputField  │  │• Colors      │       │ │
│  │  │• ChatMsg     │  │• CustomInput │  │• Typography  │       │ │
│  │  │• Profile     │  │              │  │              │       │ │
│  │  │• Security    │  │              │  │              │       │ │
│  │  └──────────────┘  └──────────────┘  └──────────────┘       │ │
│  │                          ↓                                    │ │
│  │  ┌────────────────── ROUTING LAYER ──────────────────┐      │ │
│  │  │  GoRouter: splash → login → chats → messaging    │      │ │
│  │  └────────────────────────────────────────────────────┘      │ │
│  └──────────────────────────────────────────────────────────────┘ │
│                           ↓                                       │
│  ┌─────────────── STATE MANAGEMENT (Riverpod) ──────────────┐   │
│  │                                                            │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │   │
│  │  │ Auth Provider│  │ Chat Provider│  │ Msg Provider │   │   │
│  │  ├──────────────┤  ├──────────────┤  ├──────────────┤   │   │
│  │  │• authToken   │  │• chatList    │  │• messageList │   │   │
│  │  │• currentUser │  │• selectedChat│  │• sendMessage │   │   │
│  │  │• isAuth      │  │• chatDetails │  │• encrypted   │   │   │
│  │  │• login       │  │• archiveChat │  │• decrypted   │   │   │
│  │  │• logout      │  │              │  │              │   │   │
│  │  └──────────────┘  └──────────────┘  └──────────────┘   │   │
│  │                                                            │   │
│  │  All use AsyncValue for reactive loading/error states    │   │
│  └────────────────────────────────────────────────────────────┘   │
│                           ↓                                       │
│  ┌──────────────── BUSINESS LOGIC LAYER ─────────────────┐       │
│  │                                                        │       │
│  │  ┌─────────────────────────────────────────────────┐ │       │
│  │  │            Models (Data Classes)                │ │       │
│  │  │  • User • Chat • Message • AuthToken           │ │       │
│  │  │  • Chat supports: direct, group, broadcast     │ │       │
│  │  │  • Message has delivery status tracking        │ │       │
│  │  │  • AuthToken manages JWT lifecycle             │ │       │
│  │  └─────────────────────────────────────────────────┘ │       │
│  │                                                        │       │
│  │  ┌─────────────────────────────────────────────────┐ │       │
│  │  │            Services Layer                       │ │       │
│  │  │  • ApiService (REST + JWT interceptor)         │ │       │
│  │  │  • SecureStorageService (Keystore/Keychain)    │ │       │
│  │  │  • EncryptionService (AES/RSA ready)           │ │       │
│  │  └─────────────────────────────────────────────────┘ │       │
│  │                                                        │       │
│  └────────────────────────────────────────────────────────┘       │
│                           ↓                                       │
│  ┌────────────── EXTERNAL INTEGRATIONS ─────────────────┐        │
│  │                                                      │        │
│  │  Backend API ────────→ Spring Boot 3.2.1            │        │
│  │  (JWT Auth + AES Encryption)                        │        │
│  │                                                      │        │
│  │  Secure Storage ──────→ Flutter Secure Storage     │        │
│  │  (Platform-native: Keychain/Keystore)              │        │
│  │                                                      │        │
│  │  Biometric Auth ──────→ Local Auth Package         │        │
│  │  (Fingerprint/Face)                                │        │
│  │                                                      │        │
│  └──────────────────────────────────────────────────────┘        │
│                                                                   │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 🔄 Authentication Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                    USER AUTHENTICATION FLOW                      │
└─────────────────────────────────────────────────────────────────┘

   APP START
     ↓
   [SplashScreen]
     ↓
   Check authTokenProvider
     ├─→ Token exists?
     │   ├─→ YES: Verify in SecureStorageService
     │   │   ├─→ Valid? → Navigate to ChatListScreen ✓
     │   │   └─→ Expired? → Call refreshToken() → Navigate
     │   │
     │   └─→ NO: Navigate to LoginScreen
     │        ↓
     │     [LoginScreen]
     │        ├─→ Email input
     │        ├─→ Password input
     │        ├─→ Biometric toggle (optional)
     │        └─→ Submit
     │           ↓
     │      loginProvider
     │        ├─→ Call ApiService.login()
     │        ├─→ Receive JWT (access + refresh)
     │        ├─→ Save to SecureStorageService
     │        └─→ Update authTokenProvider
     │           ↓
     │      Update currentUserProvider
     │           ↓
     │      Navigate to ChatListScreen ✓
```

---

## 💬 Messaging Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                    MESSAGE SENDING/RECEIVING                     │
└─────────────────────────────────────────────────────────────────┘

SENDING:
   MessageInputField (user types)
     ↓
   [User taps Send]
     ↓
   sendMessageProvider (FutureProvider)
     ├─→ Get selectedChatProvider (chat ID)
     ├─→ Get authTokenProvider (JWT token)
     ├─→ Optional: encryptionService.encryptMessage()
     ├─→ Call ApiService.sendMessage(ChatRequest)
     │   └─→ Auto-add JWT header
     │   └─→ Send over HTTPS
     ├─→ Return Message object
     └─→ Update messageListProvider
         (Status: pending → sent → delivered → read)


RECEIVING:
   App Background
     ↓
   Backend sends notification (FCM/APNs)
     ↓
   messageListProvider (FutureProvider + polling)
     ├─→ Check selectedChatProvider (which chat)
     ├─→ Fetch messages from ApiService
     ├─→ Call decryptedMessageProvider for each
     │   └─→ encryptionService.decryptMessage()
     └─→ Update UI with MessageBubbles
         (Status: delivery indicator)
         
   User reads message
     ↓
   Call ApiService.markAsRead(messageId)
     └─→ Backend updates status
     └─→ Poll updates delivery status to BLUE ✓
```

---

## 🔐 Encryption Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    END-TO-END ENCRYPTION                         │
└─────────────────────────────────────────────────────────────────┘

KEY MANAGEMENT:
   User A                                          User B
   ├─ Private Key (stored securely)               ├─ Private Key
   └─ Public Key (shared via server)              └─ Public Key

MESSAGE ENCRYPTION:
   User A sends to User B:
   
   1. Plain Message
   2. Generate symmetric key (AES-256)
   3. Encrypt message with AES key
   4. Encrypt AES key with User B's public key (RSA-2048)
   5. Send [Encrypted Message] + [Encrypted Key]
   
   User B receives:
   1. Decrypt AES key with private key
   2. Decrypt message with AES key
   3. Display plain message


RIVERPOD INTEGRATION:
   encryptionService (singleton)
     ├─ generateKeyPair()
     │   └─ RSA-2048 (currently mock, ready for PointyCastle)
     ├─ encryptMessage(text, publicKey)
     │   └─ AES-256-GCM encryption
     ├─ decryptMessage(ciphertext, privateKey)
     │   └─ Returns plain text
     └─ File encryption (attachments)

   decryptedMessageProvider (Riverpod)
     ├─ Takes Message object (with encryptedContent)
     ├─ Calls encryptionService.decryptMessage()
     └─ Returns decrypted Message for display
```

---

## 🎯 Chat List State Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                  CHAT LIST STATE MANAGEMENT                      │
└─────────────────────────────────────────────────────────────────┘

ChatListScreen
   ↓
ref.watch(chatListProvider)
   ├─→ FutureProvider<List<Chat>>
   ├─→ Depends on: authTokenProvider (requires JWT)
   └─→ Calls: ApiService.getChatList()
   
   ├─ LOADING STATE
   │  └─ Show CircularProgressIndicator
   │
   ├─ ERROR STATE
   │  ├─ Show error icon
   │  ├─ Show error message
   │  └─ Show Retry button
   │     └─ ref.refresh(chatListProvider)
   │
   └─ DATA STATE
      ├─ ChatListScreen builds ListView
      ├─ Each item: ChatTile widget
      │  ├─ onTap → Set selectedChatProvider = chatId
      │  │         → context.goNamed('chat_message', pathParameters: {chatId})
      │  ├─ Swipe left → onMute()
      │  │              → Show mute duration options
      │  │              → Update UI
      │  └─ Swipe right → onDelete()
      │                 → Confirm dialog
      │                 → Remove from list
      │
      ├─ Search filtering
      │  └─ Filter by chat.name.toLowerCase()
      │
      └─ Pull to refresh
         └─ ref.refresh(chatListProvider.future)

User scrolls → More items load
User exits screen → Watch stops (auto-cleanup)
User returns → Automatic refetch
```

---

## 📱 Screen Navigation Flow

```
┌──────────────────────────────────────────────────────────────────┐
│                   NAVIGATION STATE MACHINE                        │
└──────────────────────────────────────────────────────────────────┘

                         SplashScreen (/)
                                ↓
                    [Check authentication]
                         ↙           ↖
                    No Token      Token Found
                        ↓             ↓
                   LoginScreen    ChatListScreen (chats)
                 (/login)              ↓
                   ↓                   ├─→ TapChat (chats/:chatId)
                [Email/Password]       │        ↓
                   ↓                   │   [ChatMessageScreen]
             [Biometric opt]           │        ↓
                   ↓                   │   ├─→ ComposeMessage (chats/:chatId/compose)
              Submit Login             │        ↓
                ↓                      │   [ComposeMessageScreen]
         loginProvider                 │        ↓
         (calls ApiService)            │   Send Message
                ↓                      │        ↓
          Save JWT Token               │   messageListProvider updates
         (SecureStorage)               │   (delivery status changes)
                ↓                      │
         Update authTokenProvider      ├─→ ProfileButton (profile)
                ↓                      │        ↓
         Auto-redirect to chats ───────┘   [ProfileScreen]
                                            ├─ Settings
                                            ├─ Device sessions
                                            └─ Logout
                                                 ↓
                                           secureStorage.deleteToken()
                                                 ↓
                                           Redirect to Login

                                     SecurityButton (security)
                                            ↓
                                       [SecurityScreen]
                                       ├─ Encryption keys
                                       ├─ Audit log
                                       └─ 2FA settings
```

---

## 🔌 Provider Dependency Graph

```
┌──────────────────────────────────────────────────────────────────┐
│                    RIVERPOD PROVIDER GRAPH                        │
└──────────────────────────────────────────────────────────────────┘

┌─ CORE SERVICES (Singletons) ─┐
│ ├─ authServiceProvider        │
│ ├─ storageProvider            │ (No dependencies)
│ └─ encryptionProvider         │
└───────────────┬────────────────┘
                ↓
┌─ AUTH PROVIDERS ────────────────────────┐
│ ├─ authTokenProvider (depends on:)      │
│ │  └─ [fetch from storage]              │
│ ├─ currentUserProvider (depends on:)    │
│ │  ├─ authTokenProvider                 │
│ │  └─ [fetch user profile]              │
│ ├─ isAuthenticatedProvider (depends on:)│
│ │  └─ authTokenProvider (check != null) │
│ ├─ loginProvider (depends on:)          │
│ │  ├─ authServiceProvider               │
│ │  ├─ storageProvider                   │
│ │  └─ [call API + save token]           │
│ └─ logoutProvider (depends on:)         │
│    └─ storageProvider                   │
└──────────────┬──────────────────────────┘
               ↓
┌─ CHAT PROVIDERS ────────────────────────┐
│ ├─ chatListProvider (depends on:)       │
│ │  ├─ authTokenProvider (JWT for API)   │
│ │  └─ [fetch from backend]              │
│ ├─ selectedChatProvider (depends on:)   │
│ │  └─ [user selection]                  │
│ ├─ chatDetailsProvider (depends on:)    │
│ │  ├─ selectedChatProvider (which chat) │
│ │  ├─ authTokenProvider (JWT)           │
│ │  └─ [fetch details]                   │
│ └─ archiveChatProvider (depends on:)    │
│    ├─ selectedChatProvider              │
│    └─ authTokenProvider                 │
└──────────────┬──────────────────────────┘
               ↓
┌─ MESSAGE PROVIDERS ─────────────────────┐
│ ├─ messageListProvider (depends on:)    │
│ │  ├─ selectedChatProvider (which chat) │
│ │  ├─ authTokenProvider (JWT)           │
│ │  └─ [fetch messages]                  │
│ ├─ sendMessageProvider (depends on:)    │
│ │  ├─ selectedChatProvider              │
│ │  ├─ authTokenProvider                 │
│ │  ├─ encryptionProvider (optional)     │
│ │  └─ [send encrypted message]          │
│ └─ decryptedMessageProvider (depends on:)
│    ├─ encryptionProvider                │
│    └─ [decrypt on-demand]               │
└────────────────────────────────────────┘

DEPENDENCY RULES:
✓ Auth must be resolved before Chat/Message operations
✓ Selected chat must be set before fetching messages
✓ All API calls require JWT token (automatic via interceptor)
✓ Decryption is lazy (called per-message, not batch)
```

---

## 📐 Widget Composition Tree

```
┌──────────────────────────────────────────────────────────────────┐
│                     WIDGET TREE HIERARCHY                         │
└──────────────────────────────────────────────────────────────────┘

MaterialApp.router (with GoRouter)
  ├─ MaterialApp.router config
  │  └─ routerConfig: appRouter
  │
  ├─ Routes
  │  ├─ "/" → SplashScreen (ConsumerStatefulWidget)
  │  │        ├─ TweenAnimationBuilder (logo scale)
  │  │        │  └─ Container (gradient background)
  │  │        │     └─ CircleAvatar + Icon
  │  │        │
  │  │        ├─ TweenAnimationBuilder (text fade)
  │  │        │  └─ Text("IntelCrypt")
  │  │        │
  │  │        └─ CircularProgressIndicator
  │  │
  │  ├─ "/login" → LoginScreen (ConsumerStatefulWidget)
  │  │             ├─ CustomInputField (email)
  │  │             ├─ CustomInputField (password)
  │  │             ├─ ElevatedButton (login)
  │  │             ├─ CheckBox (biometric)
  │  │             └─ TextButton (signup link)
  │  │
  │  ├─ "/chats" → ChatListScreen (ConsumerStatefulWidget)
  │  │             ├─ TextField (search)
  │  │             ├─ RefreshIndicator
  │  │             │  └─ ListView.builder
  │  │             │     ├─ ChatTile (for each chat)
  │  │             │     │  ├─ Dismissible
  │  │             │     │  │  ├─ CircleAvatar
  │  │             │     │  │  │  └─ Badge (unread count)
  │  │             │     │  │  ├─ Column (chat info)
  │  │             │     │  │  │  ├─ Row (name + time)
  │  │             │     │  │  │  ├─ Row (preview + icon)
  │  │             │     │  │  │  └─ Mute badge (if muted)
  │  │             │     │  │  └─ Background actions
  │  │             │     │  └─ LongPress context menu
  │  │             │     │
  │  │             │     ├─ Empty state (if no chats)
  │  │             │     │  └─ Column (icon + message)
  │  │             │     │
  │  │             │     └─ Error state
  │  │             │        └─ Column (error + retry)
  │  │             │
  │  │             └─ FloatingActionButton (new chat)
  │  │                └─ ModalBottomSheet
  │  │                   ├─ ListTile (direct message)
  │  │                   └─ ListTile (group chat)
  │  │
  │  ├─ "/chats/:chatId" → ChatMessageScreen (stub)
  │  │                     ├─ AppBar
  │  │                     ├─ ListView (messages)
  │  │                     │  └─ MessageBubble (for each)
  │  │                     │     ├─ Container (bubble)
  │  │                     │     │  ├─ Text (content)
  │  │                     │     │  ├─ Attachment row
  │  │                     │     │  │  └─ Icon + Text
  │  │                     │     │  └─ Timer (if destructible)
  │  │                     │     └─ Row (timestamp + status)
  │  │                     │        └─ Icon (delivery status)
  │  │                     │
  │  │                     ├─ MessageInputField
  │  │                     │  ├─ IconButton (attach)
  │  │                     │  ├─ TextField (message)
  │  │                     │  │  └─ IconButton (clear)
  │  │                     │  ├─ IconButton (emoji)
  │  │                     │  └─ IconButton (send)
  │  │                     │
  │  │                     └─ Fab (compose)
  │  │
  │  ├─ "/profile" → ProfileScreen (stub)
  │  │
  │  └─ "/security" → SecurityScreen (stub)
  │
  └─ Theme (light/dark)
     ├─ ColorScheme
     ├─ TextTheme
     └─ Component themes
```

---

## 🔄 Data Flow Example: Sending a Message

```
User types "Hello" in MessageInputField
   ↓
   [TextField controller updates]
   ↓
   User taps Send button
   ↓
   widget.onSendPressed() callback
   ↓
   ref.read(sendMessageProvider)
   ├─→ Get selectedChatProvider = "chat_123"
   ├─→ Get authTokenProvider = JWT token
   ├─→ Create MessageRequest(chatId, content: "Hello")
   ├─→ Call encryptionService.encryptMessage("Hello", pubKey)
   │   └─→ Return encrypted base64 string
   ├─→ Call apiService.sendMessage(MessageRequest)
   │   ├─→ Auto-add Authorization header
   │   ├─→ POST to /api/messages
   │   ├─→ Backend stores encrypted message
   │   └─→ Return Message(id, status: "sent", timestamp)
   ├─→ Update deliveryStatus: pending → sent
   ├─→ Return Message to UI
   ↓
   messageListProvider refreshes
   ├─→ Calls ApiService.getMessages(chatId)
   ├─→ Gets updated list with new message
   └─→ UI rebuilds with new MessageBubble
   
   ↓ (async via polling)
   
   Backend processes message
   ├─→ Delivers to recipient
   ├─→ Updates status: delivered
   ├─→ Recipient device gets notification
   └─→ Recipient reads message
   
   ↓ (polling or websocket)
   
   messageListProvider updates
   ├─→ Message now shows deliveryStatus: read
   ├─→ MessageBubble shows blue double-check icon ✓✓
   └─→ UI reflects read receipt
```

---

## ✨ Summary

This architecture provides:
- **Type-Safe Navigation**: GoRouter with named routes
- **Reactive State**: Riverpod with AsyncValue error handling
- **Secure Communication**: JWT interceptor + SSL/TLS
- **Encryption-Ready**: E2E encryption scaffold
- **Material Design 3**: Consistent UI/UX across platforms
- **Modular Widgets**: Reusable components
- **Clean Separation**: Models, Services, Providers, UI
- **Production-Ready**: Error handling, loading states, empty states

All layers are decoupled and testable independently.
