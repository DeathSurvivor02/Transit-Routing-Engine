import 'package:flutter/material.dart';
import '../../isolate_bridge/itinerary_dto.dart';

/// Detailed timeline view of a selected transit itinerary.
class ItineraryTimelineView extends StatelessWidget {
  final ItineraryDto itinerary;

  const ItineraryTimelineView({super.key, required this.itinerary});

  String _formatTime(int epochSeconds) {
    final dt = DateTime.fromMillisecondsSinceEpoch(epochSeconds * 1000);
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Color _parseHexColor(String? hexString, Color defaultColor) {
    if (hexString == null || hexString.isEmpty) return defaultColor;
    final clean = hexString.replaceAll('#', '');
    if (clean.length == 6) {
      return Color(int.parse('FF$clean', radix: 16));
    }
    return defaultColor;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Itinerary summary card
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${(itinerary.totalDurationSeconds / 60).round()} min',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${_formatTime(itinerary.departureEpochSeconds)} - ${_formatTime(itinerary.arrivalEpochSeconds)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (itinerary.totalSignalDelaySeconds > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade800,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.traffic, size: 14, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            '+${itinerary.totalSignalDelaySeconds.round()}s signal',
                            style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  Chip(
                    label: Text('${itinerary.transferCount} transfers'),
                    labelStyle: const TextStyle(fontSize: 12),
                    backgroundColor: theme.colorScheme.surface,
                  ),
                ],
              ),
            ],
          ),
        ),

        // Step-by-step timeline
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: itinerary.legs.length,
          itemBuilder: (context, index) {
            final leg = itinerary.legs[index];
            final isLast = index == itinerary.legs.length - 1;
            final legColor = leg.legType == LegType.walking
                ? Colors.grey.shade600
                : _parseHexColor(leg.routeColor, theme.colorScheme.primary);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Time column
                  SizedBox(
                    width: 50,
                    child: Text(
                      _formatTime(leg.departureEpochSeconds),
                      style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),

                  // Node and vertical line indicator
                  Column(
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: legColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                      if (!isLast)
                        Container(
                          width: 3,
                          height: 50,
                          color: legColor.withValues(alpha: 0.6),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),

                  // Instruction and description
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                leg.legType == LegType.walking
                                    ? Icons.directions_walk
                                    : Icons.directions_subway,
                                size: 18,
                                color: legColor,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  leg.instruction,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${(leg.durationSeconds / 60).round()} min • ${(leg.distanceMeters).round()}m',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
