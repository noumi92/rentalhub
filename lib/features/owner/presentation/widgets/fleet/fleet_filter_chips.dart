import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../l10n/app_localizations.dart';

/// The fleet filter chips row, extracted from [OwnerFleetView] so the
/// view stays under the 250-line cap.
class FleetFilterChips extends StatelessWidget {
  const FleetFilterChips({
    super.key,
    required this.selectedFilter,
    required this.totalCount,
    required this.availableCount,
    required this.onRentCount,
    required this.maintenanceCount,
    required this.onSelected,
  });

  final String selectedFilter;
  final int totalCount;
  final int availableCount;
  final int onRentCount;
  final int maintenanceCount;
  final ValueChanged<String> onSelected;

  // Internal filter keys stay as state; only the displayed label is localized.
  static String _filterLabel(AppLocalizations l10n, String label) => {'Available': l10n.available, 'On Rent': l10n.fleetOnRent, 'Maintenance': l10n.fleetFilterMaintenance}[label] ?? l10n.fleetFilterAll;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // E3: 48dp chip + 6dp vertical padding each
    // side — the old 48dp row squeezed the chips to 36dp.
    return Container(
      height: AppDimensions.minTouchTarget + 12,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: Theme.of(context).colorScheme.surface,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _filterChip(context, l10n, 'All', totalCount),
          const SizedBox(width: 8),
          _filterChip(context, l10n, 'Available', availableCount),
          const SizedBox(width: 8),
          _filterChip(context, l10n, 'On Rent', onRentCount),
          const SizedBox(width: 8),
          _filterChip(context, l10n, 'Maintenance', maintenanceCount),
        ],
      ),
    );
  }

  Widget _filterChip(BuildContext context, AppLocalizations l10n, String label, int count) {
    final isSelected = selectedFilter == label;
    return ChoiceChip(
      materialTapTargetSize: MaterialTapTargetSize.padded,
      label: Text(l10n.fleetFilterChip(_filterLabel(l10n, label), count)),
      selected: isSelected,
      // Audit §4: explicit label colour per state — white on the
      // orangeFill (5.18:1, both modes), theme onSurface unselected.
      // The old implicit chipTheme colour on #F95700 failed AA.
      selectedColor: AppColors.orangeFill,
      labelStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w500,
          color: isSelected
              ? Colors.white
              : Theme.of(context).colorScheme.onSurface),
      onSelected: (_) => onSelected(label),
    );
  }
}
