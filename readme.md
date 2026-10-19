# Flutter Offline Transit Routing Engine

A production-grade, fully offline multimodal transit and walking routing application built with Flutter, SQLCipher, SQLite R*Tree, and background Dart isolates.

Based on the [Flutter Transit Routing Specification](c:/Users/bynoe/Downloads/flutter_transit_routing_specification.md).

---

## Architecture Overview

```
+------------------------------------------------------------------------------------+
|                                FRONT-END SUBSYSTEM                                 |
|  +------------------------------+  +---------------------------------------------+ |
|  |  Interactive Map Controller  |  | Persistent Multi-Snap Bottom Sheet          | |
|  |  (Google Maps / MapLibre)    |  | (Search, Filters, Itinerary Timeline)       | |
|  +--------------+---------------+  +----------------------+----------------------+ |
|                 |                                         |                        |
|                 +-------------------+---------------------+                        |
|                                     |                                              |
|                                     v                                              |
|                      +------------------------------+                              |
|                      |  Routing Orchestrator (BLoC) |                              |
|                      +--------------+---------------+                              |
+-------------------------------------|----------------------------------------------+
                                      | Isolate.run() / Worker Pool
+-------------------------------------v----------------------------------------------+
|                              BACK-END (LOCAL ENGINE)                               |
|  +-------------------------------------------------------------------------------+ |
|  | Background Worker Isolate                                                     | |
|  |  +-----------------------------------+  +----------------------------------+  | |
|  |  | Time-Dependent Routing Core       |  | Dynamic Signal Delay Engine      |  | |
|  |  | (CSA / Time-Dependent A*)         |  | (Webster Delay / Green Splittings)|  | |
|  |  +-----------------+-----------------+  +-----------------+----------------+  | |
|  |                    |                                      |                   | |
|  |                    +------------------+-------------------+                   | |
|  |                                       |                                       | |
|  |                                       v                                       | |
|  |                     +-----------------------------------+                     | |
|  |                     |  Encrypted Local SQLite Database  |                     | |
|  |                     |  (Pre-bundled Asset, SQLCipher)   |                     | |
|  |                     |  - GTFS Stops, Routes, Trips      |                     | |
|  |                     |  - R*Tree Spatial Indices         |                     | |
|  |                     |  - Signal Cycle & Timing Matrices |                     | |
|  |                     +-----------------------------------+                     | |
|  +-------------------------------------------------------------------------------+ |
+------------------------------------------------------------------------------------+
                                      ^
                                      | Guarded by
+-------------------------------------v----------------------------------------------+
|                                SECURITY SUBSYSTEM                                  |
|  - AES-256 SQLCipher Database Encryption                                           |
|  - Hardware Keystore / Keyring Key Management (flutter_secure_storage)             |
|  - Asset Integrity Validation (HMAC-SHA256 Manifest Verification)                  |
|  - In-Memory Key Zeroization & Anti-Tamper Runtime Probes                          |
+------------------------------------------------------------------------------------+
```

---

## Key Components

### 1. Front-End Subsystem (`lib/presentation/`)
- **`ITransitMapController`**: Decoupled map abstraction for Google Maps and MapLibre.
- **Polyline Styling**: Dashed polylines (`PatternItem.dash(20)`, `PatternItem.gap(10)`) for walking legs and solid agency hex-branded vector lines for transit.
- **Dynamic Bounding Box**: `computeRouteBounds` smoothly centers and fits multi-leg itineraries.
- **`TransitPersistentBottomSheet`**: 3-state snapping (`0.14` peek, `0.50` mid, `0.95` full) resolving gesture conflicts against the interactive map canvas.

### 2. Local Engine Subsystem (`lib/local_engine/`)
- **Pre-bundled SQLite Schema**: Complete GTFS tables (`stops`, `routes`, `trips`, `stop_times`) with R*Tree spatial indexing (`stops_spatial_idx`).
- **Dynamic Signal Delay Engine (`WebsterDelayModel`)**:
  - Deterministic cycle phase alignment: $\tau(t) = (t - \text{phase\_offset}) \pmod C$.
  - Uniform wait time: $W_{\text{wait}}(t) = C - \tau(t)$ during red phase, $0$ during green.
  - Webster's modified delay formulation:
    $$d = \frac{C \left(1 - \frac{g}{C}\right)^2}{2\left[1 - \min(1, x)\cdot \frac{g}{C}\right]} + \frac{x^2}{2q(1 - x)}$$
