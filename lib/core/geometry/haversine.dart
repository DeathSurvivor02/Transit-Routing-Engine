import 'dart:math' as math;
import 'coordinate.dart';

/// Haversine calculation utility for spherical distance evaluation.
class Haversine {
  /// Mean Earth radius in meters (WGS 84 spherical approximation)
  static const double earthRadiusMeters = 6371000.0;

  /// Calculates geodesic distance between two coordinates in meters.
  static double distanceMeters(Coordinate p1, Coordinate p2) {
    final double phi1 = _degToRad(p1.latitude);
    final double phi2 = _degToRad(p2.latitude);
    final double deltaPhi = _degToRad(p2.latitude - p1.latitude);
    final double deltaLambda = _degToRad(p2.longitude - p1.longitude);

    final double sinDeltaPhiHalf = math.sin(deltaPhi / 2.0);
    final double sinDeltaLambdaHalf = math.sin(deltaLambda / 2.0);

    final double a = (sinDeltaPhiHalf * sinDeltaPhiHalf) +
        (math.cos(phi1) * math.cos(phi2) * (sinDeltaLambdaHalf * sinDeltaLambdaHalf));

    final double c = 2.0 * math.asin(math.sqrt(math.min(1.0, math.max(0.0, a))));

    return earthRadiusMeters * c;
  }

  static double _degToRad(double degrees) {
    return degrees * (math.pi / 180.0);
  }
}
