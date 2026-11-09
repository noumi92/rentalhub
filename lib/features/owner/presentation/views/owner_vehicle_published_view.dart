import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/money_format.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../fleet/domain/entities/vehicle_entity.dart';

/// Audit §5 (O10/P4-O06): the published-confirmation screen shown
/// after a car is saved. "View in App" opens the owner vehicle
/// detail; "Copy Link" copies the public listing link; "Share Listing"
/// shares it via the OS sheet. NOTE: no web landing page exists for
/// the link yet — it is the agreed public URL shape, not a live page.
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

  Future<void> _copyLink(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    await Clipboard.setData(ClipboardData(text: listingLink(vehicle.vehicleId)));
    if (context.mounted) {
      AppFeedback.showSuccess(context, l10n.vehiclePublishedLinkCopied);
    }
  }

  Future<void> _shareListing(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final link = listingLink(vehicle.vehicleId);
    await SharePlus.instance.share(
      ShareParams(
        text: l10n.vehiclePublishedShareText(vehicle.displayName, l10n.amountRs(formatRs(vehicle.rates.daily24)), link),
      ),
    );
  }

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
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.fleetDailyRate(formatRs(vehicle.rates.daily24)),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
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
                    DebouncedButton(
                      text: l10n.vehiclePublishedViewInApp,
                      icon: Icons.visibility_rounded,
                      onPressed: () async => context.push(RouteNames.ownerVehicleDetail.replaceFirst(':id', vehicle.vehicleId)),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _copyLink(context),
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        label: Text(l10n.vehiclePublishedCopyLink),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _shareListing(context),
                        icon: const Icon(Icons.share_rounded, size: 18),
                        label: Text(l10n.vehiclePublishedShareListing),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Audit §5 finish (P4-O06): open the full share
                    // screen (pick a price, then share or copy).
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
