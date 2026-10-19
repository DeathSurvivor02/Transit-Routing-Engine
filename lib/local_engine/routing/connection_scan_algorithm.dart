import 'graph_node.dart';

/// Result of a Connection Scan Algorithm execution.
class CsaJourney {
  final List<TimetableConnection> connections;
  final int departureTime;
  final int arrivalTime;

  CsaJourney({
    required this.connections,
    required this.departureTime,
    required this.arrivalTime,
  });

  int get duration => arrivalTime - departureTime;
}

/// Implementation of the Connection Scan Algorithm (CSA) for offline transit timetable queries.
class ConnectionScanAlgorithm {
  static const int infinity = 1000000000;

  /// Finds the earliest arrival transit route from [originStopIds] to [destinationStopIds]
  /// starting at or after [departureTimeSec].
  static CsaJourney? findEarliestArrival({
    required List<String> originStopIds,
    required List<String> destinationStopIds,
    required int departureTimeSec,
    required List<TimetableConnection> sortedConnections,
    Map<String, Map<String, int>>? transferFootpaths, // fromStop -> toStop -> walkSec
  }) {
    if (originStopIds.isEmpty || destinationStopIds.isEmpty) return null;

    final destSet = destinationStopIds.toSet();
    final Map<String, int> earliestArrival = {};
    final Map<String, bool> tripReached = {};
    final Map<String, TimetableConnection?> inConnection = {};

    // Initialize origin stops with the starting time
    for (final orig in originStopIds) {
      earliestArrival[orig] = departureTimeSec;
      // Also apply initial footpaths if any
      if (transferFootpaths != null && transferFootpaths.containsKey(orig)) {
        for (final entry in transferFootpaths[orig]!.entries) {
          final target = entry.key;
          final walkTime = entry.value;
          earliestArrival[target] = departureTimeSec + walkTime;
        }
      }
    }

    int bestDestArrival = infinity;
    String? bestDestStop;

    for (final conn in sortedConnections) {
      if (conn.departureTime < departureTimeSec) {
        continue;
      }

      // Early cutoff if connection departs after we already reached destination
      if (conn.departureTime >= bestDestArrival) {
        break;
      }

      final canBoard = tripReached[conn.tripId] == true ||
          (earliestArrival.containsKey(conn.fromStopId) &&
              earliestArrival[conn.fromStopId]! <= conn.departureTime);

      if (canBoard) {
        tripReached[conn.tripId] = true;

        final currentToArrival = earliestArrival[conn.toStopId] ?? infinity;
        if (conn.arrivalTime < currentToArrival) {
          earliestArrival[conn.toStopId] = conn.arrivalTime;
          inConnection[conn.toStopId] = conn;

          if (destSet.contains(conn.toStopId) && conn.arrivalTime < bestDestArrival) {
            bestDestArrival = conn.arrivalTime;
            bestDestStop = conn.toStopId;
          }

          // Apply transfer footpaths from toStopId
          if (transferFootpaths != null && transferFootpaths.containsKey(conn.toStopId)) {
            for (final entry in transferFootpaths[conn.toStopId]!.entries) {
              final targetStop = entry.key;
              final walkSec = entry.value;
              final walkArrival = conn.arrivalTime + walkSec;
              if (walkArrival < (earliestArrival[targetStop] ?? infinity)) {
                earliestArrival[targetStop] = walkArrival;
                if (destSet.contains(targetStop) && walkArrival < bestDestArrival) {
                  bestDestArrival = walkArrival;
                  bestDestStop = targetStop;
                }
              }
            }
          }
        }
      }
    }

    if (bestDestStop == null || bestDestArrival >= infinity) {
      return null;
    }

    // Reconstruct connection path
    final List<TimetableConnection> journey = [];
    String? currStop = bestDestStop;

    while (currStop != null && inConnection.containsKey(currStop)) {
      final conn = inConnection[currStop];
      if (conn == null) break;
      journey.insert(0, conn);
      currStop = conn.fromStopId;
      if (originStopIds.contains(currStop)) {
        break;
      }
    }

    if (journey.isEmpty) return null;

    return CsaJourney(
      connections: journey,
      departureTime: journey.first.departureTime,
      arrivalTime: journey.last.arrivalTime,
    );
  }
}
