import 'dart:typed_data';

/// In-memory cryptographic zeroization utility.
class MemoryZeroizer {
  /// Securely overwrites the given byte buffer with zeroes in place.
  static void zeroize(Uint8List sensitiveData) {
    for (int i = 0; i < sensitiveData.length; i++) {
      sensitiveData[i] = 0;
    }
  }

  /// Executes an operation with a sensitive key buffer, then guarantees zeroization in a finally block.
  static T withZeroizedKey<T>(Uint8List keyBytes, T Function(Uint8List key) operation) {
    try {
      return operation(keyBytes);
    } finally {
      zeroize(keyBytes);
    }
  }

  /// Async variant for zeroization.
  static Future<T> withZeroizedKeyAsync<T>(
    Uint8List keyBytes,
    Future<T> Function(Uint8List key) operation,
  ) async {
    try {
      return await operation(keyBytes);
    } finally {
      zeroize(keyBytes);
    }
  }
}
