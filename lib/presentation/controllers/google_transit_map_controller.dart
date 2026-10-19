import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'i_transit_map_controller.dart';

/// Concrete Google Maps implementation of ITransitMapController.
class GoogleTransitMapController implements ITransitMapController {
  GoogleMapController? _googleMapController;
  final Set<Polyline> polylines = {};
  final Set<Marker> markers = {};
  final VoidCallback? onStateChanged;

  // Cached descriptors
  BitmapDescriptor? _stationIcon;
  BitmapDescriptor? _transferIcon;

  GoogleTransitMapController({this.onStateChanged});

  void attachController(GoogleMapController controller) {
    _googleMapController = controller;
  }

  @override
  Future<void> initialize({required LatLng initialPosition, required double initialZoom}) async {
    _stationIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
    _transferIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
  }

  @override
  Future<void> updateCameraBounds(LatLngBounds bounds, {double padding = 50.0}) async {
    if (_googleMapController == null) return;
    await _googleMapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, padding),
    );
  }

  @override
  Future<void> renderRoutePolyline({
    required String routeId,
    required List<LatLng> waypoints,
    required Color color,
    bool isWalkSegment = false,
  }) async {
    final polyline = Polyline(
      polylineId: PolylineId(routeId),
      points: waypoints,
      color: color,
      width: isWalkSegment ? 4 : 6,
      patterns: isWalkSegment
          ? [PatternItem.dash(20), PatternItem.gap(10)]
          : const [],
      jointType: JointType.round,
      startCap: Cap.roundCap,
      endCap: Cap.roundCap,
    );

    polylines.add(polyline);
    onStateChanged?.call();
  }

  @override
  Future<void> setStationMarkers(List<StationMarkerDto> stations) async {
    markers.clear();
    for (final st in stations) {
      final marker = Marker(
        markerId: MarkerId(st.stationId),
        position: st.latLng,
        icon: _stationIcon ?? BitmapDescriptor.defaultMarker,
        infoWindow: InfoWindow(title: st.name),
        onTap: st.onTap,
      );
      markers.add(marker);
    }
    onStateChanged?.call();
  }

  @override
  Future<void> clearActiveRoute() async {
    polylines.clear();
    onStateChanged?.call();
  }

  @override
  void dispose() {
    _googleMapController?.dispose();
    _googleMapController = null;
    polylines.clear();
    markers.clear();
  }
}
