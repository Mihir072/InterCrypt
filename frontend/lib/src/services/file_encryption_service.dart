import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter/foundation.dart';

/// Result of a file encryption operation.
class FileEncryptionResult {
  final Uint8List encryptedBytes;
  final String iv; // base64-encoded 12-byte GCM nonce
  final String key; // base64-encoded 32-byte AES key
  final String keyId;

  const FileEncryptionResult({
    required this.encryptedBytes,
    required this.iv,
    required this.key,
    required this.keyId,
  });

  Map<String, dynamic> toJson() => {
        'iv': iv,
        'keyId': keyId,
        // 'key' is NOT serialized - stored separately in secure storage
      };
}

/// Service for encrypting and decrypting file attachments (AES-256-GCM).
///
/// All heavy operations are offloaded to an isolate via [compute] to prevent
/// UI jank.
class FileEncryptionService {
  // ── Encrypt ────────────────────────────────────────────────────────────────

  /// Encrypt [fileBytes] with a freshly generated AES-256-GCM key.
  static Future<FileEncryptionResult> encryptFile(Uint8List fileBytes) async {
    final key = _generateKey();
    final iv = _generateIV();
    final keyId = _generateKeyId();

    final encryptedBytes = await compute(_encryptBytes, {
      'bytes': fileBytes,
      'key': key,
      'iv': iv,
    });

    return FileEncryptionResult(
      encryptedBytes: encryptedBytes,
      iv: iv,
      key: key,
      keyId: keyId,
    );
  }

  /// Encrypt [fileBytes] with a **given** base64-encoded [keyBase64] and [ivBase64].
  /// Useful for re-encrypting with a shared key.
  static Future<Uint8List> encryptFileWithKey(
    Uint8List fileBytes, {
    required String keyBase64,
    required String ivBase64,
  }) async {
    return compute(_encryptBytes, {
      'bytes': fileBytes,
      'key': keyBase64,
      'iv': ivBase64,
    });
  }

  // ── Decrypt ────────────────────────────────────────────────────────────────

  /// Decrypt [encryptedBytes] using [keyBase64] and [ivBase64].
  static Future<Uint8List> decryptFile(
    Uint8List encryptedBytes, {
    required String keyBase64,
    required String ivBase64,
  }) async {
    return compute(_decryptBytes, {
      'bytes': encryptedBytes,
      'key': keyBase64,
      'iv': ivBase64,
    });
  }

  // ── Key helpers ────────────────────────────────────────────────────────────

  /// Generate a cryptographically secure 256-bit AES key (base64).
  static String _generateKey() {
    final random = Random.secure();
    final bytes = Uint8List.fromList(
      List.generate(32, (_) => random.nextInt(256)),
    );
    return base64.encode(bytes);
  }

  /// Generate a 96-bit (12-byte) GCM nonce (base64).
  static String _generateIV() {
    final random = Random.secure();
    final bytes = Uint8List.fromList(
      List.generate(12, (_) => random.nextInt(256)),
    );
    return base64.encode(bytes);
  }

  /// Generate a unique key identifier.
  static String _generateKeyId() {
    final random = Random.secure();
    final bytes = Uint8List.fromList(
      List.generate(16, (_) => random.nextInt(256)),
    );
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  /// Maximum allow file size (25 MB — matches backend limit).
  static const int maxFileSizeBytes = 25 * 1024 * 1024;

  /// Check if a file exceeds the allowed size.
  static bool isFileTooLarge(int sizeBytes) => sizeBytes > maxFileSizeBytes;

  /// Human-readable file size string.
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }
}

// ── Top-level isolate functions ────────────────────────────────────────────────

Uint8List _encryptBytes(Map<String, dynamic> params) {
  final bytes = params['bytes'] as Uint8List;
  final keyBase64 = params['key'] as String;
  final ivBase64 = params['iv'] as String;

  final key = enc.Key.fromBase64(_adjustKeyLength(keyBase64));
  final iv = enc.IV.fromBase64(ivBase64);
  final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.gcm));
  final encrypted = encrypter.encryptBytes(bytes, iv: iv);
  return Uint8List.fromList(encrypted.bytes);
}

Uint8List _decryptBytes(Map<String, dynamic> params) {
  final bytes = params['bytes'] as Uint8List;
  final keyBase64 = params['key'] as String;
  final ivBase64 = params['iv'] as String;

  final key = enc.Key.fromBase64(_adjustKeyLength(keyBase64));
  final iv = enc.IV.fromBase64(ivBase64);
  final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.gcm));
  final encrypted = enc.Encrypted(bytes);
  final decryptedBytes = encrypter.decryptBytes(encrypted, iv: iv);
  return Uint8List.fromList(decryptedBytes);
}

/// Ensure a base64 key decodes to exactly 32 bytes (pad/trim otherwise).
String _adjustKeyLength(String keyBase64) {
  try {
    final decoded = base64.decode(keyBase64);
    if (decoded.length == 32) return keyBase64;
    final adjusted = Uint8List(32);
    final len = decoded.length < 32 ? decoded.length : 32;
    adjusted.setRange(0, len, decoded);
    return base64.encode(adjusted);
  } catch (_) {
    final bytes = utf8.encode(keyBase64);
    final adjusted = Uint8List(32);
    final len = bytes.length < 32 ? bytes.length : 32;
    adjusted.setRange(0, len, bytes);
    return base64.encode(adjusted);
  }
}
