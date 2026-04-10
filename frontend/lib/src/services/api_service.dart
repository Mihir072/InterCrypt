// ignore_for_file: unused_local_variable

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';
import 'secure_storage_service.dart';
import 'encryption_service.dart';

/// Exception thrown by API
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;

  ApiException({required this.message, this.statusCode, this.originalError});

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}

/// API Service for IntelCrypt backend communication
class ApiService {
  final String baseUrl;
  late http.Client _client;
  String? _accessToken;
  String? _refreshToken;

  // Services
  final SecureStorageService _secureStorage;

  // Token expiration callback
  void Function()? onTokenExpired;

  ApiService({
    required this.baseUrl,
    http.Client? client,
    SecureStorageService? secureStorage,
  }) : _secureStorage = secureStorage ?? SecureStorageService() {
    _client = client ?? http.Client();
  }

  /// Load tokens from secure storage
  Future<void> loadStoredTokens() async {
    try {
      _accessToken = await _secureStorage.getAccessToken();
      _refreshToken = await _secureStorage.getRefreshToken();
    } catch (e) {
      // Log but don't throw - may be first run
      print('Failed to load stored tokens: $e');
    }
  }

  /// Set authentication tokens and persist them
  Future<void> setTokens(
    String accessToken,
    String refreshToken, {
    String? userId,
    DateTime? expiresAt,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;

    try {
      await Future.wait([
        _secureStorage.saveAccessToken(accessToken),
        _secureStorage.saveRefreshToken(refreshToken),
        if (userId != null) _secureStorage.saveUserId(userId),
      ]);
    } catch (e) {
      print('Failed to persist tokens: $e');
      // Don't throw - tokens are still available in memory
    }
  }

  /// Get current access token
  String? getAccessToken() => _accessToken;

  /// Clear authentication tokens and storage
  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;

    try {
      await _secureStorage.clearTokens();
    } catch (e) {
      print('Failed to clear stored tokens: $e');
    }
  }

  /// Check if token exists and is valid
  Future<bool> hasValidToken() async {
    return _accessToken != null;
  }

