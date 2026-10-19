import 'dart:collection';
import '../../core/geometry/coordinate.dart';
import '../../core/geometry/haversine.dart';
import '../models/signal_timing_plan.dart';
import '../models/street_edge.dart';
import '../signals/signal_delay_calculator.dart';
import 'graph_node.dart';

class AStarPathResult {
  final List<GraphNode> nodes;
  final List<StreetEdge> edges;
  final double totalTimeSeconds;
  final double totalDistanceMeters;
  final double totalSignalDelaySeconds;

  AStarPathResult({
    required this.nodes,
    required this.edges,
    required this.totalTimeSeconds,
    required this.totalDistanceMeters,
    required this.totalSignalDelaySeconds,
  });
}

class _AStarNode implements Comparable<_AStarNode> {
  final int nodeId;
  final double gCost; // Actual time from start in seconds
  final double fCost; // gCost + heuristic
  final double signalDelay;

  _AStarNode({
    required this.nodeId,
    required this.gCost,
    required this.fCost,
    required this.signalDelay,
  });

  @override
  int compareTo(_AStarNode other) => fCost.compareTo(other.fCost);
}

/// Time-Dependent A* algorithm evaluating dynamic signal delays along street edges.
class TimeDependentAStar {
  /// Executes Time-Dependent A* search from [startNodeId] to [targetNodeId].
  static AStarPathResult? findShortestPath({
    required int startNodeId,
    required int targetNodeId,
    required double startTimeEpochSeconds,
    required Map<int, GraphNode> nodes,
    required Map<int, List<StreetEdge>> adjacencyList,
    required Map<String, SignalTimingPlan> signalPlans,
  }) {
    if (!nodes.containsKey(startNodeId) || !nodes.containsKey(targetNodeId)) {
      return null;
    }

    final targetNode = nodes[targetNodeId]!;
    final Map<int, double> gCosts = {startNodeId: 0.0};
    final Map<int, double> accumulatedSignalDelays = {startNodeId: 0.0};
    final Map<int, StreetEdge> cameFromEdge = {};
    final Map<int, int> cameFromNode = {};

    // Simple priority list/queue
    final List<_AStarNode> openSet = [];

    double heuristic(Coordinate coord) {
      final dist = Haversine.distanceMeters(coord, targetNode.coordinate);
      // Underestimate time with max walking/running speed 2.0 m/s
      return dist / 2.0;
    }

    openSet.add(_AStarNode(
      nodeId: startNodeId,
      gCost: 0.0,
      fCost: heuristic(nodes[startNodeId]!.coordinate),
      signalDelay: 0.0,
    ));

    final Set<int> closedSet = {};

    while (openSet.isNotEmpty) {
      // Pop lowest fCost
      openSet.sort();
      final current = openSet.removeAt(0);

      if (current.nodeId == targetNodeId) {
        // Reconstruct path
        final List<GraphNode> pathNodes = [];
        final List<StreetEdge> pathEdges = [];
        int currId = targetNodeId;
        double totalDist = 0.0;

        while (currId != startNodeId) {
          pathNodes.insert(0, nodes[currId]!);
          final edge = cameFromEdge[currId]!;
          pathEdges.insert(0, edge);
          totalDist += edge.lengthMeters;
          currId = cameFromNode[currId]!;
        }
        pathNodes.insert(0, nodes[startNodeId]!);

        return AStarPathResult(
          nodes: pathNodes,
          edges: pathEdges,
          totalTimeSeconds: current.gCost,
          totalDistanceMeters: totalDist,
          totalSignalDelaySeconds: current.signalDelay,
        );
      }

      closedSet.add(current.nodeId);

      final edges = adjacencyList[current.nodeId] ?? const [];
      for (final edge in edges) {
        final neighborId = edge.targetNode;
        if (closedSet.contains(neighborId)) continue;

        final currentArrival = startTimeEpochSeconds + current.gCost;
        SignalTimingPlan? plan;
        if (edge.associatedSignalId != null) {
          plan = signalPlans[edge.associatedSignalId];
        }

        // Calculate dynamic edge weight with Webster & uniform delays
        final edgeCost = SignalDelayCalculator.calculateDynamicEdgeWeight(
          edge: edge,
          arrivalTimeSeconds: currentArrival,
          plan: plan,
          includeWebsterQueueing: true,
        );

        final edgeSignalWait = edgeCost - edge.freeFlowTravelTimeSec;
        final tentativeGCost = current.gCost + edgeCost;
        final existingGCost = gCosts[neighborId] ?? double.infinity;

        if (tentativeGCost < existingGCost) {
          gCosts[neighborId] = tentativeGCost;
          accumulatedSignalDelays[neighborId] = current.signalDelay + edgeSignalWait;
          cameFromEdge[neighborId] = edge;
          cameFromNode[neighborId] = current.nodeId;

          final neighborNode = nodes[neighborId];
          final fCost = tentativeGCost + (neighborNode != null ? heuristic(neighborNode.coordinate) : 0.0);

          openSet.add(_AStarNode(
            nodeId: neighborId,
            gCost: tentativeGCost,
            fCost: fCost,
            signalDelay: accumulatedSignalDelays[neighborId]!,
          ));
        }
      }
    }

    return null;
  }
}
