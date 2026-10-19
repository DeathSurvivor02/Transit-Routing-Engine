import 'dart:math' as math;
import 'dart:typed_data';
import 'package:sqlite3/sqlite3.dart';
import '../../core/constants/transit_constants.dart';
import '../../core/geometry/coordinate.dart';
import '../../core/geometry/haversine.dart';
import '../../isolate_bridge/itinerary_dto.dart';
import '../../isolate_bridge/routing_result_dto.dart';
import '../../security/memory_zeroizer.dart';
import '../../security/secure_database_manager.dart';
import '../models/route.dart';
import '../models/signal_timing_plan.dart';
import '../models/stop.dart';
import '../models/street_edge.dart';
import '../spatial/rtree_spatial_index.dart';
import 'connection_scan_algorithm.dart';
import 'graph_node.dart';
import 'time_dependent_astar.dart';

/// Local transit graph engine executing offline multimodal path queries.
class LocalTransitGraphEngine {
  final Database _db;
  late final RtreeSpatialIndex _spatialIndex;
  final Map<String, TransitRoute> _routesCache = {};
  final Map<String, Stop> _stopsCache = {};
  final Map<String, SignalTimingPlan> _signalPlansCache = {};

  LocalTransitGraphEngine._(this._db) {
    _spatialIndex = RtreeSpatialIndex(_db);
    _populateCaches();
  }

  /// Opens an encrypted SQLCipher database connection and initializes the engine.
  factory LocalTransitGraphEngine.openEncrypted({
    required String path,
    required Uint8List key,
  }) {
    final manager = SecureDatabaseManager();
    final db = manager.openEncryptedDatabase(path, key);
    return LocalTransitGraphEngine._(db);
  }

  /// Opens a plain database (for testing environments).
  factory LocalTransitGraphEngine.openPlain({required String path}) {
    final manager = SecureDatabaseManager();
    final db = manager.openPlainDatabase(path);
    return LocalTransitGraphEngine._(db);
  }

  void _populateCaches() {
    // Cache routes
    final routeRows = _db.select('SELECT * FROM routes;');
    for (final r in routeRows) {
      final route = TransitRoute.fromMap(r);
      _routesCache[route.routeId] = route;
    }

    // Cache stops
    final stopRows = _db.select('SELECT * FROM stops;');
    for (final s in stopRows) {
      final stop = Stop.fromMap(s);
      _stopsCache[stop.stopId] = stop;
    }

    // Cache signal plans
    final signalRows = _db.select('''
      SELECT p.*, s.cycle_length_sec 
      FROM signal_timing_plans p
      JOIN traffic_signals s ON s.signal_id = p.signal_id;
    ''');
    for (final sp in signalRows) {
      final plan = SignalTimingPlan.fromMap(sp);
      _signalPlansCache[plan.signalId] = plan;
    }
  }

  /// Closes database connection.
  void close() {
    _db.dispose();
  }

