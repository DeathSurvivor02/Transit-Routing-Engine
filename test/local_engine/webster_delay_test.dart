import 'package:flutter_test/flutter_test.dart';
import '../../lib/local_engine/signals/webster_delay_model.dart';

void main() {
  group('WebsterDelayModel Tests', () {
    test('Deterministic wait: zero delay during green phase', () {
      // 90s cycle, 50% green split (green window: [0, 45s))
      // Arrival at 20.0s -> inside green -> 0s wait
      final wait = WebsterDelayModel.calculateDeterministicWait(
        arrivalTimeSeconds: 20.0,
        cycleLengthSec: 90,
        greenSplitRatio: 0.5,
        phaseOffsetSec: 0,
      );

      expect(wait, equals(0.0));
    });

    test('Deterministic wait: positive delay during red phase', () {
      // 90s cycle, 50% green split (red window: [45s, 90s))
      // Arrival at 50.0s -> wait until 90s -> 40s wait
      final wait = WebsterDelayModel.calculateDeterministicWait(
        arrivalTimeSeconds: 50.0,
        cycleLengthSec: 90,
        greenSplitRatio: 0.5,
        phaseOffsetSec: 0,
      );

      expect(wait, closeTo(40.0, 0.001));
    });

    test('Deterministic wait: phase offset shifts cycle properly', () {
      // 90s cycle, 50% green split, offset = 10s
      // Effective green: [10s, 55s), red: [55s, 100s)
      // Arrival at 5s -> (5 - 10) mod 90 = 85 -> red phase -> wait = 90 - 85 = 5s
      final wait = WebsterDelayModel.calculateDeterministicWait(
        arrivalTimeSeconds: 5.0,
        cycleLengthSec: 90,
        greenSplitRatio: 0.5,
        phaseOffsetSec: 10,
      );

      expect(wait, closeTo(5.0, 0.001));
    });

    test('Webster formula: calculates realistic delay values', () {
      final delay = WebsterDelayModel.calculateWebsterDelay(
        cycleLengthSec: 90,
        greenSplitRatio: 0.5,
        degreeOfSaturation: 0.6,
        arrivalRateVehPerSec: 0.2,
      );

      // Delay should be positive and bounded
      expect(delay, greaterThan(0.0));
      expect(delay, lessThan(90.0));
    });

    test('Webster formula: handles zero or negative cycle lengths safely', () {
      final delay = WebsterDelayModel.calculateWebsterDelay(
        cycleLengthSec: 0,
        greenSplitRatio: 0.5,
      );

      expect(delay, equals(0.0));
    });
  });
}
