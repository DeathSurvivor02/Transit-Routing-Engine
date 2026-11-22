import 'package:flutter/material.dart';
import '../../core/geometry/coordinate.dart';

class TransitPlace {
  final String key;
  final String label;
  final String subtitle;
  final Coordinate coordinate;
  final IconData icon;

  const TransitPlace({
    required this.key,
    required this.label,
    required this.subtitle,
    required this.coordinate,
    required this.icon,
  });
}

class RoutePlannerResult {
  final TransitPlace origin;
  final TransitPlace destination;
  final DateTime departureTime;

  const RoutePlannerResult({
    required this.origin,
    required this.destination,
    required this.departureTime,
  });
}

/// Material 3 modal sheet for selecting origin, destination, and departure time.
class RoutePlannerSheet extends StatefulWidget {
  final List<TransitPlace> places;
  final TransitPlace initialOrigin;
  final TransitPlace initialDestination;
  final DateTime initialDeparture;

  const RoutePlannerSheet({
    super.key,
    required this.places,
    required this.initialOrigin,
    required this.initialDestination,
    required this.initialDeparture,
  });

  @override
  State<RoutePlannerSheet> createState() => _RoutePlannerSheetState();
}

class _RoutePlannerSheetState extends State<RoutePlannerSheet> {
  late TransitPlace _origin;
  late TransitPlace _destination;
  late TimeOfDay _departureTime;
  bool _leaveNow = true;

  @override
  void initState() {
    super.initState();
    _origin = widget.initialOrigin;
    _destination = widget.initialDestination;
    _departureTime = TimeOfDay.fromDateTime(widget.initialDeparture);
  }

  void _swapPlaces() {
    setState(() {
      final temp = _origin;
      _origin = _destination;
      _destination = temp;
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _departureTime,
    );
    if (picked != null && mounted) {
      setState(() {
        _departureTime = picked;
        _leaveNow = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final now = DateTime.now();
    final selectedDateTime = _leaveNow
        ? now
        : DateTime(now.year, now.month, now.day, _departureTime.hour, _departureTime.minute);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Plan Route',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
                IconButton(
                  tooltip: 'Swap origin and destination',
                  onPressed: _swapPlaces,
                  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                  icon: const Icon(Icons.swap_vert),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _origin.key,
              decoration: InputDecoration(
                labelText: 'Origin',
                prefixIcon: Icon(_origin.icon, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: widget.places
                  .map((p) => DropdownMenuItem(value: p.key, child: Text(p.label)))
                  .toList(),
              onChanged: (key) {
                if (key == null) return;
                setState(() {
                  _origin = widget.places.firstWhere((p) => p.key == key);
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _destination.key,
              decoration: InputDecoration(
                labelText: 'Destination',
                prefixIcon: Icon(_destination.icon, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: widget.places
                  .map((p) => DropdownMenuItem(value: p.key, child: Text(p.label)))
                  .toList(),
              onChanged: (key) {
                if (key == null) return;
                setState(() {
                  _destination = widget.places.firstWhere((p) => p.key == key);
                });
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() => _leaveNow = true),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      backgroundColor: _leaveNow ? scheme.primaryContainer : null,
                    ),
                    icon: const Icon(Icons.schedule, size: 18),
                    label: const Text(
                      'Leave now',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickTime,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      backgroundColor: !_leaveNow ? scheme.primaryContainer : null,
                    ),
                    icon: const Icon(Icons.access_time, size: 18),
                    label: Text(
                      _leaveNow ? 'Set time' : _departureTime.format(context),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _origin.key == _destination.key
                  ? null
                  : () {
                      Navigator.of(context).pop(
                        RoutePlannerResult(
                          origin: _origin,
                          destination: _destination,
                          departureTime: selectedDateTime,
                        ),
                      );
                    },
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Find Route',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
