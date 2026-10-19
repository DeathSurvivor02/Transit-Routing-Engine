import 'package:flutter_bloc/flutter_bloc.dart';
import '../../isolate_bridge/offline_routing_bridge.dart';
import 'routing_event.dart';
import 'routing_state.dart';

/// BLoC orchestrator coordinating background transit routing and UI states.
class RoutingBloc extends Bloc<RoutingEvent, RoutingState> {
  final OfflineRoutingBridge _bridge;

  RoutingBloc({required OfflineRoutingBridge bridge})
      : _bridge = bridge,
        super(const RoutingInitialState()) {
    on<RouteRequestEvent>(_onRouteRequest);
    on<SelectItineraryEvent>(_onSelectItinerary);
    on<ClearRouteEvent>(_onClearRoute);
  }

  Future<void> _onRouteRequest(RouteRequestEvent event, Emitter<RoutingState> emit) async {
    emit(const RoutingLoadingState());

    try {
      final result = await _bridge.calculateRoute(
        origin: event.origin,
        destination: event.destination,
        departureTime: event.departureTime,
        preferences: event.preferences,
      );

      if (result.isSuccess && result.itineraries.isNotEmpty) {
        emit(RoutingSuccessState(
          itineraries: result.itineraries,
          selectedItinerary: result.itineraries.first,
          computationTimeMs: result.computationTimeMs,
        ));
      } else {
        emit(RoutingErrorState(
          result.errorMessage ?? 'No feasible transit or walking route found.',
        ));
      }
    } catch (e) {
      emit(RoutingErrorState('Failed to calculate route: $e'));
    }
  }

  void _onSelectItinerary(SelectItineraryEvent event, Emitter<RoutingState> emit) {
    if (state is RoutingSuccessState) {
      final current = state as RoutingSuccessState;
      emit(current.copyWith(selectedItinerary: event.itinerary));
    }
  }

  void _onClearRoute(ClearRouteEvent event, Emitter<RoutingState> emit) {
    emit(const RoutingInitialState());
  }
}
