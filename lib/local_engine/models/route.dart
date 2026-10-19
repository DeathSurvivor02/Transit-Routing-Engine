/// GTFS Route entity.
class TransitRoute {
  final String routeId;
  final String? agencyId;
  final String? routeShortName;
  final String? routeLongName;
  final int routeType; // 0: Tram, 1: Subway, 2: Rail, 3: Bus
  final String? routeColor; // Hex color string, e.g. "EE352E"

  TransitRoute({
    required this.routeId,
    this.agencyId,
    this.routeShortName,
    this.routeLongName,
    required this.routeType,
    this.routeColor,
  });

  String get displayName => routeShortName ?? routeLongName ?? routeId;

  factory TransitRoute.fromMap(Map<String, dynamic> map) {
    return TransitRoute(
      routeId: map['route_id'] as String,
      agencyId: map['agency_id'] as String?,
      routeShortName: map['route_short_name'] as String?,
      routeLongName: map['route_long_name'] as String?,
      routeType: (map['route_type'] as int?) ?? 3,
      routeColor: map['route_color'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'route_id': routeId,
      'agency_id': agencyId,
      'route_short_name': routeShortName,
      'route_long_name': routeLongName,
      'route_type': routeType,
      'route_color': routeColor,
    };
  }
}
