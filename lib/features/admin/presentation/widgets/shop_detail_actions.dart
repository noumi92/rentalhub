import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/utils/responsive.dart';
import '../../../../core/utils/whatsapp.dart';
import '../../../../core/widgets/app_feedback.dart';
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
          _suspendButton(),
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: _messageOwnerButton(context)),
        const SizedBox(width: 12),
        Expanded(child: _suspendButton()),
      ],
    );
  }

  Widget _messageOwnerButton(BuildContext context) {
    return OutlinedButton.icon(
      icon: const Icon(Icons.message_rounded, size: 18),
      label: const Text('Message owner'),
      style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
      onPressed: () async {
        final uri = whatsappUri(
          phone: shop.phoneNumber,
          message: 'Hello from RentalHub admin regarding ${shop.shopName}.',
        );
        if (uri == null) {
          AppFeedback.showError(
              context, 'No phone number on file for this shop.');
          return;
        }
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      },
    );
  }

  Widget _suspendButton() {
    return FilledButton(
      onPressed: isWorking ? null : onToggleSuspend,
      style: shop.suspended
          ? FilledButton.styleFrom(minimumSize: const Size(0, 48))
          : FilledButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              minimumSize: const Size(0, 48)),
      child: Text(isWorking
          ? 'Saving…'
          : shop.suspended
              ? 'Lift suspension'
              : 'Suspend shop'),
    );
  }
}
