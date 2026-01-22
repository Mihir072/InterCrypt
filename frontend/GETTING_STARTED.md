# IntelCrypt Frontend - Getting Started Guide

## 📋 Prerequisites

- Flutter SDK 3.10.1+ ([Install](https://flutter.dev/docs/get-started/install))
- Dart 3.10.1+ (comes with Flutter)
- Android Studio or Xcode (for platform-specific development)
- Git
- VS Code or Android Studio IDE

## 🚀 Quick Start

### 1. Install Flutter & Dependencies

```bash
# Verify Flutter installation
flutter --version
flutter doctor

# Fix any issues reported by flutter doctor
flutter doctor --android-licenses
```

### 2. Clone & Setup Project

```bash
# Navigate to frontend directory
cd frontend

# Get dependencies
flutter pub get

# Generate code (Riverpod, JSON serialization, etc.)
flutter pub run build_runner build

# Clean any previous builds
flutter clean
```

### 3. Run the Application

**On Emulator**
```bash
# List available emulators
flutter emulators

# Launch emulator
flutter emulators launch <emulator_id>

# Run app
flutter run
```

**On Physical Device**
```bash
# Enable USB debugging on device
# Connect device via USB

flutter devices  # Verify device detection

flutter run
```

**With Hot Reload**
```bash
# Press 'r' during app execution for hot reload
# Press 'R' for hot restart
flutter run
```

## 📁 Project Structure Understanding

### Core Directories

```
lib/src/
├── models/           - Data classes (User, Chat, Message, Auth models)
├── services/         - Business logic
│   ├── api_service.dart        - REST API client
│   ├── encryption_service.dart - E2E encryption
│   └── secure_storage_service.dart - Secure local storage
├── providers/        - Riverpod state management
│   ├── auth_provider.dart   - Authentication state
│   ├── chat_provider.dart   - Chat list state
│   └── message_provider.dart - Message state
└── ui/              - User interface
    ├── screens/     - Application screens
    ├── widgets/     - Reusable components
    └── theme/       - Material Design 3 configuration
```

### Key Files to Understand

1. **main.dart** - App entry point with Riverpod setup
2. **src/models/** - Data structures and JSON parsing
3. **src/services/api_service.dart** - Backend communication
4. **src/providers/** - State management business logic
5. **src/ui/theme/app_theme.dart** - Theming and colors

## 🔧 Configuration

### API Backend URL

**File**: `lib/src/providers/auth_provider.dart`

Update the `baseUrl` in the `apiService` provider:

```dart
@riverpod
ApiService apiService(ApiServiceRef ref) {
  final apiService = ApiService(baseUrl: 'http://your-backend-url/api');
  ref.onDispose(() => apiService.dispose());
  return apiService;
}
```

### Build Configuration

**Android**: `android/app/build.gradle`
- Update `compileSdkVersion`
- Configure signing

**iOS**: `ios/Runner.xcodeproj/project.pbxproj`
- Update deployment target
- Configure signing certificates

## 📦 Adding New Dependencies

```bash
# Add a package
flutter pub add package_name

# Remove a package
flutter pub remove package_name

# Update dependencies
flutter pub upgrade
```

## 🧪 Running Tests

```bash
# Run all tests
flutter test

# Run specific test
flutter test test/path/to/test.dart

# Run with coverage
flutter test --coverage

# View coverage
open coverage/index.html  # macOS
start coverage/index.html  # Windows
xdg-open coverage/index.html  # Linux
```

## 🔐 Security Setup

### Secure Storage Initialization

The `SecureStorageService` is automatically configured with:
- **Android**: Android Keystore encryption
- **iOS**: iOS Keychain

No additional setup needed, but ensure Android/iOS minSDK requirements:
- Android: minSdkVersion 18+
- iOS: iOS 9.0+

### Biometric Authentication

Enable biometric support:

**Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<uses-permission android:name="android.permission.USE_BIOMETRIC" />
```

**iOS** (`ios/Runner/Info.plist`):
```xml
<key>NSFaceIDUsageDescription</key>
<string>IntelCrypt uses Face ID for authentication</string>
<key>NSBiometricUsageDescription</key>
<string>IntelCrypt uses Biometric authentication</string>
```

## 🎨 Theme Customization

**File**: `lib/src/ui/theme/app_theme.dart`

Change primary color:
```dart
static const Color _primaryColor = Color(0xFF1565C0); // Blue
// Change to: Color(0xFF...) for your color
```

Colors automatically apply to:
- Buttons and interactive elements
- Input fields
- Text and typography
- Status indicators

## 📱 Device Testing

### Test Different Screen Sizes

```bash
# Run on different device sizes
flutter run -d pixel_4
flutter run -d iphone_13
flutter run -d ipad_pro
```

### Test Dark Mode

```bash
# Toggle dark mode in Chrome DevTools
# Or run with flag
flutter run --enable-software-brightness
```

## 🐛 Debugging

### Debug Logging

```dart
import 'package:logger/logger.dart';

final logger = Logger();

logger.d('Debug message');
logger.i('Info message');
logger.w('Warning message');
logger.e('Error message');
logger.wtf('Fatal error');
```

### Riverpod DevTools

```bash
# Install Riverpod DevTools
flutter pub global activate riverpod_cli

# Use in app
# Enable in main.dart with ProviderContainer configuration
```

### Performance Profiling

```bash
# Run with profiling
flutter run --profile

# Use in DevTools:
# - Timeline tab for frame analysis
# - Memory tab for allocation tracking
# - CPU profiler for hot spots
```

## 🔄 Code Generation

Watch for changes and regenerate:

```bash
flutter pub run build_runner watch
```

This automatically regenerates:
- Riverpod providers
- JSON serialization code
- Any `.g.dart` files

## 📝 Creating New Features

### Adding a New Screen

1. Create `lib/src/ui/screens/my_screen.dart`
2. Implement screen as `ConsumerWidget` or `ConsumerStatefulWidget`
3. Add route in navigation logic
4. Import in main app

### Adding a New Provider

1. Create `lib/src/providers/my_provider.dart`
2. Define state class and notifier
3. Implement `@riverpod` provider
4. Export in `lib/src/providers/providers.dart`
5. Watch in widgets using `ref.watch(myProvider)`

### Adding a New Service

1. Create `lib/src/services/my_service.dart`
2. Implement service class
3. Create provider in `lib/src/providers/`
4. Export in `lib/src/services/services.dart`
5. Use via Riverpod providers

### Adding a New Model

1. Create `lib/src/models/my_model.dart`
2. Implement data class with JSON support
3. Add factory constructor and toJson method
4. Export in `lib/src/models/models.dart`

## 🎯 Best Practices

### State Management
- Use Riverpod for all app-level state
- Keep notifiers focused and single-responsibility
- Use computed providers to avoid unnecessary rebuilds

### UI Development
- Create reusable widgets in `lib/src/ui/widgets/`
- Use `ConsumerWidget` to access Riverpod state
- Implement proper error handling and loading states

### Code Organization
- Follow the defined folder structure
- Use meaningful class and file names
- Add comments for complex logic
- Keep functions small and focused

### Performance
- Lazy load resources
- Cache network responses
- Use const constructors where possible
- Profile regularly with DevTools

## 📚 Learning Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Riverpod Documentation](https://riverpod.dev)
- [Material Design 3](https://m3.material.io)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)

## 🤝 Contributing

1. Create feature branch: `git checkout -b feature/my-feature`
2. Make changes following code style
3. Test thoroughly: `flutter test`
4. Commit with clear messages
5. Push and create pull request

## 📞 Support

For issues or questions:
1. Check existing issues/documentation
2. Review error logs: `flutter logs`
3. Run `flutter doctor` for setup issues
4. Consult team documentation

## 🎉 Next Steps

1. **Configure Backend URL** - Update API endpoint
2. **Test Login Flow** - Verify authentication
3. **Customize UI** - Adjust colors/fonts as needed
4. **Add Missing Screens** - Implement placeholder screens
5. **Integrate Services** - Connect encryption and storage
6. **Deploy** - Build and release to app stores
