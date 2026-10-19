import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/geometry/coordinate.dart';
import '../../isolate_bridge/itinerary_dto.dart';
import '../bloc/routing_bloc.dart';
import '../bloc/routing_event.dart';
import '../bloc/routing_state.dart';
import '../controllers/google_transit_map_controller.dart';
import '../controllers/i_transit_map_controller.dart';
import '../widgets/itinerary_timeline_view.dart';
import '../widgets/mode_filter_chips.dart';
import '../widgets/persistent_bottom_sheet.dart';

/// Main interactive screen housing the map viewport and persistent bottom sheet.
class TransitHomeScreen extends StatefulWidget {
  const TransitHomeScreen({Key? key}) : super(key: key);

  @override
  State<TransitHomeScreen> createState() => _TransitHomeScreenState();
}

class _TransitHomeScreenState extends State<TransitHomeScreen> {
  late final GoogleTransitMapController _mapController;
  final DraggableScrollableController _sheetController = DraggableScrollableController();

  TransitModeFilter _currentFilter = TransitModeFilter.all;

  // Origin: 200 Murison Blvd, Scarborough
  static const LatLng _initialPosition = LatLng(43.7995, -79.2085);

  final Coordinate _origin = Coordinate(43.7995, -79.2085); // 200 Murison Blvd
  late Coordinate _destination;

  final Map<String, Coordinate> _destinations = {
    'School': Coordinate(43.7853, -79.2282), // Centennial College Progress Campus
    'STC': Coordinate(43.7745, -79.2578),    // Scarborough Town Centre
    'Seneca': Coordinate(43.7955, -79.3496), // Seneca Polytechnic Newnham Campus
  };

  String _selectedDestinationName = 'School';

  @override
  void initState() {
    super.initState();
    _destination = _destinations['School']!;
    _mapController = GoogleTransitMapController(
      onStateChanged: () {
        if (mounted) setState(() {});
      },
    );
  }

  @override
  void dispose() {
    _sheetController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController.attachController(controller);
    _mapController.initialize(initialPosition: _initialPosition, initialZoom: 14.0);
  }

  void _renderItineraryOnMap(ItineraryDto itinerary) {
    _mapController.clearActiveRoute();
    final List<LatLng> allWaypoints = [];

    for (int i = 0; i < itinerary.legs.length; i++) {
      final leg = itinerary.legs[i];
      final isWalk = leg.legType == LegType.walking;
      final legPoints = leg.waypoints.map((w) => LatLng(w.latitude, w.longitude)).toList();
      allWaypoints.addAll(legPoints);

      Color color = Colors.blue;
      if (isWalk) {
        color = Colors.grey.shade700;
      } else if (leg.routeColor != null) {
        final clean = leg.routeColor!.replaceAll('#', '');
        if (clean.length == 6) {
          color = Color(int.parse('FF$clean', radix: 16));
        }
      }

      _mapController.renderRoutePolyline(
        routeId: '${itinerary.itineraryId}_leg_$i',
        waypoints: legPoints,
        color: color,
        isWalkSegment: isWalk,
      );
    }

    if (allWaypoints.isNotEmpty) {
      final bounds = computeRouteBounds(allWaypoints);
      _mapController.updateCameraBounds(bounds, padding: 80.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<RoutingBloc, RoutingState>(
        listener: (context, state) {
          if (state is RoutingSuccessState) {
            _renderItineraryOnMap(state.selectedItinerary);
            // Snap bottom sheet to mid or full view
            if (_sheetController.isAttached) {
              _sheetController.animateTo(
                0.50,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              // 1. Interactive Map Canvas with eager gestures
              Positioned.fill(
                child: GoogleMap(
                  initialCameraPosition: const CameraPosition(
                    target: _initialPosition,
                    zoom: 14.0,
                  ),
                  polylines: _mapController.polylines,
                  markers: _mapController.markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  compassEnabled: true,
                  gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                    Factory<OneSequenceGestureRecognizer>(
                      () => EagerGestureRecognizer(),
                    ),
                  },
                  onMapCreated: _onMapCreated,
                ),
              ),

              // 2. Offline Mode Indicator Pill (Top Bar)
              Positioned(
                top: MediaQuery.of(context).padding.top + 10,
                left: 16,
                right: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.shade800,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.offline_pin, color: Colors.white, size: 16),
                          SizedBox(width: 6),
                          Text(
                            '100% Offline Transit Engine',
                            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    FloatingActionButton.small(
                      heroTag: 'recenter_gps',
                      onPressed: () {
                        _mapController.updateCameraBounds(
                          computeRouteBounds([_initialPosition]),
                        );
                      },
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      child: const Icon(Icons.my_location),
                    ),
                  ],
                ),
              ),

              // 3. Gesture-Coordinated Multi-Snap Bottom Sheet
              TransitPersistentBottomSheet(
                sheetController: _sheetController,
                searchHeader: _buildSearchHeader(context, state),
                itineraryList: _buildItineraryListSliver(context, state),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchHeader(BuildContext context, RoutingState state) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _triggerRouteCalculation(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, size: 18, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '200 Murison -> $_selectedDestinationName',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade800),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: state is RoutingLoadingState
                  ? null
                  : () => _triggerRouteCalculation(context),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              child: state is RoutingLoadingState
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Route'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildPresetChip(context, 'School', '🎓 School (Centennial)'),
              const SizedBox(width: 8),
              _buildPresetChip(context, 'STC', '🏬 STC (Scarborough)'),
              const SizedBox(width: 8),
              _buildPresetChip(context, 'Seneca', '🏫 Seneca (Newnham)'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPresetChip(BuildContext context, String key, String label) {
    final isSelected = _selectedDestinationName == key;
    final theme = Theme.of(context);
    return InkWell(
      onTap: () {
        setState(() {
          _selectedDestinationName = key;
          _destination = _destinations[key]!;
        });
        _triggerRouteCalculation(context);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey.shade800,
          ),
        ),
      ),
    );
  }

  void _triggerRouteCalculation(BuildContext context) {
    context.read<RoutingBloc>().add(RouteRequestEvent(
          origin: _origin,
          destination: _destination,
          departureTime: DateTime.now(),
        ));
  }

  Widget _buildItineraryListSliver(BuildContext context, RoutingState state) {
    if (state is RoutingLoadingState) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 12),
              Text(
                state.statusMessage,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    if (state is RoutingErrorState) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 40, color: Colors.red),
                const SizedBox(height: 8),
                Text(
                  state.errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => _triggerRouteCalculation(context),
                  child: const Text('Retry Search'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (state is RoutingSuccessState) {
      return SliverList(
        delegate: SliverChildListDelegate([
          ModeFilterChips(
            selectedFilter: _currentFilter,
            onFilterSelected: (f) {
              setState(() => _currentFilter = f);
            },
          ),
          const Divider(height: 1),
          // Itinerary selection tabs
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: state.itineraries.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, idx) {
                final itin = state.itineraries[idx];
                final isSelected = itin.itineraryId == state.selectedItinerary.itineraryId;
                return ChoiceChip(
                  label: Text(
                    'Option ${idx + 1} (${(itin.totalDurationSeconds / 60).round()}m)',
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      context.read<RoutingBloc>().add(SelectItineraryEvent(itin));
                    }
                  },
                );
              },
            ),
          ),
          // Detailed timeline view
          ItineraryTimelineView(itinerary: state.selectedItinerary),
          const SizedBox(height: 40),
        ]),
      );
    }

    // Default / initial state: prompt to search
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.directions_transit, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(
              'Select origin and destination to plan an offline route',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
