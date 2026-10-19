import '../../core/geometry/coordinate.dart';

/// Represents a multimodal graph vertex.
class GraphNode {
  final int id;
  final String label;
  final Coordinate coordinate;
  final bool isTransitStop;
  final String? stopId;

  GraphNode({
    required this.id,
    required this.label,
    required this.coordinate,
    this.isTransitStop = false,
    this.stopId,
  });
}

/// An elementary transit connection for the Connection Scan Algorithm (CSA).
class TimetableConnection {
  final String tripId;
  final String routeId;
  final String fromStopId;
  final String toStopId;
  final int departureTime; // Seconds from midnight
  final int arrivalTime; // Seconds from midnight
  final int sequence;

  TimetableConnection({
    required this.tripId,
    required this.routeId,
    required this.fromStopId,
    required this.toStopId,
    required this.departureTime,
    required this.arrivalTime,
    required this.sequence,
  });
}
