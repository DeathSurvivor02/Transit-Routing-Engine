import 'dart:math' as math;

/// Represents a WGS 84 (EPSG:4326) geographical coordinate.
class Coordinate {
  final double latitude;
  final double longitude;

  Coordinate(double latitude, double longitude)
      : latitude = _normalizePrecision(_validateLatitude(latitude)),
        longitude = _normalizePrecision(_validateLongitude(longitude));

  static double _validateLatitude(double lat) {
    if (lat < -90.0 || lat > 90.0) {
      throw ArgumentError.value(lat, 'latitude', 'Latitude must be between -90.0 and 90.0');
    }
    return lat;
  }

  static double _validateLongitude(double lon) {
    if (lon < -180.0 || lon > 180.0) {
      throw ArgumentError.value(lon, 'longitude', 'Longitude must be between -180.0 and 180.0');
    }
    return lon;
  }

  /// Normalizes to 6 decimal places (~0.11m precision).
  static double _normalizePrecision(double val) {
    return double.parse(val.toStringAsFixed(6));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Coordinate &&
          runtimeType == other.runtimeType &&
          (latitude - other.latitude).abs() < 1e-6 &&
          (longitude - other.longitude).abs() < 1e-6;

  @override
  int get hashCode => Object.hash(
        (latitude * 1e6).round(),
        (longitude * 1e6).round(),
      );

  @override
  String toString() => 'Coordinate($latitude, $longitude)';

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
      };

  factory Coordinate.fromJson(Map<String, dynamic> json) => Coordinate(
        (json['latitude'] as num).toDouble(),
        (json['longitude'] as num).toDouble(),
      );
}