- **Routing Algorithms**:
  - Connection Scan Algorithm (CSA) for ultra-fast timetable querying.
  - Time-Dependent A* on street edges with dynamic signal wait times.
  - Multimodal integration combining walking transfers and scheduled transit legs.

### 3. Security Subsystem (`lib/security/`)
- **SQLCipher Encryption**: AES-256-CBC with PBKDF2 (HMAC-SHA512, 256,000 iterations, 4096-byte page size).
- **Key Storage**: Hardware-backed Keystore/Keychain via `FlutterSecureStorage`.
- **Memory Zeroization (`MemoryZeroizer`)**: Cryptographic zeroization of sensitive raw key buffers in memory post-initialization.
- **Asset Integrity (`AssetIntegrityVerifier`)**: HMAC-SHA256 and constant-time string verification before database unpacking.
- **Storage Hardening**: Zero internet permissions declared in `AndroidManifest.xml`, `android:allowBackup="false"`, and private app storage isolation.

---

## Directory Structure

```
flutter_transit_app/
├── assets/
│   └── database/
│       ├── manifest.json
│       └── transit_offline.db
├── android/
│   └── app/src/main/AndroidManifest.xml
├── ios/
│   └── Runner/Info.plist
├── lib/
│   ├── main.dart
│   ├── core/
│   │   ├── constants/transit_constants.dart
│   │   ├── errors/security_exception.dart
│   │   ├── geometry/coordinate.dart
│   │   ├── geometry/haversine.dart
│   │   └── utils/hex_codec.dart
│   ├── security/
│   │   ├── memory_zeroizer.dart
│   │   ├── asset_integrity_verifier.dart
│   │   └── secure_database_manager.dart
│   ├── local_engine/
│   │   ├── database/
│   │   │   ├── database_deployer.dart
│   │   │   └── sqlite_schema.dart
│   │   ├── models/
│   │   │   ├── stop.dart
│   │   │   ├── route.dart
│   │   │   ├── trip.dart
│   │   │   ├── stop_time.dart
│   │   │   ├── traffic_signal.dart
│   │   │   ├── signal_timing_plan.dart
│   │   │   └── street_edge.dart
│   │   ├── spatial/
│   │   │   ├── quadtree.dart
│   │   │   └── rtree_spatial_index.dart
│   │   ├── signals/
│   │   │   ├── webster_delay_model.dart
│   │   │   └── signal_delay_calculator.dart
│   │   └── routing/
│   │       ├── graph_node.dart
│   │       ├── connection_scan_algorithm.dart
│   │       ├── time_dependent_astar.dart
│   │       └── local_transit_graph_engine.dart
│   ├── isolate_bridge/
│   │   ├── itinerary_dto.dart
│   │   ├── routing_isolate_param.dart
│   │   ├── routing_result_dto.dart
│   │   └── offline_routing_bridge.dart
│   └── presentation/
│       ├── bloc/
│       │   ├── routing_bloc.dart
│       │   ├── routing_event.dart
│       │   └── routing_state.dart
│       ├── controllers/
│       │   ├── i_transit_map_controller.dart
│       │   └── google_transit_map_controller.dart
│       ├── widgets/
│       │   ├── persistent_bottom_sheet.dart
│       │   ├── search_header_delegate.dart
│       │   ├── mode_filter_chips.dart
│       │   └── itinerary_timeline_view.dart
│       └── screens/
│           └── transit_home_screen.dart
├── test/
│   ├── local_engine/
│   │   ├── webster_delay_test.dart
│   │   ├── spatial_index_test.dart
│   │   └── csa_routing_test.dart
│   ├── security/
│   │   ├── integrity_verifier_test.dart
│   │   └── memory_zeroizer_test.dart
│   └── presentation/
│       └── bounds_computation_test.dart
├── tool/
│   └── seed_database.dart
└── pubspec.yaml
```

---

## Running and Testing

### 1. Run Tests
```bash
flutter test
```

### 2. Generate Seed Database
```bash
dart run tool/seed_database.dart
```

### 3. Build Production Release (with Obfuscation)
```bash
flutter build apk --release --obfuscate --split-debug-info=./debug_symbols
flutter build ipa --release --obfuscate --split-debug-info=./debug_symbols
```
