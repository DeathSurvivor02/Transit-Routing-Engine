import '../../isolate_bridge/itinerary_dto.dart';
import '../widgets/mode_filter_chips.dart';

/// Filters computed itineraries by the active transit mode selection.
List<ItineraryDto> filterItinerariesByMode(
  List<ItineraryDto> itineraries,
  TransitModeFilter filter,
) {
  switch (filter) {
    case TransitModeFilter.all:
      return itineraries;
    case TransitModeFilter.transitOnly:
      return itineraries
          .where((itin) => itin.legs.any((leg) => leg.legType == LegType.transit))
          .toList();
    case TransitModeFilter.walkingOnly:
      return itineraries
          .where((itin) =>
              itin.legs.isNotEmpty &&
              itin.legs.every((leg) => leg.legType == LegType.walking))
          .toList();
  }
}
