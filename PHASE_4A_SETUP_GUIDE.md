# Phase 4A: Authentication Integration - Setup & Testing Guide

## 📋 What We've Implemented

### 1. **Secure Token Storage**
- ✅ `SecureStorageService`: Encrypted storage for access/refresh tokens using flutter_secure_storage
- ✅ `TokenStorageService`: Additional convenience wrapper (redundant but available)
- ✅ Token persistence across app restarts
- ✅ Session ID storage for tracking

### 2. **Enhanced ApiService**
- ✅ `loadStoredTokens()`: Load tokens from storage on app startup
- ✅ `setTokens()`: Save tokens securely with optional expiry
- ✅ `hasValidToken()`: Check if token still exists
- ✅ Automatic 401 error handling
- ✅ Token refresh capability
- ✅ Headers auto-include JWT Bearer tokens

### 3. **AuthProvider Integration** (Riverpod)
- ✅ `AuthNotifier`: State management for authentication
- ✅ `AuthState`: Model with user, token, loading, error states
- ✅ `authProvider`: Main provider for auth state
- ✅ Auto-initialize from stored tokens
- ✅ Computed providers: `isAuthenticatedProvider`, `currentUserProvider`, `accessTokenProvider`

### 4. **Updated Models**
- ✅ `AuthResponse`: Now includes full User object (backward compatible)
- ✅ `LoginRequest`: Email, password, device tracking
- ✅ `SignupRequest`: Full signup with validation
- ✅ `AuthToken`: JWT token with expiry tracking

---

## 🧪 Testing Setup

### Prerequisites
1. **Backend Running**: Spring Boot server at `http://localhost:8080`
2. **Database**: H2 database initialized with tables
3. **Endpoints**: Auth endpoints must be implemented (`/api/auth/login`, `/api/auth/signup`, etc.)

### Test Users (if seeded in backend)
```
Email: test@example.com
Password: Test@1234!

Email: user@example.com
Password: SecurePass123!
```

---

## 🔧 Step-by-Step Integration

### Step 1: Update LoginScreen to Use Real API

**Current location**: `frontend/lib/src/screens/auth/login_screen.dart`

```dart
// OLD: Mock login
// NEW: Real API call

final auth = ref.read(authProvider.notifier);
final success = await auth.login(emailController.text, passwordController.text);

if (success) {
  context.go('/chats');  // Navigate to chat list
} else {
  // Show error from auth.error
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(text: 'Login failed: ${auth.error}')
  );
}
```

**Error Handling**:
- Show spinner while `auth.isLoading == true`
- Display `auth.error` message in SnackBar
- Disable submit button if `auth.error != null` and `!auth.isLoading`

### Step 2: Update SignupScreen to Use Real API

**Current location**: `frontend/lib/src/screens/auth/signup_screen.dart`

```dart
// OLD: Mock signup
// NEW: Real API call

final auth = ref.read(authProvider.notifier);
final success = await auth.signup(
  usernameController.text,
  emailController.text,
  passwordController.text,
  confirmPasswordController.text,
);

if (success) {
  context.go('/chats');  // Navigate to chat list
} else {
  // Show error
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(text: 'Signup failed: ${auth.error}')
  );
}
```

### Step 3: Initialize Auth on App Startup

**Location**: `frontend/lib/main.dart` or in a startup provider

```dart
// Add to main() or in a startup effect
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // TODO: Initialize auth provider on app start
  // This will load stored tokens and validate them
  
  runApp(
    ProviderScope(
      child: MyApp(),
    ),
  );
}
```

Or better, in a setup provider:

```dart
// In a new app_startup_provider.dart
@riverpod
Future<void> appStartup(AppStartupRef ref) async {
  // Initialize auth - loads stored tokens
  await ref.read(authProvider.notifier).initialize();
}
```

Then use in main:

```dart
// In main.dart
if (appInitialized == null) {
  appInitialized = ref.read(appStartupProvider);
  await appInitialized;
}
```

### Step 4: Update SplashScreen to Wait for Auth

**Current location**: `frontend/lib/src/screens/splash_screen.dart`

```dart
@override
void initState() {
  super.initState();
  
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    // Load auth state
    final auth = ref.read(authProvider);
    
    // Simulate splash duration
    await Future.delayed(const Duration(seconds: 2));
    
    // Navigate based on auth state
    if (mounted) {
      if (auth.isAuthenticated) {
        context.go('/chats');
      } else {
        context.go('/login');
      }
    }
  });
}
```

---

## 🧬 Data Flow Diagram

