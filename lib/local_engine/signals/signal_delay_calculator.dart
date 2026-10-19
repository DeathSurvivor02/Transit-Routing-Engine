import '../models/signal_timing_plan.dart';
import '../models/street_edge.dart';
import 'webster_delay_model.dart';

/// Evaluates dynamic traversal edge weights accounting for signal delays.
class SignalDelayCalculator {
  /// Calculates the dynamic traversal cost (in seconds) for a street edge at a specific arrival time.
  static double calculateDynamicEdgeWeight({
    required StreetEdge edge,
    required double arrivalTimeSeconds,
    SignalTimingPlan? plan,
    bool includeWebsterQueueing = false,
  }) {
    final double baseTravelTime = edge.freeFlowTravelTimeSec;
    if (edge.associatedSignalId == null || plan == null) {
      return baseTravelTime;
    }

    final double deterministicWait = WebsterDelayModel.calculateDeterministicWait(
      arrivalTimeSeconds: arrivalTimeSeconds,
      cycleLengthSec: plan.cycleLengthSec,
      greenSplitRatio: plan.greenSplitRatio,
      phaseOffsetSec: plan.phaseOffsetSec,
    );

    double additionalQueueDelay = 0.0;
    if (includeWebsterQueueing) {
      // Optional queue residual delay
      final websterTotal = WebsterDelayModel.calculateWebsterDelay(
        cycleLengthSec: plan.cycleLengthSec,
        greenSplitRatio: plan.greenSplitRatio,
      );
      additionalQueueDelay = (websterTotal * 0.15).clamp(0.0, 15.0);
    }

    return baseTravelTime + deterministicWait + additionalQueueDelay;
  }
}
