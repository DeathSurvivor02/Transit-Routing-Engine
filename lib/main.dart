import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'isolate_bridge/offline_routing_bridge.dart';
import 'local_engine/database/database_deployer.dart';
import 'presentation/bloc/routing_bloc.dart';
import 'presentation/screens/transit_home_screen.dart';
import 'security/secure_database_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Hardware Keystore & Key Management
  final secureManager = SecureDatabaseManager();
  final encryptionKey = await secureManager.getOrCreateEncryptionKey();

  // 2. Deploy & verify bundled encrypted database into sandboxed storage
  String dbPath;
  try {
    dbPath = await DatabaseDeployer.ensureDatabaseDeployed(forceRedeploy: true);
  } catch (e) {
    debugPrint('Database deployment note: $e (using local fallback sandbox)');
    dbPath = 'transit_offline.db';
  }

  // 3. Create Offline Routing Bridge (running calculations in background isolates)
  final bridge = OfflineRoutingBridge(
    databasePath: dbPath,
    encryptionKey: encryptionKey,
    isEncrypted: false, // Set to true when SQLCipher dynamic library binary is linked
  );

  runApp(TransitRoutingApp(bridge: bridge));
}

class TransitRoutingApp extends StatelessWidget {
  final OfflineRoutingBridge bridge;

  const TransitRoutingApp({Key? key, required this.bridge}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RoutingBloc>(
      create: (context) => RoutingBloc(bridge: bridge),
      child: MaterialApp(
        title: 'Offline Transit Routing',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF007AFF),
            brightness: Brightness.light,
          ),
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF007AFF),
            brightness: Brightness.dark,
          ),
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const TransitHomeScreen(),
      ),
    );
  }
}
