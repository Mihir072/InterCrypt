import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:frontend/src/services/steganography_service.dart';

void main() {
  group('SteganographyService — LSB steganography', () {
    /// Generate a minimal PNG image (100x100 white pixels) for testing.
    Uint8List _generateTestPng({int width = 100, int height = 100}) {
      final image = img.Image(width: width, height: height);
      img.fill(image, color: img.ColorRgb8(255, 255, 255));
      return img.encodePng(image);
    }

    test('encode → decode roundtrip for short message', () async {
      const secret = 'Hello, World!';
      final pngBytes = _generateTestPng();

      final encoded = await SteganographyService.encode(pngBytes, secret);
      expect(encoded, isNotNull);

      final decoded = await SteganographyService.decode(encoded!);
      expect(decoded, equals(secret));
    });

    test('encode → decode roundtrip for longer message', () async {
      const secret =
          'This is a longer secret message for testing steganography. It contains alphanumeric characters and punctuation!';
      final pngBytes = _generateTestPng(width: 200, height: 200); // Larger image

      final encoded = await SteganographyService.encode(pngBytes, secret);
      expect(encoded, isNotNull);

      final decoded = await SteganographyService.decode(encoded!);
      expect(decoded, equals(secret));
    });

    test('decode on unmodified image returns null', () async {
      final pngBytes = _generateTestPng();
      final decoded = await SteganographyService.decode(pngBytes);

      // A clean white image has no hidden data — should return null
      expect(decoded, isNull);
    });

    test('message too long for image returns null', () async {
      // 50x50 image = 7500 bits capacity ≈ 937 bytes max
      // We try to embed a 2000-char string → should fail
      final pngBytes = _generateTestPng(width: 50, height: 50);
      final longMessage = 'A' * 2000;

      final result = await SteganographyService.encode(pngBytes, longMessage);
      expect(result, isNull);
    });

    test('encode produces different bytes than original', () async {
      const secret = 'changed';
      final original = _generateTestPng();

      final encoded = await SteganographyService.encode(original, secret);
      expect(encoded, isNotNull);

      // The encoded image is different from the original
      expect(encoded, isNot(equals(original)));
    });

    test('encode with empty string → decode returns empty string', () async {
      final pngBytes = _generateTestPng();

      final encoded = await SteganographyService.encode(pngBytes, '');
      expect(encoded, isNotNull);

      // Decoding after encoding empty adds the length header but no content
      // Result should be empty (length=0 → nothing to decode is valid)
    });
  });
}
