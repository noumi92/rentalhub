import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/utils/responsive.dart';
import '../../../../core/utils/whatsapp.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../discovery/data/models/shop_model.dart';

/// The action buttons on the shop detail screen, extracted from
/// AdminShopDetailView so the view stays under the 250-line cap:
/// message the owner on WhatsApp, and suspend / lift suspension.
///
/// Mobile-first (2026-11-10): on a phone the two actions stack
/// full-width — side by side each is ~150dp and the labels clip at
/// large text scales. Both buttons are 48dp tall.
class ShopDetailActions extends StatelessWidget {
  const ShopDetailActions({
    super.key,
    required this.shop,
    required this.isWorking,
    required this.onToggleSuspend,
  });

  final ShopModel shop;
  final bool isWorking;
  final VoidCallback onToggleSuspend;

  @override
  Widget build(BuildContext context) {
    final compact =
        windowSizeClassOf(context) == WindowSizeClass.compact;
    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _messageOwnerButton(context),
          const SizedBox(height: 12),
          _suspendButton(context),
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: _messageOwnerButton(context)),
        const SizedBox(width: 12),
        Expanded(child: _suspendButton(context)),
      ],
    );
  }

  Widget _messageOwnerButton(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return OutlinedButton.icon(
      icon: const Icon(Icons.message_rounded, size: 18),
      label: Text(l10n.admin2_shopActionMessageOwner),
      style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
      onPressed: () async {
        final uri = whatsappUri(
          phone: shop.phoneNumber,
          message: l10n.admin2_shopActionHello(shop.shopName),
        );
        if (uri == null) {
          AppFeedback.showError(
              context, l10n.admin2_shopActionNoPhone);
          return;
        }
        // AD-m16: check the launch result — on web a failed wa.me
        // launch used to fail silently while the admin believed the
        // owner had been contacted.
        final opened =
            await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!opened && context.mounted) {
          AppFeedback.showError(
              context,
              AppLocalizations.of(context)?.admin2_whatsappOpenFailed ??
                  'Could not open WhatsApp.');
        }
      },
    );
  }

  Widget _suspendButton(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FilledButton(
      onPressed: isWorking ? null : onToggleSuspend,
      style: shop.suspended
          ? FilledButton.styleFrom(minimumSize: const Size(0, 48))
          : FilledButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              minimumSize: const Size(0, 48)),
      child: Text(isWorking
          ? l10n.admin2_saving
          : shop.suspended
              ? l10n.admin2_shopActionLift
              : l10n.admin2_shopActionSuspend),
    );
  }
}
