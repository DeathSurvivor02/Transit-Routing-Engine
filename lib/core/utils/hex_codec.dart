import 'dart:typed_data';

/// Utility methods for hexadecimal string conversion and byte manipulation.
class HexCodec {
  static const String _hexChars = '0123456789abcdef';

  /// Encodes a byte array into a lowercase hex string.
  static String encode(Uint8List bytes) {
    final buffer = StringBuffer();
    for (int i = 0; i < bytes.length; i++) {
      final b = bytes[i];
      buffer.write(_hexChars[(b >> 4) & 0x0F]);
      buffer.write(_hexChars[b & 0x0F]);
    }
    return buffer.toString();
  }

  /// Decodes a hex string into a Uint8List.
  static Uint8List decode(String hex) {
    final cleaned = hex.replaceAll(RegExp(r'\s+'), '').toLowerCase();
    if (cleaned.length % 2 != 0) {
      throw FormatException('Invalid hex string length: ${cleaned.length}');
    }
    final result = Uint8List(cleaned.length ~/ 2);
    for (int i = 0; i < cleaned.length; i += 2) {
      final high = _hexChars.indexOf(cleaned[i]);
      final low = _hexChars.indexOf(cleaned[i + 1]);
      if (high == -1 || low == -1) {
        throw FormatException('Invalid hex character at index $i: "${cleaned.substring(i, i + 2)}"');
      }
      result[i ~/ 2] = (high << 4) | low;
    }
    return result;
  }
}
