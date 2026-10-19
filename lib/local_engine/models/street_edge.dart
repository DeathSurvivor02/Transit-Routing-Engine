/// Road network graph edge representing a walkable street or transit link.
class StreetEdge {
  final int? edgeId;
  final int sourceNode;
  final int targetNode;
  final double lengthMeters;
  final double baseSpeedMps;
  final String? associatedSignalId;
  final double? approachDirectionDegrees;

  StreetEdge({
    this.edgeId,
    required this.sourceNode,
    required this.targetNode,
    required this.lengthMeters,
    required this.baseSpeedMps,
    this.associatedSignalId,
    this.approachDirectionDegrees,
  });

  double get freeFlowTravelTimeSec => lengthMeters / baseSpeedMps;

  factory StreetEdge.fromMap(Map<String, dynamic> map) {
    return StreetEdge(
      edgeId: map['edge_id'] as int?,
      sourceNode: map['source_node'] as int,
      targetNode: map['target_node'] as int,
      lengthMeters: (map['length_meters'] as num).toDouble(),
      baseSpeedMps: (map['base_speed_mps'] as num).toDouble(),
      associatedSignalId: map['associated_signal_id'] as String?,
      approachDirectionDegrees: (map['approach_direction_degrees'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'edge_id': edgeId,
      'source_node': sourceNode,
      'target_node': targetNode,
      'length_meters': lengthMeters,
      'base_speed_mps': baseSpeedMps,
      'associated_signal_id': associatedSignalId,
      'approach_direction_degrees': approachDirectionDegrees,
    };
  }
}
