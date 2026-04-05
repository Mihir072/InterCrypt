import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/src/services/encryption_service.dart';

void main() {
  group('EncryptionService — AES-256-GCM', () {
    const testKey = 'test-key-for-encryption-service-32'; // will be padded
    const keyId = 'test-key-id';

    test('encryptMessage → decryptMessage roundtrip', () async {
      const plaintext = 'Hello, IntelCrypt! This is a secret message.';

      final encrypted = await EncryptionService.encryptMessage(
        plaintext,
        keyId: keyId,
        encryptionKey: testKey,
      );

      // Should be in iv:ciphertext format
      expect(encrypted.contains(':'), isTrue);
      expect(encrypted, isNot(equals(plaintext)));

      final decrypted = await EncryptionService.decryptMessage(
        encrypted,
        keyId: keyId,
        encryptionKey: testKey,
      );

      expect(decrypted, equals(plaintext));
    });

    test('encryptMessage produces different ciphertext for same input (random IV)', () async {
      const plaintext = 'Same message twice';

      final enc1 = await EncryptionService.encryptMessage(
        plaintext,
        keyId: keyId,
        encryptionKey: testKey,
      );
      final enc2 = await EncryptionService.encryptMessage(
        plaintext,
        keyId: keyId,
        encryptionKey: testKey,
      );

      // Same plaintext + different random IVs → different ciphertexts
      expect(enc1, isNot(equals(enc2)));

      // Both must still decrypt correctly
      final dec1 = await EncryptionService.decryptMessage(
          enc1, keyId: keyId, encryptionKey: testKey);
      final dec2 = await EncryptionService.decryptMessage(
          enc2, keyId: keyId, encryptionKey: testKey);

      expect(dec1, equals(plaintext));
      expect(dec2, equals(plaintext));
    });

    test('decryptMessage fails gracefully on tampered ciphertext', () async {
      const plaintext = 'Tamper test';

      final encrypted = await EncryptionService.encryptMessage(
        plaintext,
        keyId: keyId,
        encryptionKey: testKey,
      );

      final parts = encrypted.split(':');
      final tamperedCipher = '${parts[0]}:AAAAAAAAAA==';

      expect(
        () => EncryptionService.decryptMessage(
          tamperedCipher,
          keyId: keyId,
          encryptionKey: testKey,
        ),
        throwsA(isA<EncryptionException>()),
      );
    });

    test('generateSymmetricKey returns valid 32-byte base64 key', () async {
      final key = await EncryptionService.generateSymmetricKey();
      final decoded = base64.decode(key);
      expect(decoded.length, equals(32)); // 256 bits
    });

    test('generateSymmetricKey produces different keys on each call', () async {
      final key1 = await EncryptionService.generateSymmetricKey();
      final key2 = await EncryptionService.generateSymmetricKey();
      expect(key1, isNot(equals(key2)));
    });

    test('hashData returns consistent SHA-256 hex string', () async {
      const data = 'password123';
      final hash1 = await EncryptionService.hashData(data);
      final hash2 = await EncryptionService.hashData(data);

      expect(hash1, equals(hash2));
      expect(hash1.length, equals(64)); // SHA-256 hex = 64 chars
    });

    test('hashData produces different hash for different inputs', () async {
      final hash1 = await EncryptionService.hashData('abc');
      final hash2 = await EncryptionService.hashData('abcd');
      expect(hash1, isNot(equals(hash2)));
    });

    test('generateSignature → verifySignature roundtrip', () async {
      const data = 'data-to-sign';
      const key = 'signing-key';

      final sig = await EncryptionService.generateSignature(data, key: key);
      final valid = await EncryptionService.verifySignature(data, sig, key: key);

      expect(valid, isTrue);
    });

    test('verifySignature returns false for tampered data', () async {
      const key = 'signing-key';
      final sig = await EncryptionService.generateSignature('original', key: key);
      final valid = await EncryptionService.verifySignature('tampered', sig, key: key);

      expect(valid, isFalse);
    });

    test('deriveKey returns consistent 32-byte base64 for same password+salt', () async {
      final key1 = await EncryptionService.deriveKey('mypassword', salt: 'mysalt');
      final key2 = await EncryptionService.deriveKey('mypassword', salt: 'mysalt');

      expect(key1, equals(key2));
      expect(base64.decode(key1).length, equals(32));
    });

    test('deriveKey produces different keys for different passwords', () async {
      final key1 = await EncryptionService.deriveKey('password1', salt: 'salt');
      final key2 = await EncryptionService.deriveKey('password2', salt: 'salt');

      expect(key1, isNot(equals(key2)));
    });

    test('maskEmail hides username correctly', () {
      expect(EncryptionService.maskEmail('john@example.com'), equals('j***@example.com'));
      expect(EncryptionService.maskEmail('ab@test.org'), equals('a*@test.org'));
    });

    test('generateRandomString returns correct length with secure entropy', () {
      final s = EncryptionService.generateRandomString(24);
      expect(s.length, equals(24));
      // Should only contain alphanumeric characters
      expect(RegExp(r'^[A-Za-z0-9]+$').hasMatch(s), isTrue);
    });
  });
}
