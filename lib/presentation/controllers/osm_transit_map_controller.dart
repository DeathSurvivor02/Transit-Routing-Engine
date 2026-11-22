import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as osm;

/// Represents a station/stop marker for OpenStreetMap.
class OsmMarkerDto {
  final String id;
  final String title;
  final osm.LatLng point;
  final IconData icon;
  final Color color;

  const OsmMarkerDto({
    required this.id,
    required this.title,
    required this.point,
    this.icon = Icons.location_on,
    this.color = Colors.red,
  });
}

/// Controller managing OpenStreetMap polylines, markers, and camera animations.
class OsmTransitMapController {
  final MapController mapController = MapController();
  final List<Polyline> polylines = [];
  final List<Marker> markers = [];
  final VoidCallback? onStateChanged;

  OsmTransitMapController({this.onStateChanged});

  void clearActiveRoute() {
    polylines.clear();
    markers.clear();
    onStateChanged?.call();
  }

  void renderRoutePolyline({
    required String routeId,
    required List<osm.LatLng> waypoints,
    required Color color,
    bool isWalkSegment = false,
  }) {
    if (waypoints.isEmpty) return;

    final polyline = Polyline(
      points: waypoints,
      color: color,
      strokeWidth: isWalkSegment ? 4.0 : 6.0,
      pattern: isWalkSegment
          ? StrokePattern.dashed(segments: const [12, 8])
          : const StrokePattern.solid(),
    );

    polylines.add(polyline);
    onStateChanged?.call();
  }

  void addMarker({
    required osm.LatLng point,
    required String label,
    required IconData icon,
    required Color color,
    double size = 36.0,
  }) {
    final marker = Marker(
      point: point,
      width: size + 10,
      height: size + 10,
      child: Tooltip(
        message: label,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
            ],
            border: Border.all(color: color, width: 2.5),
          ),
          padding: const EdgeInsets.all(4.0),
          child: Icon(icon, color: color, size: size * 0.6),
        ),
      ),
    );

    markers.add(marker);
    onStateChanged?.call();
  }

  void fitBounds(List<osm.LatLng> points, {double padding = 70.0}) {
    if (points.isEmpty) return;
    if (points.length == 1) {
      mapController.move(points.first, 15.0);
      return;
    }

    final bounds = LatLngBounds.fromPoints(points);
    mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: EdgeInsets.all(padding),
      ),
    );
  }

  void recenter(osm.LatLng center, {double zoom = 14.5}) {
    mapController.move(center, zoom);
  }

  void dispose() {
    mapController.dispose();
  }
}
