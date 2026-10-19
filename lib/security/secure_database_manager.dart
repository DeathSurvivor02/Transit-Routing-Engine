import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sqlite3/sqlite3.dart';
import '../core/constants/transit_constants.dart';
import '../core/errors/security_exception.dart';
import '../core/utils/hex_codec.dart';

/// Manages SQLCipher database encryption keys and secure SQLite connections.
class SecureDatabaseManager {
  final FlutterSecureStorage _storage;

  SecureDatabaseManager({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                encryptedSharedPreferences: true,
                resetOnError: true,
              ),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock_this_device,
              ),
            );

  /// Retrieves or cryptographically generates the 256-bit database encryption key.
  Future<Uint8List> getOrCreateEncryptionKey({String keyId = TransitConstants.secureStorageKeyId}) async {
    final existingHexKey = await _storage.read(key: keyId);
    if (existingHexKey != null && existingHexKey.isNotEmpty) {
      return HexCodec.decode(existingHexKey);
    }

    // Generate 32 bytes (256 bits) of cryptographically secure random bytes
    final secureRandom = Random.secure();
    final keyBytes = Uint8List(32);
    for (int i = 0; i < 32; i++) {
      keyBytes[i] = secureRandom.nextInt(256);
    }

    await _storage.write(
      key: keyId,
      value: HexCodec.encode(keyBytes),
    );

    return keyBytes;
  }

  /// Opens an encrypted SQLCipher connection and verifies the key.
  Database openEncryptedDatabase(String path, Uint8List keyBytes) {
    final db = sqlite3.open(path);
    final hexKey = HexCodec.encode(keyBytes);

    try {
      // Apply SQLCipher pragmas before executing any schema operations
      db.execute("PRAGMA key = \"x'$hexKey'\";");
      db.execute('PRAGMA cipher_page_size = ${TransitConstants.cipherPageSize};');
      db.execute('PRAGMA kdf_iter = ${TransitConstants.cipherKdfIterations};');
      db.execute('PRAGMA cipher_hmac_algorithm = HMAC_SHA512;');
      db.execute('PRAGMA cipher_kdf_algorithm = PBKDF2_HMAC_SHA512;');

      // Verification check: ensure database header can be successfully decrypted
      final result = db.select('SELECT count(*) AS count FROM sqlite_master;');
      if (result.isEmpty) {
        throw const SecurityException('Decryption failed: Invalid key or corrupt header.');
      }

      return db;
    } catch (e) {
      db.dispose();
      if (e is SecurityException) rethrow;
      throw SecurityException('Failed to open encrypted database at $path: $e', e);
    }
  }

  /// Opens an unencrypted database (used for testing or pre-encryption migration).
  Database openPlainDatabase(String path) {
    return sqlite3.open(path);
  }
}