  /// Finds the fastest multimodal route between origin and destination coordinates.
  RoutingResultDto findFastestPath({
    required Coordinate origin,
    required Coordinate destination,
    required int startTime, // Epoch seconds
    double walkingSpeedMps = TransitConstants.defaultWalkingSpeedMps,
    int maxTransfers = TransitConstants.defaultMaxTransfers,
  }) {
    final stopwatch = Stopwatch()..start();

    try {
      // 1. Direct walk distance check
      final directWalkDist = Haversine.distanceMeters(origin, destination);
      final directWalkTime = (directWalkDist / walkingSpeedMps).round();

      final List<ItineraryDto> itineraries = [];

      // Create direct walking itinerary
      final directWalkLeg = RouteLegDto(
        legType: LegType.walking,
        fromStopName: 'Origin',
        toStopName: 'Destination',
        fromCoordinate: origin,
        toCoordinate: destination,
        departureEpochSeconds: startTime,
        arrivalEpochSeconds: startTime + directWalkTime,
        distanceMeters: directWalkDist,
        waypoints: [origin, destination],
        instruction: 'Walk directly to destination (${(directWalkDist).round()}m)',
      );

      final directWalkItinerary = ItineraryDto(
        itineraryId: 'walk-direct-${DateTime.now().millisecondsSinceEpoch}',
        departureEpochSeconds: startTime,
        arrivalEpochSeconds: startTime + directWalkTime,
        totalDistanceMeters: directWalkDist,
        transferCount: 0,
        legs: [directWalkLeg],
      );

      // If destination is within 600m, direct walk is high priority
      if (directWalkDist <= 600.0) {
        itineraries.add(directWalkItinerary);
      }

      // 2. Spatial snap to nearest origin and destination stations
      final originStops = _spatialIndex.findNearbyStops(
        center: origin,
        radiusMeters: TransitConstants.maxStationSnapRadiusMeters,
        limit: 5,
      );

      final destStops = _spatialIndex.findNearbyStops(
        center: destination,
        radiusMeters: TransitConstants.maxStationSnapRadiusMeters,
        limit: 5,
      );

      if (originStops.isNotEmpty && destStops.isNotEmpty) {
        // Query timetable connections for CSA
        // Normalize time of day in seconds from midnight
        final date = DateTime.fromMillisecondsSinceEpoch(startTime * 1000, isUtc: true);
        final secondsFromMidnight = date.hour * 3600 + date.minute * 60 + date.second;

        final connectionRows = _db.select('''
          SELECT st1.trip_id, t.route_id, st1.stop_id AS from_stop_id, 
                 st2.stop_id AS to_stop_id, st1.departure_time, st2.arrival_time, st1.stop_sequence
          FROM stop_times st1
          JOIN stop_times st2 ON st1.trip_id = st2.trip_id AND st2.stop_sequence = st1.stop_sequence + 1
          JOIN trips t ON t.trip_id = st1.trip_id
          WHERE st1.departure_time >= ?
          ORDER BY st1.departure_time ASC
          LIMIT 5000;
        ''', [secondsFromMidnight]);

        final List<TimetableConnection> connections = [];
        for (final row in connectionRows) {
          connections.add(TimetableConnection(
            tripId: row['trip_id'] as String,
            routeId: row['route_id'] as String,
            fromStopId: row['from_stop_id'] as String,
            toStopId: row['to_stop_id'] as String,
            departureTime: row['departure_time'] as int,
            arrivalTime: row['arrival_time'] as int,
            sequence: row['stop_sequence'] as int,
          ));
        }

        final csaResult = ConnectionScanAlgorithm.findEarliestArrival(
          originStopIds: originStops.map((s) => s.stopId).toList(),
          destinationStopIds: destStops.map((s) => s.stopId).toList(),
          departureTimeSec: secondsFromMidnight,
          sortedConnections: connections,
        );

        if (csaResult != null && csaResult.connections.isNotEmpty) {
          final firstConn = csaResult.connections.first;
          final lastConn = csaResult.connections.last;

          final firstStop = _stopsCache[firstConn.fromStopId]!;
          final lastStop = _stopsCache[lastConn.toStopId]!;

          // First leg: Walk from origin to first transit stop
          final walkToStationDist = Haversine.distanceMeters(origin, firstStop.coordinate);
          final walkToStationTime = (walkToStationDist / walkingSpeedMps).round();

          final transitDepartureEpoch = startTime + walkToStationTime;
          final transitArrivalEpoch = transitDepartureEpoch + csaResult.duration;

          // Last leg: Walk from last stop to destination
          final walkFromStationDist = Haversine.distanceMeters(lastStop.coordinate, destination);
          final walkFromStationTime = (walkFromStationDist / walkingSpeedMps).round();
          final finalArrivalEpoch = transitArrivalEpoch + walkFromStationTime;

          final List<RouteLegDto> legs = [];

          // Walk to station leg
          legs.add(RouteLegDto(
            legType: LegType.walking,
            fromStopName: 'Origin',
            toStopName: firstStop.stopName,
            fromCoordinate: origin,
            toCoordinate: firstStop.coordinate,
            departureEpochSeconds: startTime,
            arrivalEpochSeconds: transitDepartureEpoch,
            distanceMeters: walkToStationDist,
            waypoints: [origin, firstStop.coordinate],
            instruction: 'Walk to ${firstStop.stopName} (${walkToStationDist.round()}m)',
          ));

          // Transit legs
          for (final conn in csaResult.connections) {
            final fromS = _stopsCache[conn.fromStopId] ?? firstStop;
            final toS = _stopsCache[conn.toStopId] ?? lastStop;
            final route = _routesCache[conn.routeId];

            final legDist = Haversine.distanceMeters(fromS.coordinate, toS.coordinate);

            legs.add(RouteLegDto(
              legType: LegType.transit,
              routeId: conn.routeId,
              routeShortName: route?.routeShortName ?? conn.routeId,
              routeColor: route?.routeColor ?? '007AFF',
              fromStopName: fromS.stopName,
              toStopName: toS.stopName,
              fromCoordinate: fromS.coordinate,
              toCoordinate: toS.coordinate,
              departureEpochSeconds: transitDepartureEpoch + (conn.departureTime - firstConn.departureTime),
              arrivalEpochSeconds: transitDepartureEpoch + (conn.arrivalTime - firstConn.departureTime),
              distanceMeters: legDist,
              waypoints: [fromS.coordinate, toS.coordinate],
              instruction: 'Take ${route?.displayName ?? conn.routeId} to ${toS.stopName}',
            ));
          }

          // Walk from station leg
          legs.add(RouteLegDto(
            legType: LegType.walking,
            fromStopName: lastStop.stopName,
            toStopName: 'Destination',
            fromCoordinate: lastStop.coordinate,
            toCoordinate: destination,
            departureEpochSeconds: transitArrivalEpoch,
            arrivalEpochSeconds: finalArrivalEpoch,
            distanceMeters: walkFromStationDist,
            waypoints: [lastStop.coordinate, destination],
            instruction: 'Walk to destination (${walkFromStationDist.round()}m)',
          ));

          final totalDist = walkToStationDist +
              legs.where((l) => l.legType == LegType.transit).fold(0.0, (sum, l) => sum + l.distanceMeters) +
              walkFromStationDist;

          final transitItinerary = ItineraryDto(
            itineraryId: 'transit-${DateTime.now().millisecondsSinceEpoch}',
            departureEpochSeconds: startTime,
            arrivalEpochSeconds: finalArrivalEpoch,
            totalDistanceMeters: totalDist,
            transferCount: math.max(0, csaResult.connections.map((c) => c.tripId).toSet().length - 1),
            legs: legs,
          );

          itineraries.insert(0, transitItinerary);
        }
      }

      // Add direct walk as fallback if not already added
      if (itineraries.isEmpty) {
        itineraries.add(directWalkItinerary);
      }

      stopwatch.stop();
      return RoutingResultDto.success(
        itineraries: itineraries,
        computationTimeMs: stopwatch.elapsedMilliseconds,
      );
    } catch (e, stack) {
      stopwatch.stop();
      return RoutingResultDto.failure(
        'Routing error: $e',
        computationTimeMs: stopwatch.elapsedMilliseconds,
      );
    }
  }
}
