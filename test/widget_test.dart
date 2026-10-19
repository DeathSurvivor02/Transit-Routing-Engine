import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_transit_app/main.dart';
import 'package:flutter_transit_app/isolate_bridge/offline_routing_bridge.dart';

void main() {
  testWidgets('TransitRoutingApp smoke test', (WidgetTester tester) async {
    final bridge = OfflineRoutingBridge(
      databasePath: 'transit_offline.db',
      encryptionKey: Uint8List(32),
      isEncrypted: false,
    );

    // Build our app and trigger a frame.
    await tester.pumpWidget(TransitRoutingApp(bridge: bridge));

    // Verify app starts up and displays title/home screen.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
