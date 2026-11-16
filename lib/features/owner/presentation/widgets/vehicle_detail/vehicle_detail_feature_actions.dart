import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../l10n/app_localizations.dart';

/// Vehicle-detail feature actions (phone-test build 80): Booking
/// calendar, Edit Vehicle and Manage rates in ONE row of
/// icon-over-label tiles below the spec chips. They used to be split
/// — calendar + Edit in a 2-button row here, Manage rates as a pill
/// in the Rates & Pricing header. Nothing is dropped: the same three
/// callbacks, the same destinations, the same labels (all existing
/// .arb keys). Edit stays the filled primary (white icon + label on
/// orangeFill #C2410C, 5.18:1); the other two keep the pale orange
/// tile with the orange icon and the dark onSurface label from the
/// fleet-card readability fix (16.38:1 light, 14.77:1 dark — never
/// small orange text on the pale tint).
///
/// Fit at 360 px in English and Urdu: each tile is Expanded, the
/// icon sits above the label, and the label is 12sp semibold with
/// maxLines 2 + ellipsis, so the long Urdu labels wrap instead of
/// overflowing. Every tile is tappable over its full area (well
/// above the 48 dp minimum touch target).
class VehicleDetailFeatureActions extends StatelessWidget {
  final VoidCallback onCalendar;
  final VoidCallback onEdit;
  final VoidCallback onManageRates;

  const VehicleDetailFeatureActions({
    super.key,
    required this.onCalendar,
    required this.onEdit,
    required this.onManageRates,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(child: _tile(context, icon: Icons.calendar_month_rounded, label: l10n.vehicleDetailCalendar, onPressed: onCalendar)),
        const SizedBox(width: 8),
        Expanded(child: _tile(context, icon: Icons.edit_rounded, label: l10n.vehicleDetailEditVehicle, onPressed: onEdit, filled: true)),
        const SizedBox(width: 8),
        Expanded(child: _tile(context, icon: Icons.tune_rounded, label: l10n.vehicleDetailManageRates, onPressed: onManageRates)),
      ],
    );
  }

  Widget _tile(BuildContext context, {required IconData icon, required String label, required VoidCallback onPressed, bool filled = false}) {
    final brightness = Theme.of(context).brightness;
    final background = filled ? AppColors.orangeFill : AppColors.orangeContainerFor(brightness);
    final iconColor = filled ? Colors.white : AppColors.orangeTextFor(brightness);
    final labelColor = filled ? Colors.white : (brightness == Brightness.dark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight);
    return Tooltip(
      message: label,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 22, color: iconColor),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600, color: labelColor),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
