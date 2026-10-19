import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/core/errors/security_exception.dart';
import '../../lib/security/asset_integrity_verifier.dart';

void main() {
  group('AssetIntegrityVerifier Tests', () {
    final secretKey = Uint8List.fromList(utf8.encode('super_secret_offline_transit_key_123'));
    final assetData = Uint8List.fromList(utf8.encode('Sample pre-bundled transit SQLite DB payload'));

    test('Verifies valid HMAC-SHA256 signature without exception', () {
      final hmac = Hmac(sha256, secretKey);
      final validHmacHex = hmac.convert(assetData).toString();

      expect(
        () => AssetIntegrityVerifier.verifyAssetIntegrity(
          assetBytes: assetData,
          expectedHmacHex: validHmacHex,
          secretHmacKey: secretKey,
        ),
        returnsNormally,
      );
    });

    test('Throws SecurityException when HMAC signature is invalid or tampered', () {
      const tamperedHex = 'a1b2c3d4e5f60718293a4b5c6d7e8f900123456789abcdef0123456789abcdef';

      expect(
        () => AssetIntegrityVerifier.verifyAssetIntegrity(
          assetBytes: assetData,
          expectedHmacHex: tamperedHex,
          secretHmacKey: secretKey,
        ),
        throwsA(isA<SecurityException>()),
      );
    });

    test('Throws SecurityException when data payload has been modified', () {
      final hmac = Hmac(sha256, secretKey);
      final validHmacHex = hmac.convert(assetData).toString();

      final tamperedData = Uint8List.fromList(utf8.encode('Modified payload injected!'));

      expect(
        () => AssetIntegrityVerifier.verifyAssetIntegrity(
          assetBytes: tamperedData,
          expectedHmacHex: validHmacHex,
          secretHmacKey: secretKey,
        ),
        throwsA(isA<SecurityException>()),
      );
    });
  });
}
