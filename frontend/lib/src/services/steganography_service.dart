import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'dart:convert';
import 'dart:io';

class SteganographyService {
  /// Encodes [text] into [imageBytes] using LSB steganography.
  /// Returns the encoded image as PNG bytes.
  static Future<Uint8List?> encode(Uint8List imageBytes, String text) async {
    final image = img.decodeImage(imageBytes);
    if (image == null) return null;

    final secretData = utf8.encode(text);
    final dataLength = secretData.length;
    
    // We store the 32-bit length first
    final byteData = ByteData(4)..setUint32(0, dataLength);
    final totalBits = (4 + secretData.length) * 8;

    if (totalBits > image.width * image.height * 3) {
      throw Exception('Message too long for this image');
    }

    final bits = Uint8List(totalBits);
    
    // Convert length to bits
    for (var i = 0; i < 4; i++) {
      final byte = byteData.getUint8(i);
      for (var bit = 0; bit < 8; bit++) {
        bits[i * 8 + bit] = (byte >> (7 - bit)) & 1;
      }
    }

    // Convert message to bits
    for (var i = 0; i < secretData.length; i++) {
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
        
        // Modify R, G, B channels LSB
        var r = pixel.r.toInt();
        var g = pixel.g.toInt();
        var b = pixel.b.toInt();
        
        if (bitIndex < totalBits) {
          r = (r & ~1) | bits[bitIndex++];
        }
        if (bitIndex < totalBits) {
          g = (g & ~1) | bits[bitIndex++];
        }
        if (bitIndex < totalBits) {
          b = (b & ~1) | bits[bitIndex++];
        }

        image.setPixel(x, y, img.ColorInt8.rgb(r, g, b));
      }
      if (bitIndex >= totalBits) break;
    }

    return Uint8List.fromList(img.encodePng(image));
  }

  /// Decodes hidden text from [imageBytes].
  static Future<String?> decode(Uint8List imageBytes) async {
    final image = img.decodeImage(imageBytes);
    if (image == null) return null;

    // Read first 32 bits to get length
    final lengthBits = Uint8List(32);
    var bitIndex = 0;
    
    outerLoop:
    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        
        if (bitIndex < 32) lengthBits[bitIndex++] = pixel.r.toInt() & 1;
        if (bitIndex < 32) lengthBits[bitIndex++] = pixel.g.toInt() & 1;
        if (bitIndex < 32) lengthBits[bitIndex++] = pixel.b.toInt() & 1;
        
        if (bitIndex >= 32) break outerLoop;
      }
    }

    final lengthBytes = Uint8List(4);
    for (var i = 0; i < 4; i++) {
      var byte = 0;
      for (var bit = 0; bit < 8; bit++) {
        byte = (byte << 1) | lengthBits[i * 8 + bit];
      }
      lengthBytes[i] = byte;
    }
    
    final dataLength = ByteData.sublistView(lengthBytes).getUint32(0);
    if (dataLength == 0 || dataLength > 1000000) return null; // Safety check

    final totalBits = (4 + dataLength) * 8;
    final allBits = Uint8List(totalBits);
    bitIndex = 0;

    outerLoop2:
    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        
        if (bitIndex < totalBits) allBits[bitIndex++] = pixel.r.toInt() & 1;
        if (bitIndex < totalBits) allBits[bitIndex++] = pixel.g.toInt() & 1;
        if (bitIndex < totalBits) allBits[bitIndex++] = pixel.b.toInt() & 1;
        
        if (bitIndex >= totalBits) break outerLoop2;
      }
    }

    final messageBytes = Uint8List(dataLength);
    for (var i = 0; i < dataLength; i++) {
      var byte = 0;
      for (var bit = 0; bit < 8; bit++) {
        byte = (byte << 1) | allBits[(i + 4) * 8 + bit];
      }
      messageBytes[i] = byte;
    }

    try {
      return utf8.decode(messageBytes);
    } catch (e) {
      return null;
    }
  }
}