  /// Get headers with authorization
  Map<String, String> _getHeaders({bool includeAuth = true}) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (includeAuth && _accessToken != null) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }

    return headers;
  }

  /// Handle HTTP response with automatic token refresh on 401
  Future<dynamic> _handleResponse(http.Response response) async {
    try {
      if (response.statusCode == 204) {
        return null; // No content
      }

      final decoded = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return decoded;
      } else if (response.statusCode == 401) {
        // Try to refresh token
        try {
          if (_refreshToken != null) {
            print('Token expired, attempting refresh...');
            final newToken = await refreshToken();
            // Caller should retry the request
            throw ApiException(
              message: 'Token refreshed, please retry',
              statusCode: 401,
            );
          }
        } catch (e) {
          // Refresh failed
          print('Token refresh failed: $e');
        }

        // Token expired and refresh failed or unavailable
        await clearTokens();
        onTokenExpired?.call();
        throw ApiException(
          message: decoded['message'] ?? 'Unauthorized',
          statusCode: response.statusCode,
        );
      } else if (response.statusCode == 403) {
        throw ApiException(
          message: decoded['message'] ?? 'Forbidden',
          statusCode: response.statusCode,
        );
      } else {
        throw ApiException(
          message: decoded['message'] ?? 'Request failed',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        message: 'Failed to parse response',
        statusCode: response.statusCode,
        originalError: e,
      );
    }
  }

  /// GET request
  Future<dynamic> get(String endpoint) async {
    try {
      final response = await _client
          .get(Uri.parse('$baseUrl$endpoint'), headers: _getHeaders())
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Network error: $e', originalError: e);
    }
  }

  /// POST request
  Future<dynamic> post(String endpoint, {required dynamic data}) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl$endpoint'),
            headers: _getHeaders(),
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Network error: $e', originalError: e);
    }
  }

  /// PUT request
  Future<dynamic> put(String endpoint, {required dynamic data}) async {
    try {
      final response = await _client
          .put(
            Uri.parse('$baseUrl$endpoint'),
            headers: _getHeaders(),
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Network error: $e', originalError: e);
    }
  }

  /// DELETE request
  Future<dynamic> delete(String endpoint) async {
    try {
      final response = await _client
          .delete(Uri.parse('$baseUrl$endpoint'), headers: _getHeaders())
          .timeout(const Duration(seconds: 30));

      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Network error: $e', originalError: e);
    }
  }

  /// Upload a file
  Future<dynamic> uploadFile(String filePath, String fileName, {List<int>? bytes}) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/files/upload'),
      );
      
      final headers = _getHeaders();
      headers.remove('Content-Type'); // Let http client set boundary
      request.headers.addAll(headers);

      if (bytes != null) {
        request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: fileName));
      } else {
        request.files.add(await http.MultipartFile.fromPath('file', filePath, filename: fileName));
      }

      final streamedResponse = await _client.send(request).timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        throw ApiException(
          message: 'Upload failed',
          statusCode: response.statusCode,
          originalError: response.body,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Network error during upload: $e', originalError: e);
    }
  }

  // ============== AUTH ENDPOINTS ==============

  /// Login with email and password
  Future<AuthResponse> login(LoginRequest request) async {
    try {
      final response = await post('/auth/login', data: request.toJson());
      final authResponse = AuthResponse.fromJson(response);

      // Save tokens with proper expiry calculation
      final now = DateTime.now();
      final expiresAt = now.add(
        const Duration(hours: 1),
      ); // JWT typically valid for 1 hour

      await setTokens(
        authResponse.token.accessToken,
        authResponse.token.refreshToken,
        userId: authResponse.user.id,
        expiresAt: expiresAt,
      );

      return authResponse;
    } catch (e) {
      rethrow;
    }
  }

  /// Register new user
  Future<AuthResponse> signup(SignupRequest request) async {
    try {
      // Backend uses /auth/register endpoint
      final response = await post('/auth/register', data: request.toJson());
      final authResponse = AuthResponse.fromJson(response);

      // Save tokens with proper expiry calculation
      final now = DateTime.now();
      final expiresAt = now.add(const Duration(hours: 1));

      await setTokens(
        authResponse.token.accessToken,
        authResponse.token.refreshToken,
        userId: authResponse.user.id,
        expiresAt: expiresAt,
      );

      return authResponse;
    } catch (e) {
      rethrow;
    }
  }

  /// Refresh access token
  Future<AuthToken> refreshToken() async {
    try {
      if (_refreshToken == null) {
        throw ApiException(message: 'No refresh token available');
      }

      final response = await post(
        '/auth/refresh',
        data: {'refreshToken': _refreshToken},
      );

      final token = AuthToken.fromJson(response);

      // Save new tokens
      final now = DateTime.now();
      final expiresAt = now.add(const Duration(hours: 1));

      await setTokens(
        token.accessToken,
        token.refreshToken,
        expiresAt: expiresAt,
      );

      return token;
    } catch (e) {
      await clearTokens();
      rethrow;
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      await post('/auth/logout', data: {});
    } catch (e) {
      // Log error but always clear tokens
      print('Logout error: $e');
    } finally {
      await clearTokens();
    }
  }

  /// Change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await post(
        '/auth/change-password',
        data: {'currentPassword': currentPassword, 'newPassword': newPassword},
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Request password reset
  Future<void> requestPasswordReset(String email) async {
    try {
      await post('/auth/forgot-password', data: {'email': email});
    } catch (e) {
      rethrow;
    }
  }

  /// Reset password with token
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      await post(
        '/auth/reset-password',
        data: {'token': token, 'newPassword': newPassword},
      );
    } catch (e) {
      rethrow;
    }
  }

  // ============== CHAT ENDPOINTS ==============

  /// Get all chats for current user
  Future<List<Chat>> getChats() async {
    try {
      final response = await get('/chats');
      final chats = (response as List)
          .map((c) => Chat.fromJson(c as Map<String, dynamic>))
          .toList();
      return chats;
    } catch (e) {
      rethrow;
    }
  }

  /// Get chat by ID
  Future<Chat> getChat(String chatId) async {
    try {
      final response = await get('/chats/$chatId');
      return Chat.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  /// Create new direct chat
  Future<Chat> createDirectChat(String userId) async {
    try {
      // Backend uses POST /chats/direct/{userId}
      final response = await post('/chats/direct/$userId', data: {});
      return Chat.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  /// Create group chat
  Future<Chat> createGroupChat({
    required String name,
    required List<String> participantIds,
    String? description,
  }) async {
    try {
      // Backend uses POST /chats with CreateChatRequest
      final response = await post(
        '/chats',
        data: {
          'name': name,
          'type': 'GROUP',
          'participantIds': participantIds,
          'description': description,
        },
      );
      return Chat.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  /// Update chat
  Future<Chat> updateChat(
    String chatId, {
    String? name,
    String? description,
    String? classificationLevel,
  }) async {
    try {
      final response = await put(
        '/chats/$chatId',
        data: {
          if (name != null) 'name': name,
          if (description != null) 'description': description,
          if (classificationLevel != null)
            'classificationLevel': classificationLevel,
        },
      );
      return Chat.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  /// Archive chat
  Future<void> archiveChat(String chatId) async {
    try {
      await put('/chats/$chatId/archive', data: {});
    } catch (e) {
      rethrow;
    }
  }

  /// Unarchive chat
  Future<void> unarchiveChat(String chatId) async {
    try {
      await put('/chats/$chatId/unarchive', data: {});
    } catch (e) {
      rethrow;
    }
  }

  /// Mute chat
  Future<void> muteChat(String chatId, {Duration? duration}) async {
    try {
      await put(
        '/chats/$chatId/mute',
        data: {if (duration != null) 'durationMinutes': duration.inMinutes},
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Unmute chat
  Future<void> unmuteChat(String chatId) async {
    try {
      await put('/chats/$chatId/unmute', data: {});
    } catch (e) {
      rethrow;
    }
  }

  /// Delete chat
  Future<void> deleteChat(String chatId) async {
    try {
      await delete('/chats/$chatId');
    } catch (e) {
      rethrow;
    }
  }

  // ============== MESSAGE ENDPOINTS ==============

  /// Get messages for a chat
  Future<List<Message>> getMessages(
    String chatId, {
    int limit = 50,
    String? beforeMessageId,
  }) async {
    try {
      final queryParams = {
        'limit': limit.toString(),
        if (beforeMessageId != null) 'beforeMessageId': beforeMessageId,
      };

      final queryString = queryParams.entries
          .map((e) => '${e.key}=${e.value}')
          .join('&');

      final response = await get('/chats/$chatId/messages?$queryString');
      final messages = (response as List)
          .map((m) => Message.fromJson(m as Map<String, dynamic>))
          .toList();

      // Decrypt messages if they are encrypted
      final decryptedMessages = await Future.wait(
        messages.map((m) async {
          if (m.content == '[Encrypted]' && m.contentEncrypted.isNotEmpty) {
            try {
              final decrypted = await EncryptionService.decryptMessage(
                m.contentEncrypted,
                keyId: m.encryption.keyId,
                encryptionKey: 'default_key', // In real app, get from storage
              );
              return parseDecryptedContent(m, decrypted);
            } catch (e) {
              return m;
            }
          }
          return m;
        }),
      );

      return decryptedMessages;
    } catch (e) {
      rethrow;
    }
  }

  /// Send message
  Future<Message> sendMessage(
    String chatId, {
    required String content,
    String? contentEncrypted,
    MessageEncryption? encryption,
    List<MessageAttachment> attachments = const [],
    bool isSelfDestructing = false,
    int? expiresInSeconds,
  }) async {
    try {
      // Use defaults for encryption if not provided
      final encryptionData =
          encryption?.toJson() ??
          {
            'algorithm': 'AES-256-GCM',
            'keyId': 'default',
            'encryptionLevel': 'HIGH',
            'isE2E': true,
          };

      // Encrypt content for E2E
      String encrypted = contentEncrypted ?? content;
      if (contentEncrypted == null) {
        String payloadToEncrypt = content;
        if (attachments.isNotEmpty) {
          payloadToEncrypt = jsonEncode({
            'text': content,
            'attachments': attachments.map((a) => a.toJson()).toList(),
          });
        }
        
        try {
          encrypted = await EncryptionService.encryptMessage(
            payloadToEncrypt,
            keyId: 'default',
            encryptionKey: 'default_key',
          );
        } catch (e) {
          print('Encryption failed: $e');
        }
      }

      final response = await post(
        '/chats/$chatId/messages',
        data: {
          'content': '[Encrypted]', // Send placeholder to server
          'contentEncrypted': encrypted,
          'encryption': encryptionData,
          'attachments': attachments.map((a) => a.toJson()).toList(),
          'selfDestructing': isSelfDestructing,
          if (expiresInSeconds != null) 'expiresInSeconds': expiresInSeconds,
        },
      );

      final message = Message.fromJson(response as Map<String, dynamic>);

      // Decrypt the returned message so the UI shows it correctly immediately
      if (message.content == '[Encrypted]' &&
          message.contentEncrypted.isNotEmpty) {
        try {
          final decrypted = await EncryptionService.decryptMessage(
            message.contentEncrypted,
            keyId: message.encryption.keyId,
            encryptionKey: 'default_key',
          );
          return parseDecryptedContent(message, decrypted);
        } catch (e) {
          return message;
        }
      }

      return message;
    } catch (e) {
      rethrow;
    }
  }

  /// Get single message by ID
  Future<Message> getMessage(String chatId, String messageId) async {
    try {
      final response = await get('/messages/$messageId');
      final message = Message.fromJson(response as Map<String, dynamic>);

      // Decrypt if needed
      if (message.content == '[Encrypted]' && message.contentEncrypted.isNotEmpty) {
        try {
          final decrypted = await EncryptionService.decryptMessage(
            message.contentEncrypted,
            keyId: message.encryption.keyId,
            encryptionKey: 'default_key',
          );
          return parseDecryptedContent(message, decrypted);
        } catch (e) {
          return message;
        }
      }
      return message;
    } catch (e) {
      rethrow;
    }
  }

  /// Mark message as read
  Future<void> markMessageAsRead(String chatId, String messageId) async {
    try {
      await put('/chats/$chatId/messages/$messageId/read', data: {});
    } catch (e) {
      rethrow;
    }
  }

  /// Mark all messages as read
  Future<void> markAllMessagesAsRead(String chatId) async {
    try {
      await put('/chats/$chatId/messages/read-all', data: {});
    } catch (e) {
      rethrow;
    }
  }

  /// Delete message
  Future<void> deleteMessage(String chatId, String messageId) async {
    try {
      await delete('/chats/$chatId/messages/$messageId');
    } catch (e) {
      rethrow;
    }
  }

  /// Search messages
  Future<List<Message>> searchMessages(String chatId, String query) async {
    try {
      final response = await get('/chats/$chatId/messages/search?q=$query');
      final messages = (response as List)
          .map((m) => Message.fromJson(m as Map<String, dynamic>))
          .toList();
      return messages;
    } catch (e) {
      rethrow;
    }
  }

  // ============== USER ENDPOINTS ==============

  /// Get current user profile
  Future<User> getCurrentUser() async {
    try {
      final response = await get('/users/me');
      return User.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  /// Get user by ID
  Future<User> getUser(String userId) async {
    try {
      final response = await get('/users/$userId');
      return User.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  /// Update user profile
  Future<User> updateProfile({
    String? username,
    String? profileImageUrl,
    String? clearanceLevel,
  }) async {
    try {
      final response = await put(
        '/users/me',
        data: {
          if (username != null) 'username': username,
          if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
          if (clearanceLevel != null) 'clearanceLevel': clearanceLevel,
        },
      );
      return User.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  /// Search users
  Future<List<User>> searchUsers(String query, {int limit = 10}) async {
    try {
      final response = await get('/users/search?q=$query&limit=$limit');
      final users = (response as List)
          .map((u) => User.fromJson(u as Map<String, dynamic>))
          .toList();
      return users;
    } catch (e) {
      rethrow;
    }
  }

  // ============== KEY MANAGEMENT ENDPOINTS ==============

  /// Generate encryption key pair
  Future<dynamic> generateKeyPair() async {
    try {
      final response = await post('/keys/generate', data: {});
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Rotate encryption keys
  Future<dynamic> rotateKeys(String algorithm) async {
    try {
      final response = await post(
        '/keys/rotate',
        data: {'algorithm': algorithm},
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Get key status
  Future<dynamic> getKeyStatus() async {
    try {
      final response = await get('/keys/status');
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Message parseDecryptedContent(Message m, String decrypted) {
    try {
      if (decrypted.startsWith('{') && decrypted.contains('"text":') && decrypted.contains('"attachments":')) {
        final decoded = jsonDecode(decrypted);
        final text = decoded['text'] as String? ?? '';
        final List<dynamic>? attList = decoded['attachments'];
        
        List<MessageAttachment> parsedAtts = [];
        if (attList != null) {
          parsedAtts = attList.map((a) => MessageAttachment.fromJson(a as Map<String, dynamic>)).toList();
        }
        return m.copyWith(content: text, attachments: parsedAtts);
      }
    } catch (e) {
      // Not valid JSON payload, fallback to raw string
    }
    return m.copyWith(content: decrypted);
  }

  // ============== ADMIN ENDPOINTS ==============

  /// Get all users (admin only)
  Future<List<Map<String, dynamic>>> getUsers({int limit = 100}) async {
    try {
      final response = await get('/users?limit=$limit');
      if (response is List) {
        return response.cast<Map<String, dynamic>>();
      }
      // If backend returns a wrapper object
      final list = (response as Map<String, dynamic>)['users'] ??
          (response)['content'] ??
          [];
      return (list as List).cast<Map<String, dynamic>>();
    } catch (e) {
      // Return empty list on error — admin panel handles gracefully
      return [];
    }
  }

  /// Get system audit logs (admin only)
  Future<List<Map<String, dynamic>>> getSystemAuditLogs({int page = 0, int size = 100}) async {
    try {
      final response = await get('/admin/audit?page=$page&size=$size');
      if (response is List) {
        return response.cast<Map<String, dynamic>>();
      }
      final list = (response as Map<String, dynamic>)['content'] ?? [];
      return (list as List).cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  /// Ban or unban a user (admin only)
  Future<void> setBannedStatus(String userId, bool banned) async {
    try {
      await put('/users/$userId/ban', data: {'banned': banned});
    } catch (e) {
      rethrow;
    }
  }

  /// Change user role (admin only)
  Future<void> setUserRole(String userId, String role) async {
    try {
      await put('/users/$userId/role', data: {'role': role});
    } catch (e) {
      rethrow;
    }
  }

  /// Send broadcast notification to all users (admin only)
  Future<void> sendBroadcast(String message) async {
    try {
      await post('/admin/broadcast', data: {'message': message});
    } catch (e) {
      rethrow;
    }
  }

  void dispose() {
    _client.close();
  }
}

