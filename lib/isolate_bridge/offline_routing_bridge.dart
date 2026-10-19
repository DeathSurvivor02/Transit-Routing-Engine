import 'dart:isolate';
import 'dart:typed_data';
import '../../core/geometry/coordinate.dart';
import '../local_engine/routing/local_transit_graph_engine.dart';
import 'itinerary_dto.dart';
import 'routing_isolate_param.dart';
import 'routing_result_dto.dart';

/// Zero-stutter bridge offloading heavy transit routing graph traversals to a background isolate.
class OfflineRoutingBridge {
  final String databasePath;
  final Uint8List encryptionKey;
  final bool isEncrypted;

  OfflineRoutingBridge({
    required this.databasePath,
    required this.encryptionKey,
    this.isEncrypted = true,
  });

  /// Calculates the fastest route in a background isolate.
  Future<RoutingResultDto> calculateRoute({
    required Coordinate origin,
    required Coordinate destination,
    required DateTime departureTime,
    TransitPreferences preferences = const TransitPreferences(),
  }) async {
    final payload = RoutingIsolateParam(
      databasePath: databasePath,
      encryptionKey: encryptionKey,
      origin: origin,
      destination: destination,
      departureEpochSeconds: departureTime.millisecondsSinceEpoch ~/ 1000,
      maxTransfers: preferences.maxTransfers,
      walkingSpeedMps: preferences.walkingSpeedMps,
      wheelchairAccessibleOnly: preferences.wheelchairAccessibleOnly,
    );

    // Offload compute to background isolate using Isolate.run
    return await Isolate.run<RoutingResultDto>(() => _executeRoutingInIsolate(payload, isEncrypted));
  }

  /// Top-level or static isolate entry function
  static RoutingResultDto _executeRoutingInIsolate(RoutingIsolateParam param, bool isEncrypted) {
    // 1. Initialize local isolate SQLite/SQLCipher connection
    final LocalTransitGraphEngine engine = isEncrypted
        ? LocalTransitGraphEngine.openEncrypted(
            path: param.databasePath,
            key: param.encryptionKey,
          )
        : LocalTransitGraphEngine.openPlain(
            path: param.databasePath,
          );

    try {
      // 2. Perform graph search with dynamic signal wait times
      final itineraryResult = engine.findFastestPath(
        origin: param.origin,
        destination: param.destination,
        startTime: param.departureEpochSeconds,
        walkingSpeedMps: param.walkingSpeedMps,
        maxTransfers: param.maxTransfers,
      );
      return itineraryResult;
    } finally {
      engine.close();
    }
  }
}
