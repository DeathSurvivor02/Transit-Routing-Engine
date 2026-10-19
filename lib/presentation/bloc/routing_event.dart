import 'package:equatable/equatable.dart';
import '../../core/geometry/coordinate.dart';
import '../../isolate_bridge/itinerary_dto.dart';
import '../../isolate_bridge/routing_isolate_param.dart';

abstract class RoutingEvent extends Equatable {
  const RoutingEvent();

  @override
  List<Object?> get props => [];
}

/// Request to calculate route between origin and destination coordinates.
class RouteRequestEvent extends RoutingEvent {
  final Coordinate origin;
  final Coordinate destination;
  final DateTime departureTime;
  final TransitPreferences preferences;

  const RouteRequestEvent({
    required this.origin,
    required this.destination,
    required this.departureTime,
    this.preferences = const TransitPreferences(),
  });

  @override
  List<Object?> get props => [origin, destination, departureTime, preferences];
}

/// User selected a specific itinerary option from the bottom sheet.
class SelectItineraryEvent extends RoutingEvent {
  final ItineraryDto itinerary;

  const SelectItineraryEvent(this.itinerary);

  @override
  List<Object?> get props => [itinerary];
}

/// Clear current active route.
class ClearRouteEvent extends RoutingEvent {
  const ClearRouteEvent();
}
