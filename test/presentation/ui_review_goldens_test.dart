import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_transit_app/core/geometry/coordinate.dart';
import 'package:flutter_transit_app/isolate_bridge/itinerary_dto.dart';
import 'package:flutter_transit_app/isolate_bridge/offline_routing_bridge.dart';
import 'package:flutter_transit_app/isolate_bridge/routing_isolate_param.dart';
import 'package:flutter_transit_app/isolate_bridge/routing_result_dto.dart';
import 'package:flutter_transit_app/presentation/bloc/routing_bloc.dart';
import 'package:flutter_transit_app/presentation/bloc/routing_event.dart';
import 'package:flutter_transit_app/presentation/screens/transit_home_screen.dart';

class _StubRoutingBridge extends OfflineRoutingBridge {
  final RoutingResultDto Function() responder;

  _StubRoutingBridge(this.responder)
      : super(
          databasePath: 'stub.db',
          encryptionKey: Uint8List(32),
          isEncrypted: false,
        );

  @override
  Future<RoutingResultDto> calculateRoute({
    required Coordinate origin,
    required Coordinate destination,
    required DateTime departureTime,
    TransitPreferences preferences = const TransitPreferences(),
  }) async {
    return responder();
  }
}

Widget _buildTestApp(RoutingBloc bloc) {
  return BlocProvider<RoutingBloc>.value(
    value: bloc,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0062CC),
          brightness: Brightness.light,
        ).copyWith(
          primary: const Color(0xFF0062CC),
          onPrimary: Colors.white,
        ),
      ),
      home: const TransitHomeScreen(),
    ),
  );
}

void main() {
  final origin = Coordinate(43.7995, -79.2085);
  final dest = Coordinate(43.7853, -79.2282);

  final sampleItinerary = ItineraryDto(
    itineraryId: 'itin_1',
    departureEpochSeconds: 1700000000,
    arrivalEpochSeconds: 1700001200,
    totalDistanceMeters: 3200,
    transferCount: 0,
    totalSignalDelaySeconds: 18,
    legs: [
      RouteLegDto(
        legType: LegType.transit,
        routeId: '95',
        routeShortName: '95',
        routeColor: '#0062CC',
        fromStopName: 'Murison Blvd',
        toStopName: 'Centennial Progress',
        fromCoordinate: origin,
        toCoordinate: dest,
        departureEpochSeconds: 1700000000,
        arrivalEpochSeconds: 1700001200,
        distanceMeters: 3200,
        waypoints: [origin, dest],
        instruction: 'Take 95 York Mills East to Centennial Progress',
        signalDelaySeconds: 18,
      ),
    ],
  );

  testWidgets('capture 412x915 UI review states', (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    // 1. Home screen with map
    final successBridge = _StubRoutingBridge(
      () => RoutingResultDto(isSuccess: true, itineraries: [sampleItinerary]),
    );
    final bloc = RoutingBloc(bridge: successBridge);
    addTearDown(bloc.close);

    await tester.pumpWidget(_buildTestApp(bloc));
    await tester.pump(const Duration(milliseconds: 300));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../../docs/ui-review/01_home_map.png'),
    );

    // 2. Route planner sheet open
    await tester.tap(find.text('Home -> School'));
    await tester.pump(const Duration(milliseconds: 400));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../../docs/ui-review/02_route_planner_sheet.png'),
    );

    // Close modal sheet
    Navigator.of(tester.element(find.text('Plan Route'))).pop();
    await tester.pump(const Duration(milliseconds: 400));

    // 3. Empty-after-filter state (route exists with transit, filter = Walking Only)
    bloc.add(RouteRequestEvent(
      origin: origin,
      destination: dest,
      departureTime: DateTime.now(),
    ));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.ensureVisible(find.text('Walking Only'));
    await tester.tap(find.text('Walking Only'));
    await tester.pump(const Duration(milliseconds: 200));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../../docs/ui-review/03_empty_after_filter.png'),
    );

    // 4. Error state
    final errorBridge = _StubRoutingBridge(
      () => RoutingResultDto(
        isSuccess: false,
        itineraries: const [],
        errorMessage: 'No offline transit connections found for the selected time.',
      ),
    );
    final errorBloc = RoutingBloc(bridge: errorBridge);
    addTearDown(errorBloc.close);

    await tester.pumpWidget(_buildTestApp(errorBloc));
    await tester.pump(const Duration(milliseconds: 200));
    errorBloc.add(RouteRequestEvent(
      origin: origin,
      destination: dest,
      departureTime: DateTime.now(),
    ));
    await tester.pump(const Duration(milliseconds: 400));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../../docs/ui-review/04_error_state.png'),
    );
  });
}
