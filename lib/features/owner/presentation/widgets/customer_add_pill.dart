import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../l10n/app_localizations.dart';

/// Compact orange "+ Add Customer" pill for the customers app bar
/// (Item 5, 2026-11-21): the extended FAB overlapped the list on a
/// phone, so Add Customer moved into the AppBar — the same pattern
/// as the fleet header's "+ Add Vehicle" pill ([FleetAddVehiclePill]).
/// Same destination ('/owner/customers/add', wired by the caller),
/// same `customers-action-add` key + tooltip so tests keep
/// addressing it. The "+" is the icon; the label is the plain
/// `addCustomerTitle` text, so exact-text finders still match.
///
/// White icon + label on orangeFill #C2410C (5.18:1) — the same
/// fill the old FAB used. Compact (40 dp tall, 8 dp side padding,
/// 16 dp icon, 11 sp label) so title + pill + scan icon fit
/// inside 360 px (the fleet pill's first roomier version overflowed
/// there).
///
/// E3: the label's text scaling is capped at 1.5x — at 200% the
/// unclamped label makes the pill ~306 px wide and the app-bar Row
/// overflows by 26 px at 360 px (the scan icon sits beside the
/// pill, unlike the fleet header's pill-only bar). Capped, the full
/// label still renders large and the tooltip carries the full text;
/// below 1.5x nothing changes.
class CustomerAddPill extends StatelessWidget {
  final VoidCallback onPressed;

  const CustomerAddPill({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Tooltip(
      message: l10n.addCustomerTitle,
      child: MediaQuery.withClampedTextScaling(
        minScaleFactor: 0,
        maxScaleFactor: 1.5,
        child: SizedBox(
          height: 40,
          child: Material(
            color: AppColors.orangeFill,
            borderRadius: BorderRadius.circular(20),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              key: const Key('customers-action-add'),
              onTap: onPressed,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_rounded, size: 16, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      l10n.addCustomerTitle,
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
      ),
    );
  }
}
