import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as osm;
import '../../core/geometry/coordinate.dart';
import '../../isolate_bridge/itinerary_dto.dart';
import '../bloc/itinerary_filter.dart';
import '../bloc/routing_bloc.dart';
import '../bloc/routing_event.dart';
import '../bloc/routing_state.dart';
import '../controllers/osm_transit_map_controller.dart';
import '../widgets/itinerary_timeline_view.dart';
import '../widgets/mode_filter_chips.dart';
import '../widgets/persistent_bottom_sheet.dart';
import '../widgets/route_planner_sheet.dart';

/// Main interactive screen housing the OpenStreetMap viewport and persistent bottom sheet.
class TransitHomeScreen extends StatefulWidget {
  const TransitHomeScreen({super.key});

  @override
  State<TransitHomeScreen> createState() => _TransitHomeScreenState();
}

class _TransitHomeScreenState extends State<TransitHomeScreen> {
  late final OsmTransitMapController _mapController;
  final DraggableScrollableController _sheetController = DraggableScrollableController();

  TransitModeFilter _currentFilter = TransitModeFilter.all;
  DateTime _departureTime = DateTime.now();

  static const osm.LatLng _initialPosition = osm.LatLng(43.7995, -79.2085);

  static final List<TransitPlace> _places = [
    TransitPlace(
      key: 'Home',
      label: 'Home (200 Murison)',
      subtitle: '200 Murison Blvd, Scarborough',
      coordinate: Coordinate(43.7995, -79.2085),
      icon: Icons.home,
    ),
    TransitPlace(
      key: 'School',
      label: 'School (Centennial)',
      subtitle: 'Centennial College Progress Campus',
      coordinate: Coordinate(43.7853, -79.2282),
      icon: Icons.school,
    ),
    TransitPlace(
      key: 'STC',
      label: 'STC (Scarborough)',
      subtitle: 'Scarborough Town Centre',
      coordinate: Coordinate(43.7745, -79.2578),
      icon: Icons.storefront,
    ),
    TransitPlace(
      key: 'Seneca',
      label: 'Seneca (Newnham)',
      subtitle: 'Seneca Polytechnic Newnham Campus',
      coordinate: Coordinate(43.7955, -79.3496),
      icon: Icons.account_balance,
    ),
  ];

  late TransitPlace _originPlace;
  late TransitPlace _destinationPlace;

  @override
  void initState() {
    super.initState();
    _originPlace = _places[0];
    _destinationPlace = _places[1];
    _mapController = OsmTransitMapController(
      onStateChanged: () {
        if (mounted) setState(() {});
      },
    );
    _setupInitialMarkers();
  }

  void _setupInitialMarkers() {
    _mapController.clearActiveRoute();
    _mapController.addMarker(
      point: osm.LatLng(_originPlace.coordinate.latitude, _originPlace.coordinate.longitude),
      label: _originPlace.label,
      icon: _originPlace.icon,
      color: Colors.green.shade700,
    );
    _mapController.addMarker(
      point: osm.LatLng(_destinationPlace.coordinate.latitude, _destinationPlace.coordinate.longitude),
      label: _destinationPlace.label,
      icon: _destinationPlace.icon,
      color: Colors.red.shade700,
    );
  }

