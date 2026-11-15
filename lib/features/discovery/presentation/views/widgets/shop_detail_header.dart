import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/utils/whatsapp.dart';
import '../../../../../core/widgets/app_feedback.dart';
import '../../../domain/entities/shop_entity.dart';
import '../../../../../l10n/app_localizations.dart';

/// Team B (UI/UX audit 2026-11-15, PW-7): the shop detail header —
/// the shop's real photo when one exists (never a stock banner
/// presented as the showroom), the real rating when one is stored,
/// and the Call / WhatsApp actions the list card has (same real
/// `tel:` / `wa.me` launches, same disabled-with-tooltip state when
/// the shop has no phone number). No trip count exists on
/// [ShopEntity], so none is shown — never invented.
class ShopDetailHeader extends StatelessWidget {
  const ShopDetailHeader({
    super.key,
    required this.shop,
    this.onCall,
    this.onWhatsApp,
  });

  final ShopEntity shop;
  final VoidCallback? onCall;
  final VoidCallback? onWhatsApp;

  Future<void> _call(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final digits = shop.phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri(scheme: 'tel', path: digits);
    if (!await launchUrl(uri)) {
      if (context.mounted) {
        AppFeedback.showError(context, l10n.couldNotOpenDialer);
      }
    }
  }

  Future<void> _whatsApp(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final uri = whatsappUri(
      phone: shop.phoneNumber,
      message: l10n.shopWhatsappHello(shop.shopName),
    );
    if (uri == null) {
      AppFeedback.showInfo(context, l10n.shopNoPhoneNumber);
      return;
    }
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        AppFeedback.showError(context, l10n.couldNotOpenWhatsapp);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasPhone = shop.phoneNumber.trim().isNotEmpty;
    final photoUrl = shop.headerUrl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (photoUrl != null && photoUrl.startsWith('http'))
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(20)),
            child: Image.network(
              photoUrl,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 180,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Center(
                  child: Icon(Icons.storefront_rounded, size: 48),
                ),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              if (shop.hasRealRating) ...[
                Icon(
                  Icons.star_rounded,
                  size: 18,
                  color: AppColors.warningTextFor(
                      Theme.of(context).brightness),
                ),
                const SizedBox(width: 4),
                Text(
                  shop.rating.toStringAsFixed(1),
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: Tooltip(
                  message: hasPhone ? l10n.call : l10n.shopNoPhoneNumber,
                  child: FilledButton.icon(
                    onPressed: hasPhone
                        ? (onCall ?? () => _call(context))
                        : null,
                    icon: const Icon(Icons.call_rounded, size: 18),
                    label: Text(l10n.call),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 48),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Tooltip(
                  message:
                      hasPhone ? l10n.whatsapp : l10n.shopNoPhoneNumber,
                  child: OutlinedButton.icon(
                    onPressed: hasPhone
                        ? (onWhatsApp ?? () => _whatsApp(context))
                        : null,
                    icon: Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 18,
                      color: AppColors.successTextFor(
                          Theme.of(context).brightness),
                    ),
                    label: Text(l10n.whatsapp),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
