import 'package:flutter/material.dart';

enum TransitModeFilter { all, transitOnly, walkingOnly }

/// Filter chips allowing users to switch between All, Transit, or Walking preferences.
class ModeFilterChips extends StatelessWidget {
  final TransitModeFilter selectedFilter;
  final ValueChanged<TransitModeFilter> onFilterSelected;

  const ModeFilterChips({
    Key? key,
    required this.selectedFilter,
    required this.onFilterSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        children: [
          _buildChip(
            context,
            filter: TransitModeFilter.all,
            label: 'All Modes',
            icon: Icons.alt_route,
          ),
          const SizedBox(width: 8),
          _buildChip(
            context,
            filter: TransitModeFilter.transitOnly,
            label: 'Transit Only',
            icon: Icons.directions_subway,
          ),
          const SizedBox(width: 8),
          _buildChip(
            context,
            filter: TransitModeFilter.walkingOnly,
            label: 'Walking Only',
            icon: Icons.directions_walk,
          ),
        ],
      ),
    );
  }

  Widget _buildChip(
    BuildContext context, {
    required TransitModeFilter filter,
    required String label,
    required IconData icon,
  }) {
    final isSelected = selectedFilter == filter;
    final theme = Theme.of(context);

    return FilterChip(
      selected: isSelected,
      avatar: Icon(
        icon,
        size: 16,
        color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
      ),
      label: Text(label),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
      ),
      selectedColor: theme.colorScheme.primary,
      backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(0.5),
      onSelected: (_) => onFilterSelected(filter),
    );
  }
}
