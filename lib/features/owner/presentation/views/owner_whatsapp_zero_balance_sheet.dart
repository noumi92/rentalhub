import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/whatsapp.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../l10n/app_localizations.dart';

/// W6 — zero-balance fallback sheet + amber banner (deck p.19
/// screen 6).
///
/// The sheet is shown when an auto-message could not be sent because
/// the balance is 0. "Buy credits" goes to W2; "Send via my WhatsApp"
/// opens the owner's own WhatsApp with the real message prefilled
/// (the manual wa.me pattern, not an automated dispatch).
///
/// The banner appears ONLY when a real auto-message was skipped for
/// zero balance: `WhatsappZeroBalanceBanner.shouldShow` is true when
/// the real balance is 0 AND `whatsapp_skipped_messages` holds at
/// least one `zero_balance` row for the shop. Nothing writes that
/// collection before D2, so the banner cannot trigger yet — that is
/// honest, not a missing feature.
///
/// Mount point (integration wires it; this file only owns the
/// widgets): the Requests view (`owner_booking_requests_view.dart`,
/// worker B owns it) — above the triage list, where the skipped
/// pickup reminder belongs.
class WhatsappZeroBalanceBanner extends StatelessWidget {
  final int skippedCount;

  const WhatsappZeroBalanceBanner({super.key, required this.skippedCount});

  static bool shouldShow({
    required int balance,
    required int skippedCount,
  }) =>
      balance == 0 && skippedCount > 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        // OW-m39: brightness-aware warning tokens — the amber
        // shade was unreadable in dark mode.
        color: AppColors.warningContainerFor(Theme.of(context).brightness),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.warningOnContainerFor(Theme.of(context).brightness)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(l10n.creditsZeroBanner,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.warningOnContainerFor(Theme.of(context).brightness))),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
              '${l10n.creditsZeroBannerNote} · $skippedCount',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.warningOnContainerFor(Theme.of(context).brightness))),
        ],
      ),
    );
  }
}

class ZeroBalanceSheet {
  ZeroBalanceSheet._();

  /// Shows the fallback sheet for one real skipped message.
  /// [messagePreview] is the exact message that was not sent;
  /// [customerPhone] is the recipient's real number (wa.me is
  /// disabled with an honest message when it is empty).
  static Future<void> show(
    BuildContext context, {
    required String messagePreview,
    required String customerPhone,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.creditsZeroTitle,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(l10n.creditsZeroBody,
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10)),
              child: Text(messagePreview,
                  style: Theme.of(context).textTheme.bodySmall),
            ),
            const SizedBox(height: 8),
            Text(l10n.creditsViaWhatsappNote,
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.chat_rounded),
                label: Text(l10n.creditsSendViaWhatsapp),
                onPressed: () async {
                  final uri = whatsappUri(
                      phone: customerPhone, message: messagePreview);
                  if (uri == null) {
                    AppFeedback.showError(
                        context, l10n.creditsSendTestDisabled);
                    return;
                  }
                  Navigator.pop(ctx);
                  await launchUrl(uri,
                      mode: LaunchMode.externalApplication);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
