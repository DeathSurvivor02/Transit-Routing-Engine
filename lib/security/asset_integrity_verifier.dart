import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import '../core/errors/security_exception.dart';

/// Cryptographic verification utility for database assets and delta packages.
class AssetIntegrityVerifier {
  /// Verifies the HMAC-SHA256 signature of an asset against an expected hex string.
  static void verifyAssetIntegrity({
    required Uint8List assetBytes,
    required String expectedHmacHex,
    required Uint8List secretHmacKey,
  }) {
    final hmac = Hmac(sha256, secretHmacKey);
    final calculatedMac = hmac.convert(assetBytes).toString().toLowerCase();
    final expectedNormalized = expectedHmacHex.trim().toLowerCase();

    if (!_constantTimeEquals(calculatedMac, expectedNormalized)) {
      throw const SecurityException(
        'Database bundle failed integrity verification. Possible tampering detected.',
      );
    }
  }

  /// Verifies standard SHA-256 hash against expected checksum.
  static void verifySha256Checksum({
    required Uint8List assetBytes,
    required String expectedSha256Hex,
  }) {
    final calculatedSha = sha256.convert(assetBytes).toString().toLowerCase();
    final expectedNormalized = expectedSha256Hex.trim().toLowerCase();

    if (!_constantTimeEquals(calculatedSha, expectedNormalized)) {
      throw const SecurityException(
        'Database checksum mismatch. Bundle corrupted or tampered.',
      );
    }
  }

  /// Constant-time string equality to protect against timing analysis.
  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }
}