  @override
  void dispose() {
    _sheetController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _renderItineraryOnMap(ItineraryDto itinerary) {
    _mapController.clearActiveRoute();
    final List<osm.LatLng> allWaypoints = [];

    _mapController.addMarker(
      point: osm.LatLng(_originPlace.coordinate.latitude, _originPlace.coordinate.longitude),
      label: _originPlace.label,
      icon: _originPlace.icon,
      color: Colors.green.shade700,
    );

    final primaryColor = Theme.of(context).colorScheme.primary;
    for (int i = 0; i < itinerary.legs.length; i++) {
      final leg = itinerary.legs[i];
      final isWalk = leg.legType == LegType.walking;
      final legPoints = leg.waypoints
          .map((w) => osm.LatLng(w.latitude, w.longitude))
          .toList();
      allWaypoints.addAll(legPoints);

      Color color = primaryColor;
      if (isWalk) {
        color = Colors.grey.shade600;
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

      if (!isWalk && legPoints.isNotEmpty) {
        _mapController.addMarker(
          point: legPoints.first,
          label: leg.fromStopName,
          icon: Icons.directions_bus,
          color: color,
          size: 30.0,
        );
        _mapController.addMarker(
          point: legPoints.last,
          label: leg.toStopName,
          icon: Icons.directions_bus,
          color: color,
          size: 30.0,
        );
      }
    }

    _mapController.addMarker(
      point: osm.LatLng(_destinationPlace.coordinate.latitude, _destinationPlace.coordinate.longitude),
      label: _destinationPlace.label,
      icon: _destinationPlace.icon,
      color: Colors.red.shade700,
    );

    if (allWaypoints.isNotEmpty) {
      _mapController.fitBounds(allWaypoints, padding: 80.0);
    }
  }

  Future<void> _openRoutePlanner(BuildContext context) async {
    final result = await showModalBottomSheet<RoutePlannerResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => RoutePlannerSheet(
        places: _places,
        initialOrigin: _originPlace,
        initialDestination: _destinationPlace,
        initialDeparture: _departureTime,
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _originPlace = result.origin;
        _destinationPlace = result.destination;
        _departureTime = result.departureTime;
      });
      _setupInitialMarkers();
      if (context.mounted) {
        _triggerRouteCalculation(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: BlocConsumer<RoutingBloc, RoutingState>(
        listener: (context, state) {
          if (state is RoutingSuccessState) {
            _renderItineraryOnMap(state.selectedItinerary);
            if (_sheetController.isAttached) {
              _sheetController.animateTo(
                0.45,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              Positioned.fill(
                child: FlutterMap(
                  mapController: _mapController.mapController,
                  options: const MapOptions(
                    initialCenter: _initialPosition,
                    initialZoom: 14.5,
                    interactionOptions: InteractionOptions(
                      flags: InteractiveFlag.all,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.flutter_transit_app',
                      tileProvider: NetworkTileProvider(
                        headers: {
                          'User-Agent': 'FlutterTransitApp/1.0 (contact: bynoeean@gmail.com)',
                        },
                      ),
                      errorTileCallback: (tile, error, stackTrace) {
                        // Silently handle tile network failures (e.g. offline or test environment)
                      },
                      maxZoom: 19,
                    ),
                    PolylineLayer(
                      polylines: _mapController.polylines,
                    ),
                    MarkerLayer(
                      markers: _mapController.markers,
                    ),
                  ],
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 16,
                right: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: scheme.outlineVariant),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.map_outlined, color: scheme.primary, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Offline OSM Map',
                            style: TextStyle(
                              color: scheme.onSurface,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton.filledTonal(
                      tooltip: 'Recenter map',
                      onPressed: () {
                        _mapController.recenter(
                          osm.LatLng(
                            _originPlace.coordinate.latitude,
                            _originPlace.coordinate.longitude,
                          ),
                        );
                      },
                      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                      icon: const Icon(Icons.my_location),
                    ),
                  ],
                ),
              ),
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
    final scheme = Theme.of(context).colorScheme;
    final presetDestinations = _places.where((p) => p.key != _originPlace.key).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _openRoutePlanner(context),
                borderRadius: BorderRadius.circular(12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search, size: 18, color: scheme.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${_originPlace.key} -> ${_destinationPlace.key}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(Icons.tune, size: 18, color: scheme.onSurfaceVariant),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: state is RoutingLoadingState
                  ? null
                  : () => _triggerRouteCalculation(context),
              style: FilledButton.styleFrom(
                minimumSize: const Size(88, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: state is RoutingLoadingState
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: scheme.onPrimary,
                      ),
                    )
                  : const Text(
                      'Route',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: presetDestinations
                .map((place) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _buildPresetChip(context, place),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildPresetChip(BuildContext context, TransitPlace place) {
    final isSelected = _destinationPlace.key == place.key;
    final scheme = Theme.of(context).colorScheme;

    return ChoiceChip(
      selected: isSelected,
      avatar: Icon(
        place.icon,
        size: 16,
        color: isSelected ? scheme.onPrimary : scheme.onSurfaceVariant,
      ),
      label: Text(
        place.label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          color: isSelected ? scheme.onPrimary : scheme.onSurface,
        ),
      ),
      selectedColor: scheme.primary,
      backgroundColor: scheme.surfaceContainerHighest,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      onSelected: (_) {
        setState(() {
          _destinationPlace = place;
        });
        _setupInitialMarkers();
        _triggerRouteCalculation(context);
      },
    );
  }

  void _triggerRouteCalculation(BuildContext context) {
    context.read<RoutingBloc>().add(RouteRequestEvent(
          origin: _originPlace.coordinate,
          destination: _destinationPlace.coordinate,
          departureTime: _departureTime,
        ));
  }

  Widget _buildItineraryListSliver(BuildContext context, RoutingState state) {
    final scheme = Theme.of(context).colorScheme;

    if (state is RoutingLoadingState) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  state.statusMessage,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (state is RoutingErrorState) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 40, color: scheme.error),
                const SizedBox(height: 8),
                Text(
                  state.errorMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: scheme.error,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => _triggerRouteCalculation(context),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(120, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Retry Search',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (state is RoutingSuccessState) {
      final filteredItineraries = filterItinerariesByMode(state.itineraries, _currentFilter);

      if (filteredItineraries.isEmpty) {
        return SliverList(
          delegate: SliverChildListDelegate([
            ModeFilterChips(
              selectedFilter: _currentFilter,
              onFilterSelected: (f) => setState(() => _currentFilter = f),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.filter_list_off, size: 36, color: scheme.onSurfaceVariant),
                  const SizedBox(height: 8),
                  Text(
                    'No routes match the selected mode filter.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () => setState(() => _currentFilter = TransitModeFilter.all),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(140, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      'Show All Modes',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ]),
        );
      }

      final activeItinerary = filteredItineraries.any(
        (itin) => itin.itineraryId == state.selectedItinerary.itineraryId,
      )
          ? state.selectedItinerary
          : filteredItineraries.first;

      return SliverList(
        delegate: SliverChildListDelegate([
          ModeFilterChips(
            selectedFilter: _currentFilter,
            onFilterSelected: (f) {
              setState(() => _currentFilter = f);
            },
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 52,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: filteredItineraries.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, idx) {
                final itin = filteredItineraries[idx];
                final isSelected = itin.itineraryId == activeItinerary.itineraryId;
                return ChoiceChip(
                  label: Text(
                    'Option ${idx + 1} (${(itin.totalDurationSeconds / 60).round()}m)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  selected: isSelected,
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                  onSelected: (selected) {
                    if (selected) {
                      context.read<RoutingBloc>().add(SelectItineraryEvent(itin));
                    }
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          ItineraryTimelineView(itinerary: activeItinerary),
          const SizedBox(height: 24),
        ]),
      );
    }

    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.directions_transit, size: 48, color: scheme.onSurfaceVariant),
              const SizedBox(height: 16),
              Text(
                'Select origin and destination to plan an offline route',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
