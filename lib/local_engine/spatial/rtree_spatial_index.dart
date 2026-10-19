import 'dart:math' as math;
import 'package:sqlite3/sqlite3.dart';
import '../../core/geometry/coordinate.dart';
import '../../core/geometry/haversine.dart';
import '../models/stop.dart';

/// Interacts with SQLite R*Tree virtual table for geospatial queries.
class RtreeSpatialIndex {
  final Database _db;

  RtreeSpatialIndex(this._db);

  /// Queries all stops within [radiusMeters] of a center coordinate.
  List<Stop> findNearbyStops({
    required Coordinate center,
    required double radiusMeters,
    int limit = 50,
  }) {
    // 1 degree latitude ~ 111,000 meters
    final double deltaLat = radiusMeters / 111000.0;
    // 1 degree longitude ~ 111,000 * cos(lat) meters
    final double cosLat = math.cos(center.latitude * math.pi / 180.0).abs();
    final double deltaLon = radiusMeters / (111000.0 * math.max(0.1, cosLat));

    final minLat = center.latitude - deltaLat;
    final maxLat = center.latitude + deltaLat;
    final minLon = center.longitude - deltaLon;
    final maxLon = center.longitude + deltaLon;

    // Check if R*Tree table exists
    final rtreeCheck = _db.select(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='stops_spatial_idx';",
    );

    ResultSet rows;
    if (rtreeCheck.isNotEmpty) {
      // Query R*Tree
      final sql = '''
        SELECT s.stop_id, s.stop_code, s.stop_name, s.stop_lat, s.stop_lon,
               s.zone_id, s.location_type, s.parent_station, s.wheelchair_boarding
        FROM stops_spatial_idx r
        JOIN stops s ON s.rowid = r.id
        WHERE r.min_lat <= ? AND r.max_lat >= ?
          AND r.min_lon <= ? AND r.max_lon >= ?
        LIMIT ?;
      ''';
      rows = _db.select(sql, [maxLat, minLat, maxLon, minLon, limit * 2]);
    } else {
      // Fallback bounding box query on standard stops table
      final sql = '''
        SELECT stop_id, stop_code, stop_name, stop_lat, stop_lon,
               zone_id, location_type, parent_station, wheelchair_boarding
        FROM stops
        WHERE stop_lat BETWEEN ? AND ?
          AND stop_lon BETWEEN ? AND ?
        LIMIT ?;
      ''';
      rows = _db.select(sql, [minLat, maxLat, minLon, maxLon, limit * 2]);
    }

    final List<Stop> candidates = [];
    for (final row in rows) {
      final stop = Stop.fromMap(row);
      final dist = Haversine.distanceMeters(center, stop.coordinate);
      if (dist <= radiusMeters) {
        candidates.add(stop);
      }
    }

    // Sort by geodesic proximity
    candidates.sort((a, b) {
      final dA = Haversine.distanceMeters(center, a.coordinate);
      final dB = Haversine.distanceMeters(center, b.coordinate);
      return dA.compareTo(dB);
    });

    if (candidates.length > limit) {
      return candidates.sublist(0, limit);
    }
    return candidates;
  }
}
