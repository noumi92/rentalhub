import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/money_format.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../fleet/domain/entities/vehicle_entity.dart';

/// Audit §5 (O10/P4-O06): the published-confirmation screen shown
/// after a car is saved. RQ-F1 (2026-11-13): the "View in App" /
/// "Copy Link" / "Share Listing" actions are HIDDEN until the public
/// listing landing page exists — the link below is the agreed public
/// URL shape, not a live page, so no dead link is handed to the owner.
/// Restore the three actions (copy/share helpers live in git history)
/// once the landing page is live.
class OwnerVehiclePublishedView extends StatelessWidget {
  final VehicleEntity vehicle;
  final VoidCallback? onBack;

  const OwnerVehiclePublishedView({
    super.key,
    required this.vehicle,
    this.onBack,
  });

  /// The public listing link. The web page behind it does not exist
  /// yet — see the class doc.
  static String listingLink(String vehicleId) =>
      'https://rentalhub.62onlinestore.com/vehicle/$vehicleId';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final link = listingLink(vehicle.vehicleId);
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            MinimalAppBar(
              title: l10n.vehiclePublishedTitle,
              onBack: onBack ?? () => context.pop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: AppColors.successContainerFor(Theme.of(context).brightness),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(Icons.check_circle_rounded, size: 64, color: AppColors.successOnContainerFor(Theme.of(context).brightness)),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      l10n.vehiclePublishedHeading(vehicle.displayName),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.fleetDailyRate(formatRs(vehicle.rates.daily24)),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      vehicle.plateNumber,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Theme.of(context).dividerColor),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.link_rounded, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(link, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.labelMedium),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // RQ-F1: the listing actions (View in App / Copy
                    // Link / Share Listing) are hidden until the
                    // public landing page exists. The note below says
                    // so honestly instead of offering a dead link.
                    Text(
                      l10n.shareLinkNote,
                      style: Theme.of(context).textTheme.labelSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    // Audit §5 finish (P4-O06): open the full share
                    // screen (pick a price, then share or copy) — its
                    // own share/copy actions are likewise disabled
                    // until the landing page exists (RQ-F1).
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => context.push(RouteNames.ownerShareWithCustomers.replaceFirst(':vehicleId', vehicle.vehicleId)),
                        icon: const Icon(Icons.group_rounded, size: 18),
                        label: Text(l10n.shareTitle),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () => context.push(RouteNames.ownerAddVehicle),
                      icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                      label: Text(l10n.vehiclePublishedAddAnother),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
