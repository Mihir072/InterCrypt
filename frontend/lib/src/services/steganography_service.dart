import 'dart:convert';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:flutter/foundation.dart';

class SteganographyService {
  /// Encodes [text] into [imageBytes] using LSB steganography.
  /// Returns the encoded image as PNG bytes.
  static Future<Uint8List?> encode(Uint8List imageBytes, String text) async {
    try {
      debugPrint('Steganography: Starting encode for ${text.length} chars...');
      return await compute(_encodeWrapper, {'bytes': imageBytes, 'text': text});
    } catch (e) {
      debugPrint('Steganography encode compute error: $e');
      return null;
    }
  }

  /// Decodes hidden text from [imageBytes].
  static Future<String?> decode(Uint8List imageBytes) async {
    try {
      debugPrint('Steganography: Starting decode for image of ${imageBytes.length} bytes...');
      return await compute(_decodeWrapper, imageBytes);
    } catch (e) {
      debugPrint('Steganography decode compute error: $e');
      return null;
    }
  }

  static Uint8List? _encodeSync(Uint8List imageBytes, String text) {
    try {
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        debugPrint('Steganography Encode: Image format not recognized');
        return null;
      }

      final secretData = utf8.encode(text);
      final dataLength = secretData.length;
      
      final byteData = ByteData(4)..setUint32(0, dataLength);
      final totalBits = (4 + dataLength) * 8;

      if (totalBits > image.width * image.height * 3) {
        throw Exception('Message too long for this image (${text.length} chars)');
      }

      final bits = Uint8List(totalBits);
      
      // Length to bits (Big Endian)
      for (var i = 0; i < 4; i++) {
        final byte = byteData.getUint8(i);
        for (var bit = 0; bit < 8; bit++) {
          bits[i * 8 + bit] = (byte >> (7 - bit)) & 1;
        }
      }

      // Message to bits
      for (var i = 0; i < dataLength; i++) {
        final byte = secretData[i];
        for (var bit = 0; bit < 8; bit++) {
          bits[(i + 4) * 8 + bit] = (byte >> (7 - bit)) & 1;
        }
      }

      var bitIndex = 0;
      for (var y = 0; y < image.height; y++) {
        for (var x = 0; x < image.width; x++) {
          if (bitIndex >= totalBits) break;

          final pixel = image.getPixel(x, y);
          var r = pixel.r.toInt();
          var g = pixel.g.toInt();
          var b = pixel.b.toInt();
          
          if (bitIndex < totalBits) r = (r & ~1) | bits[bitIndex++];
          if (bitIndex < totalBits) g = (g & ~1) | bits[bitIndex++];
          if (bitIndex < totalBits) b = (b & ~1) | bits[bitIndex++];

          image.setPixelRgb(x, y, r, g, b);
        }
        if (bitIndex >= totalBits) break;
      }

      debugPrint('Steganography: Successfully encoded $dataLength bytes');
      return img.encodePng(image);
    } catch (e) {
      debugPrint('Steganography encode error: $e');
      return null;
    }
  }

  static String? _decodeSync(Uint8List imageBytes) {
    try {
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        debugPrint('Steganography Decode: Image format not recognized');
        return null;
      }

      final lengthBits = Uint8List(32);
      var bitIndex = 0;
      
      // Extract first 32 bits to get length
      for (var y = 0; y < image.height; y++) {
        for (var x = 0; x < image.width; x++) {
          final pixel = image.getPixel(x, y);
          if (bitIndex < 32) lengthBits[bitIndex++] = pixel.r.toInt() & 1;
          if (bitIndex < 32) lengthBits[bitIndex++] = pixel.g.toInt() & 1;
          if (bitIndex < 32) lengthBits[bitIndex++] = pixel.b.toInt() & 1;
          if (bitIndex >= 32) break;
        }
        if (bitIndex >= 32) break;
      }

      if (bitIndex < 32) return null;

      final lengthBytes = Uint8List(4);
      for (var i = 0; i < 4; i++) {
        var byte = 0;
        for (var bit = 0; bit < 8; bit++) {
          byte = (byte << 1) | lengthBits[i * 8 + bit];
        }
        lengthBytes[i] = byte;
      }
      
      final dataLength = ByteData.sublistView(lengthBytes).getUint32(0);
      if (dataLength == 0 || dataLength > 1000000) {
        debugPrint('Steganography: Invalid data length detected ($dataLength)');
        return null;
      }

      final totalBits = (4 + dataLength) * 8;
      final allBits = Uint8List(totalBits);
      bitIndex = 0;

      // Extract all bits
      for (var y = 0; y < image.height; y++) {
        for (var x = 0; x < image.width; x++) {
          final pixel = image.getPixel(x, y);
          if (bitIndex < totalBits) allBits[bitIndex++] = pixel.r.toInt() & 1;
          if (bitIndex < totalBits) allBits[bitIndex++] = pixel.g.toInt() & 1;
          if (bitIndex < totalBits) allBits[bitIndex++] = pixel.b.toInt() & 1;
          if (bitIndex >= totalBits) break;
        }
        if (bitIndex >= totalBits) break;
      }

      if (bitIndex < totalBits) return null;

      final messageBytes = Uint8List(dataLength);
      for (var i = 0; i < dataLength; i++) {
        var byte = 0;
        for (var bit = 0; bit < 8; bit++) {
          byte = (byte << 1) | allBits[(i + 4) * 8 + bit];
        }
        messageBytes[i] = byte;
      }

      final result = utf8.decode(messageBytes);
      debugPrint('Steganography: Successfully decoded ${result.length} characters');
      return result;
    } catch (e) {
      debugPrint('Steganography decode error: $e');
      return null;
    }
  }
}

/// Top-level wrappers for compute compatibility
Uint8List? _encodeWrapper(Map<String, dynamic> params) {
  return SteganographyService._encodeSync(params['bytes'] as Uint8List, params['text'] as String);
}

String? _decodeWrapper(Uint8List bytes) {
  return SteganographyService._decodeSync(bytes);
}



