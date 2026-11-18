import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../l10n/app_localizations.dart';

/// Compact orange "+ Add Vehicle" pill for the fleet header (user
/// layout, 2026-11-18): the extended FAB overlapped the third
/// vehicle card on a phone, so Add Vehicle moved into the AppBar as
/// a pill next to the Schedule icon. Same gated callback as the old
/// FAB — the caller wires [_openAddVehicle] (shop approval + plan
/// car cap) — and the same `fleet-action-add-vehicle` key + tooltip
/// so the fleet-tab tests keep addressing it. The "+" is the icon;
/// the label is the plain `fleetAddVehicle` text, so exact-text
/// finders still match.
///
/// White icon + label on orangeFill #C2410C (5.18:1) — the same
/// fill the old FAB used. Compact (40 dp tall, 8 dp side padding,
/// 16 dp icon, 11 sp label) so title + pill + calendar icon fit
/// inside 360 px — the roomier first version overflowed by 3.5 px
/// there (covered by the fleet header overflow test).
class FleetAddVehiclePill extends StatelessWidget {
  final VoidCallback onPressed;

  const FleetAddVehiclePill({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Tooltip(
      message: l10n.fleetAddVehicle,
      child: SizedBox(
        height: 40,
        child: Material(
          color: AppColors.orangeFill,
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: const Key('fleet-action-add-vehicle'),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add_rounded, size: 16, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    l10n.fleetAddVehicle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
