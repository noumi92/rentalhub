import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/utils/money_format.dart';
import '../../../../../core/utils/whatsapp.dart';
import '../../../../../core/widgets/app_feedback.dart';
import '../../../../../core/widgets/verified_badge.dart';
import '../../../domain/entities/shop_entity.dart';
import '../../../../../l10n/app_localizations.dart';
import 'shops_filter_logic.dart';

class ShopListCard extends StatelessWidget {
  final ShopEntity shop;
  final VoidCallback onTap;
  final VoidCallback? onCall;
  final VoidCallback? onWhatsApp;

  /// PW-4: cheapest available daily rate for this shop (min over
  /// its available cars' `rates.daily24`). Null hides the price
  /// line — a price is never invented.
  final int? minDailyRate;

  const ShopListCard({
    super.key,
    required this.shop,
    required this.onTap,
    this.onCall,
    this.onWhatsApp,
    this.minDailyRate,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // CU-C1: the call/WhatsApp buttons dial for real — the old code
    // only showed a SnackBar. Without a phone number both buttons
    // are disabled with a tooltip explaining why.
    final hasPhone = shop.phoneNumber.trim().isNotEmpty;
    // FG-21: the shop's real header photo when one exists, else a
    // neutral surface + storefront icon — never a stock banner
    // presented as the showroom.
    final headerUrl = shop.headerUrl?.trim() ?? '';
    Widget neutralBanner() => Container(height: 135, color: Theme.of(context).colorScheme.surfaceContainerHighest, child: const Center(child: Icon(Icons.storefront_rounded, size: 48)));

    // BP-13: no bottom margin on the card — the list separates
    // items with spacing between them only, so the last item sits
    // at the list padding instead of margin + padding.
    return Card(
      margin: EdgeInsets.zero,
      elevation: 2.5,
      clipBehavior: Clip.antiAlias,
      // CU-M2: cards carry no dark border — the shadow does the work.
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Showroom photo (real header photo, or neutral).
            Stack(
              children: [
                if (headerUrl.isNotEmpty)
                  Image.network(
                    headerUrl,
                    height: 135,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => neutralBanner(),
                  )
                else
                  neutralBanner(),
                // Distance badge — only when the distance is real (never the 1.2 km fallback).
                if (shop.hasRealDistance)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on_rounded, size: 13, color: AppColors.secondary),
                          const SizedBox(width: 3),
                          Text(
                            '${shop.distanceKm.toStringAsFixed(1)} km',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w500, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            // 2. Showroom Metadata & Status
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Verified Badge Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          shop.shopName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Shops tab: every shop states its verification
                      // plainly — "Verified" for verified shops, an
                      // explicit "Unverified" label for the rest
                      // (the badge's own fallback reads "Pending
                      // Review", which is not the same claim). The
                      // badge caps at 180 dp so a long Urdu label at
                      // large text scales ellipsizes inside the badge
                      // instead of overflowing the title row.
                      ConstrainedBox(
                        constraints:
                            const BoxConstraints(maxWidth: 180),
                        child: VerifiedBadge(
                          isVerified: isShopVerified(shop),
                          label: isShopVerified(shop)
                              ? null
                              : l10n.shops_unverified,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),

                  // Rating / cars: a number the shop document never stored is hidden, never shown with the display-only fallback (4.9 / 8 cars).
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Star Rating
                      if (shop.hasRealRating)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, size: 16, color: AppColors.warning),
                            const SizedBox(width: 3),
                            Text(
                              shop.rating.toStringAsFixed(1),
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      if (shop.hasRealRating)
                        Text('•', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      Text(
                        shop.city.isEmpty ? shop.address : '${shop.address}, ${shop.city}',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      if (shop.hasRealAvailableCount)
                        Text('•', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      if (shop.hasRealAvailableCount)
                        Text(
                          l10n.shopCarsAvailable(shop.availableCount),
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w500, color: AppColors.successOnContainerFor(Theme.of(context).brightness)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // PW-4: "from Rs. X/day" — the cheapest available
                  // car, so shops can be compared from the listing.
                  if (minDailyRate != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(l10n.shopFromPerDay(l10n.amountRs(formatRs(minDailyRate!))), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    ),

                  // 3. Action Bar: Call, WhatsApp, View Fleet
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    alignment: WrapAlignment.spaceBetween,
                    children: [
                      // Direct Phone Call Button — dials the shop's
                      // real number (CU-C1); disabled when there is
                      // none, with a tooltip saying so.
                      _CallButton(
                        enabled: hasPhone,
                        noPhoneMessage: l10n.shopNoPhoneNumber,
                        onPressed: onCall ??
                            () async {
                              final digits = shop.phoneNumber
                                  .replaceAll(RegExp(r'[^0-9+]'), '');
                              final uri =
                                  Uri(scheme: 'tel', path: digits);
                              if (!await launchUrl(uri)) {
                                if (context.mounted) {
                                  AppFeedback.showError(
                                    context,
                                    l10n.couldNotOpenDialer,
                                  );
                                }
                              }
                            },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.call_rounded, size: 16),
                            const SizedBox(width: 6),
                            Text(l10n.call),
                          ],
                        ),
                      ),

                      // Direct WhatsApp Chat Button — opens a real
                      // wa.me chat (CU-C1); disabled when there is
                      // no number.
                      _CallButton(
                        enabled: hasPhone,
                        noPhoneMessage: l10n.shopNoPhoneNumber,
                        onPressed: onWhatsApp ??
                            () async {
                              final uri = whatsappUri(
                                phone: shop.phoneNumber,
                                message: l10n
                                    .shopWhatsappHello(shop.shopName),
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
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.chat_bubble_outline_rounded,
                                size: 16,
                                color: AppColors.successOnContainerFor(
                                    Theme.of(context).brightness)),
                            const SizedBox(width: 6),
                            Text(l10n.whatsapp),
                          ],
                        ),
                      ),

                      // View Showroom Fleet CTA
                      ElevatedButton(
                        onPressed: onTap,
                        style: ElevatedButton.styleFrom(
                          // CU-M1: white on AppColors.secondary is
                          // 3.29:1 — orangeFill is 5.18:1.
                          backgroundColor: AppColors.orangeFill,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 13, vertical: 12),
                          minimumSize: const Size(0, 48),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                l10n.viewFleet,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward_rounded, size: 13),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// CU-C1 / CU-M3: a call/WhatsApp button with a 48dp minimum tap
/// target. When [enabled] is false (the shop has no phone number)
/// the button is disabled and wrapped in a tooltip explaining why —
/// it never pretends to work.
class _CallButton extends StatelessWidget {
  const _CallButton({
    required this.enabled,
    required this.noPhoneMessage,
    required this.onPressed,
    required this.child,
    this.isWhatsApp = false,
  });

  final bool enabled;
  final String noPhoneMessage;
  final VoidCallback? onPressed;
  final Widget child;
  final bool isWhatsApp;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final button = OutlinedButton(
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: child,
    );
    if (enabled) return button;
    return Tooltip(message: noPhoneMessage, child: button);
  }
}
