// ignore_for_file: unused_local_variable

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../config/app_config.dart';
import '../models/models.dart';
import '../services/services.dart';

part 'auth_provider.g.dart';

/// Auth state
class AuthState {
  final bool isAuthenticated;
  final AuthToken? token;
  final User? currentUser;
  final bool isLoading;
  final String? error;
  final DateTime? lastRefresh;
  final bool requiresMfaSetup;
  final Session? activeSession;

  const AuthState({
    this.isAuthenticated = false,
    this.token,
    this.currentUser,
    this.isLoading = false,
    this.error,
    this.lastRefresh,
    this.requiresMfaSetup = false,
    this.activeSession,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    AuthToken? token,
    User? currentUser,
    bool? isLoading,
    String? error,
    DateTime? lastRefresh,
    bool? requiresMfaSetup,
    Session? activeSession,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      token: token ?? this.token,
      currentUser: currentUser ?? this.currentUser,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      lastRefresh: lastRefresh ?? this.lastRefresh,
      requiresMfaSetup: requiresMfaSetup ?? this.requiresMfaSetup,
      activeSession: activeSession ?? this.activeSession,
    );
  }

  bool get isTokenExpired => token?.isExpired ?? true;
  bool get isTokenExpiringSoon => token?.isExpiringSoon ?? false;
  String? get userId => currentUser?.id;
  String? get username => currentUser?.username;
  bool get isAdmin => currentUser?.roles.contains('ADMIN') ?? false;
}

/// Auth Notifier for managing authentication state
class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _apiService;
  final SecureStorageService _secureStorage;

  AuthNotifier(this._apiService, this._secureStorage)
    : super(const AuthState());

  /// Initialize auth state from stored tokens
  Future<void> initialize() async {
    try {
      state = state.copyWith(isLoading: true);

      // Load tokens from secure storage (local — fast, no network)
      await _apiService.loadStoredTokens();

      final accessToken = await _secureStorage.getAccessToken();
      final refreshToken = await _secureStorage.getRefreshToken();

      if (accessToken != null && refreshToken != null) {
        try {
          // Validate token with the server. Use a timeout so a slow/offline
          // server doesn't hang the splash screen.
          final user = await _apiService.getCurrentUser().timeout(
            const Duration(seconds: 6),
          );

          state = AuthState(
            isAuthenticated: true,
            token: AuthToken(
              accessToken: accessToken,
              refreshToken: refreshToken,
              tokenType: 'Bearer',
              expiresIn: 3600,
              issuedAt: DateTime.now(),
              scopes: [],
              userId: user.id,
            ),
            currentUser: user,
            lastRefresh: DateTime.now(),
          );
        } catch (e) {
          // Token invalid or server unreachable — clear local tokens only
          // (skip server-side logout which would make us hang again).
          await _secureStorage.clearTokens();
          state = const AuthState();
        }
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to initialize auth: $e',
      );
    }
  }

  /// Login with username and password
  Future<bool> login(
    String username,
    String password, {
    bool rememberMe = false,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final request = LoginRequest(
        username: username,
        password: password,
        rememberMe: rememberMe,
      );

      final response = await _apiService.login(request);

      // Tokens are already saved by ApiService.login()
      await _secureStorage.saveUserId(response.user.id);
      if (response.sessionId.isNotEmpty) {
        await _secureStorage.saveSessionId(response.sessionId);
      }

      state = AuthState(
        isAuthenticated: true,
        token: response.token,
        currentUser: response.user,
        lastRefresh: DateTime.now(),
      );

      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Sign up new user
  Future<bool> signup(
    String username,
    String email,
    String password,
    String confirmPassword,
  ) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final request = SignupRequest(
        username: username,
        email: email,
        password: password,
        confirmPassword: confirmPassword,
        acceptTerms: true,
      );

      if (!request.isValid) {
        throw 'Invalid signup request';
      }

      final response = await _apiService.signup(request);

      // Tokens are already saved by ApiService.signup()
      await _secureStorage.saveUserId(response.user.id);

      state = AuthState(
        isAuthenticated: true,
        token: response.token,
        currentUser: response.user,
        lastRefresh: DateTime.now(),
      );

      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Refresh access token
  Future<bool> refreshAccessToken() async {
    try {
      if (!state.isAuthenticated || state.token == null) {
        return false;
      }

      final newToken = await _apiService.refreshToken();

      // Save new tokens
      await _secureStorage.saveAccessToken(newToken.accessToken);
      await _secureStorage.saveRefreshToken(newToken.refreshToken);

      state = state.copyWith(token: newToken, lastRefresh: DateTime.now());

      return true;
    } catch (e) {
      await logout();
      return false;
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      await _apiService.logout();
    } catch (e) {
      // Logout from server might fail, but we still clear local state
    }

    await _secureStorage.clearTokens();
    state = const AuthState();
  }

  /// Change password
  Future<bool> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await _apiService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Request password reset
  Future<bool> requestPasswordReset(String email) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await _apiService.requestPasswordReset(email);

      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Update user profile
  Future<bool> updateProfile({String? username, String? clearanceLevel}) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final updatedUser = await _apiService.updateProfile(
        username: username,
        clearanceLevel: clearanceLevel,
      );

      state = state.copyWith(currentUser: updatedUser, isLoading: false);

      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Auth provider — kept alive for the full app lifetime so auth state
/// is never lost to auto-dispose.
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  // Use read (not watch) so rebuilding apiServiceProvider/secureStorageProvider
  // doesn't silently create a fresh AuthNotifier and wipe auth state.
  final apiService = ref.read(apiServiceProvider);
  final secureStorage = ref.read(secureStorageProvider);
  return AuthNotifier(apiService, secureStorage);
});

/// Current auth state provider
@riverpod
AuthState authState(AuthStateRef ref) {
  return ref.watch(authProvider);
}

/// Check if user is authenticated
@riverpod
bool isAuthenticated(IsAuthenticatedRef ref) {
  return ref.watch(authStateProvider).isAuthenticated;
}

/// Check if auth is loading
@riverpod
bool authLoading(AuthLoadingRef ref) {
  return ref.watch(authStateProvider).isLoading;
}

/// Get current user
@riverpod
User? currentUser(CurrentUserRef ref) {
  return ref.watch(authStateProvider).currentUser;
}

/// Get auth error
@riverpod
String? authError(AuthErrorRef ref) {
  return ref.watch(authStateProvider).error;
}

/// API Service provider — kept alive for app lifetime (non-auto-dispose).
@Riverpod(keepAlive: true)
ApiService apiService(ApiServiceRef ref) {
  final apiService = ApiService(baseUrl: AppConfig.apiBaseUrl);
  ref.onDispose(() => apiService.dispose());
  return apiService;
}

/// Secure Storage provider — kept alive for app lifetime (non-auto-dispose).
@Riverpod(keepAlive: true)
SecureStorageService secureStorage(SecureStorageRef ref) {
  return SecureStorageService();
}
