/// System-wide constants for the Transit Routing Engine.
class TransitConstants {
  static const String databaseAssetPath = 'assets/database/transit_offline.db';
  static const String databaseFilename = 'transit_offline.db';
  static const String manifestAssetPath = 'assets/database/manifest.json';
  static const String secureStorageKeyId = 'com.transit.offline.db_key';

  /// Default pedestrian walking speed in meters per second (~4.5 km/h)
  static const double defaultWalkingSpeedMps = 1.25;

  /// Default maximum transit transfers allowed in an itinerary
  static const int defaultMaxTransfers = 3;

  /// Maximum walking search radius for station snapping in meters
  static const double maxStationSnapRadiusMeters = 800.0;

  /// SQLite page size for SQLCipher
  static const int cipherPageSize = 4096;

  /// PBKDF2 iteration count for SQLCipher key derivation
  static const int cipherKdfIterations = 256000;
}
