import 'package:flutter_test/flutter_test.dart';
import '../../lib/local_engine/routing/connection_scan_algorithm.dart';
import '../../lib/local_engine/routing/graph_node.dart';

void main() {
  group('ConnectionScanAlgorithm (CSA) Tests', () {
    test('Finds direct transit route with earliest arrival', () {
      // 3 stops: A -> B -> C
      final connections = [
        TimetableConnection(
          tripId: 'trip_1',
          routeId: 'route_red',
          fromStopId: 'stop_A',
          toStopId: 'stop_B',
          departureTime: 3600, // 01:00
          arrivalTime: 3900,   // 01:05
          sequence: 1,
        ),
        TimetableConnection(
          tripId: 'trip_1',
          routeId: 'route_red',
          fromStopId: 'stop_B',
          toStopId: 'stop_C',
          departureTime: 3960, // 01:06
          arrivalTime: 4300,   // 01:11
          sequence: 2,
        ),
      ];

      final result = ConnectionScanAlgorithm.findEarliestArrival(
        originStopIds: ['stop_A'],
        destinationStopIds: ['stop_C'],
        departureTimeSec: 3500,
        sortedConnections: connections,
      );

      expect(result, isNotNull);
      expect(result!.connections.length, equals(2));
      expect(result.departureTime, equals(3600));
      expect(result.arrivalTime, equals(4300));
      expect(result.duration, equals(700));
    });

    test('Finds transfer route across two different trips', () {
      // Trip 1: stop_A -> stop_B (dep 3600, arr 3800)
      // Trip 2: stop_B -> stop_D (dep 3900, arr 4200)
      final connections = [
        TimetableConnection(
          tripId: 'trip_1',
          routeId: 'route_blue',
          fromStopId: 'stop_A',
          toStopId: 'stop_B',
          departureTime: 3600,
          arrivalTime: 3800,
          sequence: 1,
        ),
        TimetableConnection(
          tripId: 'trip_2',
          routeId: 'route_green',
          fromStopId: 'stop_B',
          toStopId: 'stop_D',
          departureTime: 3900,
          arrivalTime: 4200,
          sequence: 1,
        ),
      ];

      final result = ConnectionScanAlgorithm.findEarliestArrival(
        originStopIds: ['stop_A'],
        destinationStopIds: ['stop_D'],
        departureTimeSec: 3500,
        sortedConnections: connections,
      );

      expect(result, isNotNull);
      expect(result!.connections.length, equals(2));
      expect(result.connections[0].tripId, equals('trip_1'));
      expect(result.connections[1].tripId, equals('trip_2'));
      expect(result.arrivalTime, equals(4200));
    });

    test('Returns null when no viable connections exist', () {
      final connections = [
        TimetableConnection(
          tripId: 'trip_1',
          routeId: 'route_blue',
          fromStopId: 'stop_X',
          toStopId: 'stop_Y',
          departureTime: 3600,
          arrivalTime: 3800,
          sequence: 1,
        ),
      ];

      final result = ConnectionScanAlgorithm.findEarliestArrival(
        originStopIds: ['stop_A'],
        destinationStopIds: ['stop_B'],
        departureTimeSec: 3500,
        sortedConnections: connections,
      );

      expect(result, isNull);
    });
  });
}
