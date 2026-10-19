import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../lib/presentation/controllers/i_transit_map_controller.dart';

void main() {
  group('computeRouteBounds Tests', () {
    test('Calculates tight bounding box across waypoints', () {
      final points = [
        const LatLng(40.7128, -74.0060),
        const LatLng(40.7580, -73.9855),
        const LatLng(40.7829, -73.9654),
      ];

      final bounds = computeRouteBounds(points);

      expect(bounds.southwest.latitude, equals(40.7128));
      expect(bounds.southwest.longitude, equals(-74.0060));
      expect(bounds.northeast.latitude, equals(40.7829));
      expect(bounds.northeast.longitude, equals(-73.9654));
    });

    test('Handles single waypoint by setting southwest == northeast', () {
      final points = [const LatLng(40.7128, -74.0060)];
      final bounds = computeRouteBounds(points);

      expect(bounds.southwest.latitude, equals(40.7128));
      expect(bounds.northeast.latitude, equals(40.7128));
      expect(bounds.southwest.longitude, equals(-74.0060));
      expect(bounds.northeast.longitude, equals(-74.0060));
    });
  });
}
