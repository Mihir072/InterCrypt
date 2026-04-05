import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/src/services/file_encryption_service.dart';

void main() {
  group('FileEncryptionService — AES-256-GCM file encryption', () {
    test('encryptFile → decryptFile roundtrip (small binary)', () async {
      final original = Uint8List.fromList(List.generate(256, (i) => i % 256));

      final result = await FileEncryptionService.encryptFile(original);

      expect(result.encryptedBytes, isNotEmpty);
      expect(result.iv, isNotEmpty);
      expect(result.key, isNotEmpty);
      expect(result.keyId, isNotEmpty);

      // Encrypted bytes should differ from original
      expect(result.encryptedBytes, isNot(equals(original)));

      // Decrypt and verify match
      final decrypted = await FileEncryptionService.decryptFile(
        result.encryptedBytes,
        keyBase64: result.key,
        ivBase64: result.iv,
      );

      expect(decrypted, equals(original));
    });

    test('encryptFile → decryptFile roundtrip (UTF-8 text file)', () async {
      const text = 'IntelCrypt secure file — confidential!';
      final original = Uint8List.fromList(utf8.encode(text));

      final result = await FileEncryptionService.encryptFile(original);
      final decrypted = await FileEncryptionService.decryptFile(
        result.encryptedBytes,
        keyBase64: result.key,
        ivBase64: result.iv,
      );

      expect(utf8.decode(decrypted), equals(text));
    });

    test('decryptFile fails with wrong key', () async {
      final original = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]);
      final result = await FileEncryptionService.encryptFile(original);

      final wrongKey = await FileEncryptionService.encryptFile(original);

      expect(
        () => FileEncryptionService.decryptFile(
          result.encryptedBytes,
          keyBase64: wrongKey.key, // Wrong key!
          ivBase64: result.iv,
        ),
        throwsException,
      );
    });

    test('two encryptions of same file produce different ciphertext', () async {
      final original = Uint8List.fromList([10, 20, 30, 40, 50]);

      final enc1 = await FileEncryptionService.encryptFile(original);
      final enc2 = await FileEncryptionService.encryptFile(original);

      // Different keys and IVs → different ciphertexts
      expect(enc1.key, isNot(equals(enc2.key)));
      expect(enc1.iv, isNot(equals(enc2.iv)));
      expect(enc1.encryptedBytes, isNot(equals(enc2.encryptedBytes)));
    });

    test('isFileTooLarge returns false for normal file', () {
      expect(FileEncryptionService.isFileTooLarge(1024 * 1024), isFalse); // 1MB
    });

    test('isFileTooLarge returns true for huge file', () {
      expect(
        FileEncryptionService.isFileTooLarge(30 * 1024 * 1024), // 30MB > 25MB limit
        isTrue,
      );
    });

    test('formatFileSize returns correct human-readable strings', () {
      expect(FileEncryptionService.formatFileSize(512), equals('512B'));
      expect(FileEncryptionService.formatFileSize(1536), equals('1.5KB'));
      expect(FileEncryptionService.formatFileSize(2 * 1024 * 1024), equals('2.0MB'));
    });
  });
}
