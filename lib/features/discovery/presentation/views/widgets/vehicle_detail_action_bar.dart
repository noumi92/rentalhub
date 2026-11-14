import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/routing/auth_route_guard.dart';
import '../../../../../core/routing/route_names.dart';
import '../../../../../core/utils/current_shop.dart';
import '../../../../../core/utils/whatsapp.dart';
import '../../../../../core/widgets/app_feedback.dart';
import '../../../../../core/widgets/debounced_button.dart';
import '../../../../fleet/domain/entities/vehicle_entity.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../core/utils/money_format.dart';

/// Phase A (A1): the bottom action bar of the car detail screen —
/// WhatsApp the shop + Book Now — extracted so the view stays under the
/// 250-line cap.
class VehicleDetailActionBar extends StatelessWidget {
  const VehicleDetailActionBar({
    super.key,
    required this.vehicle,
    required this.shopName,
    required this.shopPhone,
    this.shopOwnerId = '',
    required this.selectedRate,
    required this.withDriver,
    this.onBookNow,
  });

  final VehicleEntity vehicle;
  final String shopName;
  final String shopPhone;

  /// The shop document's `owner_id` ('' when unknown). New cars carry
  /// the shop DOCUMENT id as `shopId`, so the owner's UID no longer
  /// matches it — the owner is recognised by the shop's owner id
  /// instead (the direct `shopId` match is kept for legacy cars, whose
  /// shop has no `owner_id`).
  final String shopOwnerId;
  final int selectedRate;
  final bool withDriver;
  final VoidCallback? onBookNow;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final v = vehicle;
    // Fleet-card tap (integration, audit §4): the owner reaches this
    // customer detail screen from the fleet tab. An owner looking at
    // their own car gets "Manage rates" (→ the owner rate matrix)
    // instead of "Book Now"; everyone else keeps the booking CTA.
    // Default deny: locked role must be 'owner' AND the signed-in uid
    // must own the shop — either the vehicle's shop id (legacy cars,
    // written under the UID) or the shop's `owner_id` (new cars carry
    // the shop DOCUMENT id as `shopId`).
    final isOwnVehicle = AuthRouteGuard.lockedRole == 'owner' &&
        (currentShopId() == v.shopId ||
            (shopOwnerId.isNotEmpty && currentShopId() == shopOwnerId));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
              // Theme shadow colour — no raw hex literal.
              color: Theme.of(context).shadowColor,
              blurRadius: 10,
              offset: const Offset(0, -3))
        ],
      ),
      child: Row(
        children: [
          Flexible(
            child: OutlinedButton.icon(
              onPressed: () async {
                final uri = whatsappUri(
                  phone: shopPhone,
                  message: l10n.vehicleWhatsappInterest(shopName, v.displayName, v.plateNumber),
                );
                if (uri == null) {
                  AppFeedback.showInfo(
                    context,
                    l10n.shopNoWhatsapp,
                  );
                  return;
                }
                if (!await launchUrl(
                  uri,
                  mode: LaunchMode.externalApplication,
                )) {
                  if (context.mounted) {
                    AppFeedback.showError(
                      context,
                      l10n.couldNotOpenWhatsapp,
                    );
                  }
                }
              },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.successOnContainerFor(Theme.of(context).brightness),
              side: BorderSide(color: AppColors.successBorderFor(Theme.of(context).brightness)),
              backgroundColor: AppColors.successContainerFor(Theme.of(context).brightness),
              // 48dp minimum touch target; the label ellipsizes
              // instead of squeezing the Book Now button off-screen
              // at 360px / large text scale.
              minimumSize: const Size(0, 48),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            icon: Icon(Icons.chat_bubble_outline_rounded,
                size: 18, color: AppColors.successOnContainerFor(Theme.of(context).brightness)),
            label: Text(
              l10n.whatsapp,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: isOwnVehicle
                ? DebouncedButton(
                    text: l10n.vehicleManageRates,
                    icon: Icons.tune_rounded,
                    onPressed: () => context.push(
                      RouteNames.ownerRatesVehicle
                          .replaceFirst(':vehicleId', v.vehicleId),
                    ),
                  )
                : DebouncedButton(
                    text: l10n.bookNowWithRate(formatRs(selectedRate)),
                    icon: Icons.check_circle_outline_rounded,
                    onPressed: () async {
                      if (onBookNow != null) {
                        onBookNow!.call();
                      } else {
                        AppFeedback.showInfo(
                          context,
                          l10n.vehicleSelectedMode(withDriver
                              ? l10n.withChauffeur
                              : l10n.selfDriveHyphen),
                        );
                      }
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
