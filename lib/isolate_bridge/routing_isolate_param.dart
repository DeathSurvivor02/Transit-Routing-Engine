import 'dart:typed_data';
import '../../core/constants/transit_constants.dart';
import '../../core/geometry/coordinate.dart';

/// User preferences for transit routing queries.
class TransitPreferences {
  final int maxTransfers;
  final double walkingSpeedMps;
  final bool wheelchairAccessibleOnly;
  final bool preferFewerTransfers;

  const TransitPreferences({
    this.maxTransfers = TransitConstants.defaultMaxTransfers,
    this.walkingSpeedMps = TransitConstants.defaultWalkingSpeedMps,
    this.wheelchairAccessibleOnly = false,
    this.preferFewerTransfers = false,
  });
}

/// Parameter container sent to background isolate for path computation.
class RoutingIsolateParam {
  final String databasePath;
  final Uint8List encryptionKey;
  final Coordinate origin;
  final Coordinate destination;
  final int departureEpochSeconds;
  final int maxTransfers;
  final double walkingSpeedMps;
  final bool wheelchairAccessibleOnly;

  RoutingIsolateParam({
    required this.databasePath,
    required this.encryptionKey,
    required this.origin,
    required this.destination,
    required this.departureEpochSeconds,
    this.maxTransfers = TransitConstants.defaultMaxTransfers,
    this.walkingSpeedMps = TransitConstants.defaultWalkingSpeedMps,
    this.wheelchairAccessibleOnly = false,
  });
}
