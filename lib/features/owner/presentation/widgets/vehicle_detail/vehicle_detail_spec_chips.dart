import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';

/// Phone-test build 81 (user feedback): the 5 car-feature spec chips
/// were plain text in a wrapping layout and read as the old design —
/// and their labels were grey (`labelMedium` carries the theme's grey
/// `onSurfaceVariant`). They are now ONE single row, each chip with
/// an icon, in the same icon language as the feature-actions row
/// below them.
///
/// The five chips never fit a 360px screen side by side (even at
/// 12sp), so the single row scrolls horizontally instead of wrapping
/// or shrinking the text — the app's established scrollable-chip-row
/// pattern (fleet quick actions, Shops filters). Labels stay 12sp
/// w500, maxLines 1 + ellipsis, with an explicit onSurface colour
/// (light + dark legs) so they are never grey again. All 5 features
/// stay, same data, no omissions.
///
/// Icons (built-in Material icons, no new assets):
/// * colour → palette, seats → airline seat, fuel → petrol pump,
///   transmission → gear, category → car.
class VehicleDetailSpecChips extends StatelessWidget {
  const VehicleDetailSpecChips({
    super.key,
    required this.colorLabel,
    required this.seatsLabel,
    required this.fuelLabel,
    required this.transmissionLabel,
    required this.categoryLabel,
  });

  final String colorLabel;
  final String seatsLabel;
  final String fuelLabel;
  final String transmissionLabel;
  final String categoryLabel;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final labelColor = brightness == Brightness.dark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight;
    final iconColor = AppColors.orangeTextFor(brightness);
    final labelStyle = Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w500, color: labelColor);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _chip(icon: Icons.palette_rounded, label: colorLabel, iconColor: iconColor, labelStyle: labelStyle),
          const SizedBox(width: 8),
          _chip(icon: Icons.airline_seat_recline_normal_rounded, label: seatsLabel, iconColor: iconColor, labelStyle: labelStyle),
          const SizedBox(width: 8),
          _chip(icon: Icons.local_gas_station_rounded, label: fuelLabel, iconColor: iconColor, labelStyle: labelStyle),
          const SizedBox(width: 8),
          _chip(icon: Icons.settings_rounded, label: transmissionLabel, iconColor: iconColor, labelStyle: labelStyle),
          const SizedBox(width: 8),
          _chip(icon: Icons.directions_car_rounded, label: categoryLabel, iconColor: iconColor, labelStyle: labelStyle),
        ],
      ),
    );
  }

  Widget _chip({required IconData icon, required String label, required Color iconColor, required TextStyle? labelStyle}) {
    return Chip(
      avatar: Icon(icon, size: 18, color: iconColor),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: labelStyle),
    );
  }
}
