import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_transit_app/core/geometry/coordinate.dart';
import 'package:flutter_transit_app/isolate_bridge/itinerary_dto.dart';
import 'package:flutter_transit_app/presentation/bloc/itinerary_filter.dart';
import 'package:flutter_transit_app/presentation/widgets/mode_filter_chips.dart';

RouteLegDto _makeLeg(LegType type) {
  final coord = Coordinate(43.7995, -79.2085);
  return RouteLegDto(
    legType: type,
    fromStopName: 'Stop A',
    toStopName: 'Stop B',
    fromCoordinate: coord,
    toCoordinate: coord,
    departureEpochSeconds: 1000,
    arrivalEpochSeconds: 1300,
    distanceMeters: 400,
    waypoints: [coord],
    instruction: 'Move',
  );
}

ItineraryDto _makeItinerary(String id, List<LegType> types) {
  return ItineraryDto(
    itineraryId: id,
    legs: types.map(_makeLeg).toList(),
    totalDistanceMeters: 400,
    transferCount: 0,
    departureEpochSeconds: 1000,
    arrivalEpochSeconds: 1300,
  );
}

void main() {
  final mixed = _makeItinerary('mixed', [LegType.walking, LegType.transit]);
  final walkOnly = _makeItinerary('walk', [LegType.walking]);
  final all = [mixed, walkOnly];

  test('all mode returns every itinerary', () {
    expect(filterItinerariesByMode(all, TransitModeFilter.all), [mixed, walkOnly]);
  });

  test('transitOnly filters to itineraries with at least one transit leg', () {
    expect(filterItinerariesByMode(all, TransitModeFilter.transitOnly), [mixed]);
  });

  test('walkingOnly filters to itineraries with only walking legs', () {
    expect(filterItinerariesByMode(all, TransitModeFilter.walkingOnly), [walkOnly]);
  });
}
