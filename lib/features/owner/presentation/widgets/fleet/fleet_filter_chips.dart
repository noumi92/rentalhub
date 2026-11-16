import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../l10n/app_localizations.dart';

/// Showroom redesign (Phase 2, 2026-11-16): the old KPI boxes and the
/// filter chips are merged into ONE segmented bar — four equal
/// segments (All / Ready / On Rent / Maintenance) in a single row.
/// Maintenance is KEPT: the guide's 3-segment example drops it,
/// but a maintenance car must stay filterable. Total Fleet is the
/// "All" count. Each segment carries its count (the merged KPI) and a
/// status dot (Ready green, On Rent orange, Maintenance amber); the
/// selected segment keeps the theme chip spec (navy fill + white
/// label, DS-1) via [ChoiceChip] — the theme owns the selected style,
/// this file sets no selectedColor.
///
/// User layout 2026-11-16: the white card behind the bar is gone —
/// the four segments sit directly on the scaffold background, with no
/// wrapping Container. Segment labels are 14sp, set on the label
/// Text itself — the theme chipTheme (11sp) and its selected spec
/// (navy fill + white label, DS-1) are untouched, so no per-file
/// chip override exists here. DS-1 is untouched: no per-file
/// selectedColor/labelStyle.
///
/// Internal filter keys stay as state ('All' | 'Available' |
/// 'On Rent' | 'Maintenance'); only the displayed label is localized
/// — 'Available' renders as the new `fleetReady` ("Ready") label.
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

  static String _filterLabel(AppLocalizations l10n, String label) => {'Available': l10n.fleetReady, 'On Rent': l10n.fleetOnRent, 'Maintenance': l10n.fleetFilterMaintenance}[label] ?? l10n.fleetFilterAll;

  /// The status dot per segment; All has none. Dots use the same
  /// filled tokens as the card status chips (never a hardcoded hex).
  static Color? _dotColor(String label) => switch (label) {
        'Available' => AppColors.accentSuccessStrong,
        'On Rent' => AppColors.orangeFill,
        'Maintenance' => AppColors.warningOnContainer,
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Four loose chips directly on the scaffold background — no
    // wrapping card (user layout 2026-11-16).
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          _segment(context, l10n, 'All', totalCount),
          _segment(context, l10n, 'Available', availableCount),
          _segment(context, l10n, 'On Rent', onRentCount),
          _segment(context, l10n, 'Maintenance', maintenanceCount),
        ],
      ),
    );
  }

  Widget _segment(BuildContext context, AppLocalizations l10n, String label, int count) {
    final dotColor = _dotColor(label);
    // FittedBox scale-down: at 360px each segment is ~78dp and the
    // 14sp Urdu "Maintenance (1)" label is wider — it shrinks
    // instead of overflowing (the 360px / 1.35x overflow test
    // covers this).
    final labelWidget = FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dotColor != null) ...[
            Container(width: 8, height: 8, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
            const SizedBox(width: 6),
          ],
          Text(
            l10n.fleetFilterChip(_filterLabel(l10n, label), count),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            // User layout 2026-11-16: 14sp segment labels. Set on
            // the Text itself so the chip's resolved label style
            // (theme: onSurface unselected, white selected) still
            // supplies the color and weight — no chipTheme override,
            // DS-1 intact.
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
    return Expanded(
      child: ChoiceChip(
        // E3 / accessibility: the padded tap target keeps every
        // segment at the 48dp minimum.
        materialTapTargetSize: MaterialTapTargetSize.padded,
        label: labelWidget,
        selected: selectedFilter == label,
        // Audit 2026-11-15 DS-1: no per-file selectedColor/labelStyle
        // — the theme's chipTheme is the one selected spec (navy fill
        // + white label).
        onSelected: (_) => onSelected(label),
      ),
    );
  }
}