```
App Start
    ↓
SplashScreen (2s delay)
    ↓
Initialize Auth Provider
    ├─→ Load tokens from SecureStorage
    ├─→ Check if token is valid
    ├─→ Try to fetch current user (if valid)
    └─→ Set isAuthenticated = true/false
    ↓
Check auth.isAuthenticated
    ├─→ TRUE  → Navigate to /chats (ChatListScreen)
    └─→ FALSE → Navigate to /login (LoginScreen)

User Enters Email/Password on LoginScreen
    ↓
Click Login Button
    ↓
Call auth.login(email, password)
    ├─→ API Call: POST /auth/login
    ├─→ Backend validates credentials
    ├─→ Backend returns JWT tokens + user data
    ├─→ ApiService saves tokens to SecureStorage
    ├─→ AuthNotifier updates state
    └─→ isAuthenticated = true
    ↓
Router navigates to /chats
    ↓
ChatListScreen displays user's chats
```

---

## 🔐 Token Refresh Logic

### Automatic Refresh
When a 401 Unauthorized response is received:

```
HTTP 401 Response
    ↓
ApiService._handleResponse() detects 401
    ↓
Try to refresh token:
    POST /auth/refresh with refreshToken
    ↓
On Success:
    ├─→ Save new tokens to SecureStorage
    ├─→ Update ApiService._accessToken
    └─→ Caller should RETRY original request
    
On Failure:
    ├─→ Clear all tokens
    ├─→ Call onTokenExpired callback
    ├─→ AuthNotifier logs out user
    └─→ Navigate to /login
```

### Manual Refresh (via AuthNotifier)
```dart
final auth = ref.read(authProvider.notifier);
final success = await auth.refreshAccessToken();
```

---

## ✅ Checklist for Integration

### Backend Prerequisites
- [ ] `/api/auth/login` endpoint implemented & tested
- [ ] `/api/auth/signup` endpoint implemented & tested
- [ ] `/api/auth/refresh` endpoint implemented
- [ ] `/api/auth/logout` endpoint implemented
- [ ] `/api/users/me` endpoint (for loading current user)
- [ ] JWT token generation working
- [ ] Database initialized with User table

### Frontend Implementation
- [ ] Update LoginScreen to call `auth.login()`
- [ ] Update SignupScreen to call `auth.signup()`
- [ ] Add error display to both screens
- [ ] Add loading spinner to both screens
- [ ] Update SplashScreen to check `isAuthenticated`
- [ ] Create app startup provider
- [ ] Call `auth.initialize()` on app start
- [ ] Verify tokens persist across app restart

### Testing Scenarios
- [ ] **New User Login**: Fresh credentials, first time
- [ ] **Returning User**: Tokens exist from previous session
- [ ] **Invalid Credentials**: Wrong email/password
- [ ] **Network Error**: Backend unreachable
- [ ] **Expired Token**: Refresh endpoint called automatically
- [ ] **Token Refresh Failure**: Logout user automatically
- [ ] **App Restart with Valid Token**: Auto-login without input
- [ ] **App Restart with Expired Token**: Navigate to login

---

## 🐛 Common Issues & Solutions

### Issue 1: Tokens Not Persisting
**Problem**: Tokens clear after app restart
**Solution**: Ensure `SecureStorageService.saveTokens()` is called after login

### Issue 2: 401 Loop
**Problem**: Token refresh keeps failing, causing infinite loop
**Solution**: Add max retry limit in ApiService._handleResponse()

### Issue 3: Missing User Data
**Problem**: AuthResponse.user is null
**Solution**: Verify backend returns user object in auth response

### Issue 4: App Crashes on Startup
**Problem**: `initialize()` throws exception
**Solution**: Wrap in try-catch, handle empty storage gracefully

---

## 📝 Next Steps

1. **Connect Screens**: Update LoginScreen & SignupScreen UI
2. **Test Locally**: Run with local backend, test login flow
3. **Error Handling**: Add snackbars, dialogs for errors
4. **Loading States**: Show spinners during API calls
5. **Move to Phase 4B**: Implement chat API integration

---

## 📚 Files Modified

```
✅ frontend/lib/src/services/api_service.dart
   - loadStoredTokens()
   - setTokens() with persistence
   - Auto 401 handling

✅ frontend/lib/src/services/secure_storage_service.dart
   - saveSessionId()
   - getSessionId()

✅ frontend/lib/src/models/auth_model.dart
   - Added import for User
   - Updated AuthResponse to include User object

✅ frontend/lib/src/providers/auth_provider.dart
   - Enhanced initialize() to load tokens
   - Updated login() to save tokens properly
   - Updated signup() to save tokens properly

✅ PHASE_4_INTEGRATION_PLAN.md
   - Comprehensive integration roadmap
```

---

**Status**: Phase 4A Infrastructure Complete ✅
**Next**: Connect UI screens to APIs
