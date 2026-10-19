import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/geometry/coordinate.dart';

/// DTO for station markers displayed on the map viewport.
class StationMarkerDto {
  final String stationId;
  final String name;
  final Coordinate coordinate;
  final String? agencyColorHex;
  final VoidCallback? onTap;

  StationMarkerDto({
    required this.stationId,
    required this.name,
    required this.coordinate,
    this.agencyColorHex,
    this.onTap,
  });

  LatLng get latLng => LatLng(coordinate.latitude, coordinate.longitude);
}

/// Computes the minimal bounding box enclosing a list of waypoints.
LatLngBounds computeRouteBounds(List<LatLng> points) {
  if (points.isEmpty) {
    return LatLngBounds(
      southwest: const LatLng(0, 0),
      northeast: const LatLng(0, 0),
    );
  }
  double minLat = points.first.latitude, maxLat = points.first.latitude;
  double minLng = points.first.longitude, maxLng = points.first.longitude;
  for (final p in points) {
    if (p.latitude < minLat) minLat = p.latitude;
    if (p.latitude > maxLat) maxLat = p.latitude;
    if (p.longitude < minLng) minLng = p.longitude;
    if (p.longitude > maxLng) maxLng = p.longitude;
  }
  return LatLngBounds(
    southwest: LatLng(minLat, minLng),
    northeast: LatLng(maxLat, maxLng),
  );
}

/// Decoupled interface for interactive transit map viewports.
abstract class ITransitMapController {
  Future<void> initialize({required LatLng initialPosition, required double initialZoom});
  Future<void> updateCameraBounds(LatLngBounds bounds, {double padding = 50.0});
  Future<void> renderRoutePolyline({
    required String routeId,
    required List<LatLng> waypoints,
    required Color color,
    bool isWalkSegment = false,
  });
  Future<void> setStationMarkers(List<StationMarkerDto> stations);
  Future<void> clearActiveRoute();
  void dispose();
}
