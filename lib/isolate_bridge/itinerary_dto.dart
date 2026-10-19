import '../../core/geometry/coordinate.dart';

enum LegType { walking, transit, transfer }

/// A single leg within a planned multimodal itinerary.
class RouteLegDto {
  final LegType legType;
  final String? routeId;
  final String? routeShortName;
  final String? routeColor; // Hex string
  final String fromStopName;
  final String toStopName;
  final Coordinate fromCoordinate;
  final Coordinate toCoordinate;
  final int departureEpochSeconds;
  final int arrivalEpochSeconds;
  final double distanceMeters;
  final List<Coordinate> waypoints;
  final String instruction;
  final double signalDelaySeconds;

  RouteLegDto({
    required this.legType,
    this.routeId,
    this.routeShortName,
    this.routeColor,
    required this.fromStopName,
    required this.toStopName,
    required this.fromCoordinate,
    required this.toCoordinate,
    required this.departureEpochSeconds,
    required this.arrivalEpochSeconds,
    required this.distanceMeters,
    required this.waypoints,
    required this.instruction,
    this.signalDelaySeconds = 0.0,
  });

  int get durationSeconds => arrivalEpochSeconds - departureEpochSeconds;

  Map<String, dynamic> toJson() => {
        'legType': legType.name,
        'routeId': routeId,
        'routeShortName': routeShortName,
        'routeColor': routeColor,
        'fromStopName': fromStopName,
        'toStopName': toStopName,
        'fromCoordinate': fromCoordinate.toJson(),
        'toCoordinate': toCoordinate.toJson(),
        'departureEpochSeconds': departureEpochSeconds,
        'arrivalEpochSeconds': arrivalEpochSeconds,
        'distanceMeters': distanceMeters,
        'waypoints': waypoints.map((w) => w.toJson()).toList(),
        'instruction': instruction,
        'signalDelaySeconds': signalDelaySeconds,
      };

  factory RouteLegDto.fromJson(Map<String, dynamic> json) => RouteLegDto(
        legType: LegType.values.byName(json['legType'] as String),
        routeId: json['routeId'] as String?,
        routeShortName: json['routeShortName'] as String?,
        routeColor: json['routeColor'] as String?,
        fromStopName: json['fromStopName'] as String,
        toStopName: json['toStopName'] as String,
        fromCoordinate: Coordinate.fromJson(json['fromCoordinate'] as Map<String, dynamic>),
        toCoordinate: Coordinate.fromJson(json['toCoordinate'] as Map<String, dynamic>),
        departureEpochSeconds: json['departureEpochSeconds'] as int,
        arrivalEpochSeconds: json['arrivalEpochSeconds'] as int,
        distanceMeters: (json['distanceMeters'] as num).toDouble(),
        waypoints: (json['waypoints'] as List<dynamic>)
            .map((w) => Coordinate.fromJson(w as Map<String, dynamic>))
            .toList(),
        instruction: json['instruction'] as String,
        signalDelaySeconds: (json['signalDelaySeconds'] as num?)?.toDouble() ?? 0.0,
      );
}

/// Complete multimodal journey proposal.
class ItineraryDto {
  final String itineraryId;
  final int departureEpochSeconds;
  final int arrivalEpochSeconds;
  final double totalDistanceMeters;
  final int transferCount;
  final double totalSignalDelaySeconds;
  final List<RouteLegDto> legs;

  ItineraryDto({
    required this.itineraryId,
    required this.departureEpochSeconds,
    required this.arrivalEpochSeconds,
    required this.totalDistanceMeters,
    required this.transferCount,
    this.totalSignalDelaySeconds = 0.0,
    required this.legs,
  });

  int get totalDurationSeconds => arrivalEpochSeconds - departureEpochSeconds;

  List<Coordinate> get allWaypoints {
    final List<Coordinate> points = [];
    for (final leg in legs) {
      points.addAll(leg.waypoints);
    }
    return points;
  }

  Map<String, dynamic> toJson() => {
        'itineraryId': itineraryId,
        'departureEpochSeconds': departureEpochSeconds,
        'arrivalEpochSeconds': arrivalEpochSeconds,
        'totalDistanceMeters': totalDistanceMeters,
        'transferCount': transferCount,
        'totalSignalDelaySeconds': totalSignalDelaySeconds,
        'legs': legs.map((l) => l.toJson()).toList(),
      };

  factory ItineraryDto.fromJson(Map<String, dynamic> json) => ItineraryDto(
        itineraryId: json['itineraryId'] as String,
        departureEpochSeconds: json['departureEpochSeconds'] as int,
        arrivalEpochSeconds: json['arrivalEpochSeconds'] as int,
        totalDistanceMeters: (json['totalDistanceMeters'] as num).toDouble(),
        transferCount: json['transferCount'] as int,
        totalSignalDelaySeconds: (json['totalSignalDelaySeconds'] as num?)?.toDouble() ?? 0.0,
        legs: (json['legs'] as List<dynamic>)
            .map((l) => RouteLegDto.fromJson(l as Map<String, dynamic>))
            .toList(),
      );
}
