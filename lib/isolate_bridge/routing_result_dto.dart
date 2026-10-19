import 'itinerary_dto.dart';

/// Container for the outcome of an offline route search.
class RoutingResultDto {
  final bool isSuccess;
  final List<ItineraryDto> itineraries;
  final String? errorMessage;
  final int computationTimeMs;

  RoutingResultDto({
    required this.isSuccess,
    required this.itineraries,
    this.errorMessage,
    this.computationTimeMs = 0,
  });

  factory RoutingResultDto.success({
    required List<ItineraryDto> itineraries,
    int computationTimeMs = 0,
  }) {
    return RoutingResultDto(
      isSuccess: true,
      itineraries: itineraries,
      computationTimeMs: computationTimeMs,
    );
  }

  factory RoutingResultDto.failure(String message, {int computationTimeMs = 0}) {
    return RoutingResultDto(
      isSuccess: false,
      itineraries: const [],
      errorMessage: message,
      computationTimeMs: computationTimeMs,
    );
  }
}
