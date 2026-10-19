import 'package:equatable/equatable.dart';
import '../../isolate_bridge/itinerary_dto.dart';

abstract class RoutingState extends Equatable {
  const RoutingState();

  @override
  List<Object?> get props => [];
}

class RoutingInitialState extends RoutingState {
  const RoutingInitialState();
}

class RoutingLoadingState extends RoutingState {
  final String statusMessage;

  const RoutingLoadingState({this.statusMessage = 'Searching offline transit schedule...'});

  @override
  List<Object?> get props => [statusMessage];
}

class RoutingSuccessState extends RoutingState {
  final List<ItineraryDto> itineraries;
  final ItineraryDto selectedItinerary;
  final int computationTimeMs;

  const RoutingSuccessState({
    required this.itineraries,
    required this.selectedItinerary,
    this.computationTimeMs = 0,
  });

  @override
  List<Object?> get props => [itineraries, selectedItinerary, computationTimeMs];

  RoutingSuccessState copyWith({
    List<ItineraryDto>? itineraries,
    ItineraryDto? selectedItinerary,
    int? computationTimeMs,
  }) {
    return RoutingSuccessState(
      itineraries: itineraries ?? this.itineraries,
      selectedItinerary: selectedItinerary ?? this.selectedItinerary,
      computationTimeMs: computationTimeMs ?? this.computationTimeMs,
    );
  }
}

class RoutingErrorState extends RoutingState {
  final String errorMessage;

  const RoutingErrorState(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}
