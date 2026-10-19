import 'dart:math' as math;

/// Implementation of Webster's traffic signal delay model and cycle phase alignment.
class WebsterDelayModel {
  /// Computes deterministic uniform signal wait time (seconds) based on cyclic arrival.
  ///
  /// - [arrivalTimeSeconds]: Timestamp of arrival at the intersection (epoch seconds or seconds from midnight).
  /// - [cycleLengthSec]: Total cycle duration in seconds (e.g. 90, 120).
  /// - [greenSplitRatio]: Ratio of effective green time to cycle length (0.0 to 1.0).
  /// - [phaseOffsetSec]: Coordination phase offset in seconds.
  static double calculateDeterministicWait({
    required double arrivalTimeSeconds,
    required int cycleLengthSec,
    required double greenSplitRatio,
    int phaseOffsetSec = 0,
  }) {
    if (cycleLengthSec <= 0) return 0.0;
    final double greenRatio = greenSplitRatio.clamp(0.01, 0.99);
    final double cycle = cycleLengthSec.toDouble();
    final double effectiveGreenTime = cycle * greenRatio;

    // Cycle Phase Alignment: tau(t) = (t - phase_offset) mod C
    double cyclePosition = (arrivalTimeSeconds - phaseOffsetSec) % cycle;
    if (cyclePosition < 0) {
      cyclePosition += cycle;
    }

    if (cyclePosition >= effectiveGreenTime) {
      // Arrived during red phase: wait until green starts
      return cycle - cyclePosition;
    } else {
      // Arrived during green window: zero uniform wait
      return 0.0;
    }
  }

  /// Calculates Webster's modified delay formulation accounting for queuing & traffic friction:
  ///
  /// d = [C * (1 - g/C)^2] / [2 * (1 - min(1, x) * g/C)] + [x^2 / (2 * q * (1 - x))]
  ///
  /// - [cycleLengthSec] (C): Cycle length in seconds
  /// - [greenSplitRatio] (g/C): Green-to-cycle ratio
  /// - [degreeOfSaturation] (x): v/c ratio (clamped to prevent singularity at 1.0)
  /// - [arrivalRateVehPerSec] (q): Traffic arrival rate in vehicles/sec
  static double calculateWebsterDelay({
    required int cycleLengthSec,
    required double greenSplitRatio,
    double degreeOfSaturation = 0.5,
    double arrivalRateVehPerSec = 0.25,
  }) {
    if (cycleLengthSec <= 0) return 0.0;

    final double c = cycleLengthSec.toDouble();
    final double gOverC = greenSplitRatio.clamp(0.01, 0.99);
    // Clamp degree of saturation to avoid division by zero or infinite queues in static model
    final double x = degreeOfSaturation.clamp(0.0, 0.95);
    final double q = math.max(1e-4, arrivalRateVehPerSec);

    // Uniform component: [C * (1 - g/C)^2] / [2 * (1 - min(1, x) * g/C)]
    final double numerator1 = c * math.pow(1.0 - gOverC, 2);
    final double denominator1 = 2.0 * (1.0 - math.min(1.0, x) * gOverC);
    final double d1 = numerator1 / denominator1;

    // Random queuing component: [x^2] / [2 * q * (1 - x)]
    final double numerator2 = x * x;
    final double denominator2 = 2.0 * q * (1.0 - x);
    final double d2 = numerator2 / denominator2;

    return d1 + d2;
  }
}
