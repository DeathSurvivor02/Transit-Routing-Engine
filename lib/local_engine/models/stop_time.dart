/// GTFS Stop Time entity representing a scheduled vehicle stop.
class StopTime {
  final String tripId;
  final int arrivalTime; // Seconds from midnight
  final int departureTime; // Seconds from midnight
  final String stopId;
  final int stopSequence;

  StopTime({
    required this.tripId,
    required this.arrivalTime,
    required this.departureTime,
    required this.stopId,
    required this.stopSequence,
  });

  factory StopTime.fromMap(Map<String, dynamic> map) {
    return StopTime(
      tripId: map['trip_id'] as String,
      arrivalTime: map['arrival_time'] as int,
      departureTime: map['departure_time'] as int,
      stopId: map['stop_id'] as String,
      stopSequence: map['stop_sequence'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'trip_id': tripId,
      'arrival_time': arrivalTime,
      'departure_time': departureTime,
      'stop_id': stopId,
      'stop_sequence': stopSequence,
    };
  }
}
