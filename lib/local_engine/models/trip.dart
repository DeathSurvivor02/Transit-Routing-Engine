/// GTFS Trip entity.
class Trip {
  final String tripId;
  final String routeId;
  final String serviceId;
  final String? tripHeadsign;
  final int? directionId;

  Trip({
    required this.tripId,
    required this.routeId,
    required this.serviceId,
    this.tripHeadsign,
    this.directionId,
  });

  factory Trip.fromMap(Map<String, dynamic> map) {
    return Trip(
      tripId: map['trip_id'] as String,
      routeId: map['route_id'] as String,
      serviceId: map['service_id'] as String,
      tripHeadsign: map['trip_headsign'] as String?,
      directionId: map['direction_id'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'trip_id': tripId,
      'route_id': routeId,
      'service_id': serviceId,
      'trip_headsign': tripHeadsign,
      'direction_id': directionId,
    };
  }
}
