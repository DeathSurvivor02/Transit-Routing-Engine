import '../../core/geometry/coordinate.dart';

/// GTFS Stop or Platform entity.
class Stop {
  final String stopId;
  final String? stopCode;
  final String stopName;
  final Coordinate coordinate;
  final String? zoneId;
  final int locationType; // 0: Stop/Platform, 1: Station, 2: Entrance/Exit
  final String? parentStation;
  final int wheelchairBoarding;

  Stop({
    required this.stopId,
    this.stopCode,
    required this.stopName,
    required this.coordinate,
    this.zoneId,
    this.locationType = 0,
    this.parentStation,
    this.wheelchairBoarding = 0,
  });

  factory Stop.fromMap(Map<String, dynamic> map) {
    return Stop(
      stopId: map['stop_id'] as String,
      stopCode: map['stop_code'] as String?,
      stopName: map['stop_name'] as String,
      coordinate: Coordinate(
        (map['stop_lat'] as num).toDouble(),
        (map['stop_lon'] as num).toDouble(),
      ),
      zoneId: map['zone_id'] as String?,
      locationType: (map['location_type'] as int?) ?? 0,
      parentStation: map['parent_station'] as String?,
      wheelchairBoarding: (map['wheelchair_boarding'] as int?) ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'stop_id': stopId,
      'stop_code': stopCode,
      'stop_name': stopName,
      'stop_lat': coordinate.latitude,
      'stop_lon': coordinate.longitude,
      'zone_id': zoneId,
      'location_type': locationType,
      'parent_station': parentStation,
      'wheelchair_boarding': wheelchairBoarding,
    };
  }
}
