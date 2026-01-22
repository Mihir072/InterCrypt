import 'user_model.dart';

/// Authentication token model
class AuthToken {
  final String accessToken;
  final String refreshToken;
  final String tokenType; // Bearer
  final int expiresIn; // seconds
  final DateTime issuedAt;
  final List<String> scopes;
  final String? userId;

  const AuthToken({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
    required this.issuedAt,
    required this.scopes,
    this.userId,
  });

  factory AuthToken.fromJson(Map<String, dynamic> json) {
    // Handle both nested 'token' object and flat response from backend
    final tokenData = json['token'] as Map<String, dynamic>? ?? json;
    return AuthToken(
      accessToken: tokenData['accessToken'] as String,
      refreshToken: tokenData['refreshToken'] as String,
      tokenType: tokenData['tokenType'] as String? ?? 'Bearer',
      expiresIn: (tokenData['expiresIn'] as num?)?.toInt() ?? 3600,
      issuedAt: tokenData['issuedAt'] != null
          ? DateTime.parse(tokenData['issuedAt'] as String)
          : DateTime.now(),
      scopes: List<String>.from(tokenData['scopes'] as List? ?? []),
      userId:
          tokenData['userId'] as String? ??
          (json['user'] as Map<String, dynamic>?)?['id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'tokenType': tokenType,
      'expiresIn': expiresIn,
      'issuedAt': issuedAt.toIso8601String(),
      'scopes': scopes,
      'userId': userId,
    };
  }

  DateTime get expiresAt => issuedAt.add(Duration(seconds: expiresIn));
  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isExpiringSoon =>
      DateTime.now().add(const Duration(minutes: 5)).isAfter(expiresAt);
}

/// Login request model
class LoginRequest {
  final String username; // Backend expects 'username' not 'email'
  final String password;
  final bool rememberMe;
  final String? deviceId;
  final bool useBiometric;

  const LoginRequest({
    required this.username,
    required this.password,
    this.rememberMe = false,
    this.deviceId,
    this.useBiometric = false,
  });

  Map<String, dynamic> toJson() {
    return {'username': username, 'password': password};
  }
}

/// Signup request model
class SignupRequest {
  final String username;
  final String email;
  final String password;
  final String confirmPassword;
  final bool acceptTerms;
  final String? clearanceLevel;

  const SignupRequest({
    required this.username,
    required this.email,
    required this.password,
    required this.confirmPassword,
    required this.acceptTerms,
    this.clearanceLevel = 'STANDARD',
  });

  /// Convert to JSON - only sends fields the backend expects
  Map<String, dynamic> toJson() {
    return {'username': username, 'email': email, 'password': password};
  }

  bool get isValid =>
      username.isNotEmpty &&
      email.isNotEmpty &&
      password.isNotEmpty &&
      password == confirmPassword &&
      password.length >= 8 &&
      acceptTerms;
}

/// Authentication response model
class AuthResponse {
  final String message;
  final AuthToken token;
  final User user;
  final bool requiresMfaSetup;
  final String sessionId;

  const AuthResponse({
    required this.message,
    required this.token,
    required this.user,
    this.requiresMfaSetup = false,
    required this.sessionId,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    // Backend returns: accessToken, refreshToken, tokenType, expiresIn, user
    // Create token from the flat response
    final token = AuthToken.fromJson(json);

    // Parse user from backend's 'user' field
    final userJson = json['user'] as Map<String, dynamic>?;
    final user = userJson != null
        ? User.fromJson({
            'id': userJson['id'] as String? ?? '',
            'username': userJson['username'] as String? ?? '',
            'email': userJson['email'] as String? ?? '',
            'roles': (userJson['roles'] as List?)?.cast<String>() ?? [],
            'clearanceLevel':
                userJson['clearanceLevel'] as String? ?? 'STANDARD',
            'isOnline': true,
            'lastSeen': DateTime.now().toIso8601String(),
            'createdAt': DateTime.now().toIso8601String(),
          })
        : User(
            id: '',
            username: '',
            email: '',
            roles: [],
            clearanceLevel: 'STANDARD',
            lastSeen: DateTime.now(),
            createdAt: DateTime.now(),
          );

    return AuthResponse(
      message: json['message'] as String? ?? 'Authentication successful',
      token: token,
      user: user,
      requiresMfaSetup: json['requiresMfaSetup'] as bool? ?? false,
      sessionId: json['sessionId'] as String? ?? '',
    );
  }

  // For backward compatibility
  String get userId => user.id;
  String get username => user.username;
  String get email => user.email;

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'token': token.toJson(),
      'user': user.toJson(),
      'requiresMfaSetup': requiresMfaSetup,
      'sessionId': sessionId,
    };
  }
}

/// Biometric authentication model
class BiometricAuth {
  final String userId;
  final String? deviceId;
  final String authenticationType; // FINGERPRINT, FACE
  final bool isEnabled;
  final DateTime enrolledAt;
  final DateTime? lastUsedAt;
  final int failedAttempts;

  const BiometricAuth({
    required this.userId,
    this.deviceId,
    required this.authenticationType,
    required this.isEnabled,
    required this.enrolledAt,
    this.lastUsedAt,
    this.failedAttempts = 0,
  });

  factory BiometricAuth.fromJson(Map<String, dynamic> json) {
    return BiometricAuth(
      userId: json['userId'] as String,
      deviceId: json['deviceId'] as String?,
      authenticationType:
          json['authenticationType'] as String? ?? 'FINGERPRINT',
      isEnabled: json['isEnabled'] as bool? ?? false,
      enrolledAt: DateTime.parse(json['enrolledAt'] as String),
      lastUsedAt: json['lastUsedAt'] != null
          ? DateTime.parse(json['lastUsedAt'] as String)
          : null,
      failedAttempts: json['failedAttempts'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'deviceId': deviceId,
      'authenticationType': authenticationType,
      'isEnabled': isEnabled,
      'enrolledAt': enrolledAt.toIso8601String(),
      'lastUsedAt': lastUsedAt?.toIso8601String(),
      'failedAttempts': failedAttempts,
    };
  }

  bool get isLocked => failedAttempts >= 5;
}

/// Session model
class Session {
  final String sessionId;
  final String userId;
  final String deviceId;
  final String deviceName;
  final String ipAddress;
  final String userAgent;
  final DateTime createdAt;
  final DateTime lastActivityAt;
  final DateTime? expiresAt;
  final bool isActive;

  const Session({
    required this.sessionId,
    required this.userId,
    required this.deviceId,
    required this.deviceName,
    required this.ipAddress,
    required this.userAgent,
    required this.createdAt,
    required this.lastActivityAt,
    this.expiresAt,
    this.isActive = true,
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      sessionId: json['sessionId'] as String,
      userId: json['userId'] as String,
      deviceId: json['deviceId'] as String,
      deviceName: json['deviceName'] as String,
      ipAddress: json['ipAddress'] as String,
      userAgent: json['userAgent'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastActivityAt: DateTime.parse(json['lastActivityAt'] as String),
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'userId': userId,
      'deviceId': deviceId,
      'deviceName': deviceName,
      'ipAddress': ipAddress,
      'userAgent': userAgent,
      'createdAt': createdAt.toIso8601String(),
      'lastActivityAt': lastActivityAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'isActive': isActive,
    };
  }

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
}
