/// Signal timing plan defining cycle parameters for time intervals.
class SignalTimingPlan {
  final int? planId;
  final String signalId;
  final String dayType; // 'WEEKDAY', 'SATURDAY', 'SUNDAY'
  final int startHour; // 0-23
  final int endHour; // 0-23
  final double greenSplitRatio; // Effective green / cycle length (0.0 to 1.0)
  final int phaseOffsetSec;
  final int cycleLengthSec;

  SignalTimingPlan({
    this.planId,
    required this.signalId,
    required this.dayType,
    required this.startHour,
    required this.endHour,
    required this.greenSplitRatio,
    this.phaseOffsetSec = 0,
    required this.cycleLengthSec,
  });

  factory SignalTimingPlan.fromMap(Map<String, dynamic> map, {int defaultCycle = 90}) {
    return SignalTimingPlan(
      planId: map['plan_id'] as int?,
      signalId: map['signal_id'] as String,
      dayType: map['day_type'] as String,
      startHour: map['start_hour'] as int,
      endHour: map['end_hour'] as int,
      greenSplitRatio: (map['green_split_ratio'] as num).toDouble(),
      phaseOffsetSec: (map['phase_offset_sec'] as int?) ?? 0,
      cycleLengthSec: (map['cycle_length_sec'] as int?) ?? defaultCycle,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'plan_id': planId,
      'signal_id': signalId,
      'day_type': dayType,
      'start_hour': startHour,
      'end_hour': endHour,
      'green_split_ratio': greenSplitRatio,
      'phase_offset_sec': phaseOffsetSec,
    };
  }
}
