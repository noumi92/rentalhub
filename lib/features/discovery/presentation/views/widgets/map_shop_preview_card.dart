import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/utils/whatsapp.dart';
import '../../../../../core/widgets/app_feedback.dart';
import '../../../../../core/widgets/verified_badge.dart';
import '../../../domain/entities/shop_entity.dart';
import '../../../../../l10n/app_localizations.dart';
import 'shop_placeholder_image.dart';
import 'shops_filter_logic.dart';

class MapShopPreviewCard extends StatelessWidget {
  final ShopEntity shop;
  final VoidCallback onViewShowroom;

  const MapShopPreviewCard({
    super.key,
    required this.shop,
    required this.onViewShowroom,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // CU-C1: same real dial/WhatsApp handlers as the shop list card
    // — the old SnackBars never opened anything. Disabled with a
    // tooltip when the shop has no phone number.
    final hasPhone = shop.phoneNumber.trim().isNotEmpty;
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Card(
        elevation: 6,
        // CU-M2: cards carry no dark border.
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Customer pass (2026-11-16): the generic showroom
                  // placeholder thumbnail instead of the dull grey
                  // storefront-icon box.
                  const ClipRRect(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    child: ShopPlaceholderImage(height: 44, width: 44),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shop.shopName,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          // Admin-integration audit (2026-11-10):
                          // the distance is shown only when real —
                          // the 1.2 km fallback is never displayed.
                          shop.hasRealDistance
                              ? l10n.mapShopDistance(shop.address, shop.distanceKm)
                              : shop.address,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  // Shops tab: every shop states its verification
                  // plainly — "Verified" for verified shops, an
                  // explicit "Unverified" label for the rest.
                  VerifiedBadge(
                    isVerified: isShopVerified(shop),
                    label: isShopVerified(shop)
                        ? null
                        : l10n.shops_unverified,
                  ),
                  const SizedBox(width: 8),
                  // Admin-integration audit (2026-11-10): numbers the
                  // shop document never stored are hidden, never shown
                  // with the display-only fallback (4.9 / 8 cars).
                  if (shop.hasRealRating)
                    Text(
                      l10n.shopRatingLabel(shop.rating),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w500),
                    ),
                  if (shop.hasRealRating && shop.hasRealAvailableCount)
                    const SizedBox(width: 8),
                  if (shop.hasRealAvailableCount)
                    Text(
                      l10n.shopCarsReady(shop.availableCount),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w500, color: AppColors.successTextFor(Theme.of(context).brightness)),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  // CU-C1: dials the shop's real number; disabled
                  // with a tooltip when there is none.
                  _MapPreviewButton(
                    enabled: hasPhone,
                    noPhoneMessage: l10n.shopNoPhoneNumber,
                    onPressed: () async {
                      final digits = shop.phoneNumber
                          .replaceAll(RegExp(r'[^0-9+]'), '');
                      final uri = Uri(scheme: 'tel', path: digits);
                      if (!await launchUrl(uri)) {
                        if (context.mounted) {
                          AppFeedback.showError(
                            context,
                            l10n.couldNotOpenDialer,
                          );
                        }
                      }
                    },
                    isWhatsApp: false,
                    icon: const Icon(Icons.call_rounded, size: 16),
                    label: l10n.call,
                  ),
                  // CU-C1: opens a real wa.me chat; disabled when
                  // there is no number.
                  _MapPreviewButton(
                    enabled: hasPhone,
                    noPhoneMessage: l10n.shopNoPhoneNumber,
                    onPressed: () async {
                      final uri = whatsappUri(
                        phone: shop.phoneNumber,
                        message: l10n.shopWhatsappHello(shop.shopName),
                      );
                      if (uri == null) {
                        AppFeedback.showInfo(
                          context,
                          l10n.shopNoPhoneNumber,
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
                    isWhatsApp: true,
                    icon: Icon(Icons.chat_bubble_outline_rounded,
                        size: 16,
                        color: AppColors.successOnContainerFor(
                            Theme.of(context).brightness)),
                    label: l10n.whatsapp,
                  ),
                  ElevatedButton.icon(
                    onPressed: onViewShowroom,
                    style: ElevatedButton.styleFrom(
                      // CU-M1: white on AppColors.secondary is 3.29:1
                      // — orangeFill is 5.18:1.
                      backgroundColor: AppColors.orangeFill,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.directions_car_rounded, size: 14),
                    label: Text(l10n.viewFleet),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// CU-C1 / CU-M3: a 48dp-minimum call/WhatsApp button for the map
/// preview. Disabled + tooltip when the shop has no phone number.
class _MapPreviewButton extends StatelessWidget {
  const _MapPreviewButton({
    required this.enabled,
    required this.noPhoneMessage,
    required this.onPressed,
    required this.isWhatsApp,
    required this.icon,
    required this.label,
  });

  final bool enabled;
  final String noPhoneMessage;
  final VoidCallback onPressed;
  final bool isWhatsApp;
  final Widget icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final button = OutlinedButton.icon(
      onPressed: enabled ? onPressed : null,
      style: OutlinedButton.styleFrom(
        foregroundColor: isWhatsApp
            ? AppColors.successOnContainerFor(brightness)
            : Theme.of(context).colorScheme.onSurface,
        side: BorderSide(
            color: isWhatsApp
                ? AppColors.successBorderFor(brightness)
                : Theme.of(context).dividerColor),
        backgroundColor:
            isWhatsApp ? AppColors.successContainerFor(brightness) : null,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      icon: icon,
      label: Text(label),
    );
    if (enabled) return button;
    return Tooltip(message: noPhoneMessage, child: button);
  }
}
