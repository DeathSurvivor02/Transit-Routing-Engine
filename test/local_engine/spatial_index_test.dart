import 'package:flutter_test/flutter_test.dart';
import '../../lib/core/geometry/coordinate.dart';
import '../../lib/core/geometry/haversine.dart';
import '../../lib/local_engine/models/stop.dart';
import '../../lib/local_engine/spatial/quadtree.dart';

void main() {
  group('Spatial Geometry & Index Tests', () {
    test('Coordinate: normalizes to 6 decimal places (~0.11m)', () {
      final coord = Coordinate(40.752712345, -73.977234567);
      expect(coord.latitude, equals(40.752712));
      expect(coord.longitude, equals(-73.977235));
    });

    test('Coordinate: throws ArgumentError on out-of-bounds coordinates', () {
      expect(() => Coordinate(91.0, 0.0), throwsArgumentError);
      expect(() => Coordinate(-91.0, 0.0), throwsArgumentError);
      expect(() => Coordinate(0.0, 181.0), throwsArgumentError);
      expect(() => Coordinate(0.0, -181.0), throwsArgumentError);
    });

    test('Haversine: computes known distance accurately', () {
      // Grand Central (40.7527, -73.9772) to Times Square (40.7580, -73.9855) ~ 915 meters
      final p1 = Coordinate(40.7527, -73.9772);
      final p2 = Coordinate(40.7580, -73.9855);

      final distance = Haversine.distanceMeters(p1, p2);
      expect(distance, greaterThan(850.0));
      expect(distance, lessThan(1000.0));
    });

    test('Quadtree: correctly inserts and queries spatial range', () {
      final tree = Quadtree(
        bounds: const GeoBounds(
          minLat: 40.0,
          maxLat: 41.0,
          minLon: -74.5,
          maxLon: -73.5,
        ),
        capacity: 4,
      );

      final stop1 = Stop(
        stopId: 'stop_1',
        stopName: 'Station One',
        coordinate: Coordinate(40.5, -74.0),
      );

      final stop2 = Stop(
        stopId: 'stop_2',
        stopName: 'Station Two',
        coordinate: Coordinate(40.8, -73.8),
      );

      final stopOut = Stop(
        stopId: 'stop_out',
        stopName: 'Station Out',
        coordinate: Coordinate(42.0, -74.0), // Outside root bounds
      );

      expect(tree.insert(stop1), isTrue);
      expect(tree.insert(stop2), isTrue);
      expect(tree.insert(stopOut), isFalse);

      final queryResults = tree.query(const GeoBounds(
        minLat: 40.4,
        maxLat: 40.6,
        minLon: -74.1,
        maxLon: -73.9,
      ));

      expect(queryResults.length, equals(1));
      expect(queryResults.first.stopId, equals('stop_1'));
    });
  });
}
