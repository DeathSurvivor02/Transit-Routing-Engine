import '../../core/geometry/coordinate.dart';

/// Traffic signal intersection entity.
class TrafficSignal {
  final String signalId;
  final Coordinate coordinate;
  final int cycleLengthSec;
  final String? coordinationGroup;

  TrafficSignal({
    required this.signalId,
    required this.coordinate,
    required this.cycleLengthSec,
    this.coordinationGroup,
  });

  factory TrafficSignal.fromMap(Map<String, dynamic> map) {
    return TrafficSignal(
      signalId: map['signal_id'] as String,
      coordinate: Coordinate(
        (map['intersection_lat'] as num).toDouble(),
        (map['intersection_lon'] as num).toDouble(),
      ),
      cycleLengthSec: map['cycle_length_sec'] as int,
      coordinationGroup: map['coordination_group'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'signal_id': signalId,
      'intersection_lat': coordinate.latitude,
      'intersection_lon': coordinate.longitude,
      'cycle_length_sec': cycleLengthSec,
      'coordination_group': coordinationGroup,
    };
  }
}
