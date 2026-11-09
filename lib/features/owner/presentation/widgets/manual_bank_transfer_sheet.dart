import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../core/utils/money_format.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/debounced_button.dart';

/// Shared manual bank-transfer sheet — the ONLY payment path for
/// subscriptions (S1–S3) and WhatsApp credit packs (W2) until the
/// Play Console (D1) and Meta/WhatsApp (D2) gates are done.
///
/// The owner transfers to the RentalHub Meezan account and submits the
/// bank transaction ID; an admin verifies it and the request flips to
/// approved. No card is ever charged here and no payment method is
/// collected. Callers pass [onSubmit], which performs their own
/// collection write (`subscription_requests` or
/// `credit_purchase_requests`).
class ManualBankTransferSheet {
  ManualBankTransferSheet._();

  static Future<void> show(
    BuildContext context, {
    required String title,
    required int amount,
    String? note,
    required Future<void> Function(String transactionId) onSubmit,
    required VoidCallback onSubmitted,
  }) async {
    final trxIdController = TextEditingController();
    var isSubmitting = false;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(title,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900)),
                  ),
                  IconButton(
                      tooltip: AppLocalizations.of(ctx)?.subscriptionClose ??
                          'Close',
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                  AppLocalizations.of(ctx)!.amountRs(formatRs(amount)),
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w900)),
              if (note != null) ...[
                const SizedBox(height: 8),
                Text(note, style: Theme.of(context).textTheme.bodySmall),
              ],
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bank: Meezan Bank Ltd.',
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    Text('Title: RentalHub Pakistan PVT Ltd.',
                        style: Theme.of(context).textTheme.bodySmall),
                    // Still hardcoded — no bank-details field exists
                    // in `platform_settings/global`.
                    Text('IBAN: PK64MEZN0001234567890123',
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: trxIdController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(ctx)!.subscriptionTrxLabel,
                  hintText: AppLocalizations.of(ctx)!.subscriptionTrxHint,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 12),
                ),
              ),
              const SizedBox(height: 16),
              DebouncedButton(
                text: AppLocalizations.of(ctx)!.subscriptionSubmit,
                icon: Icons.check_circle_rounded,
                isLoading: isSubmitting,
                onPressed: () async {
                  if (trxIdController.text.trim().isEmpty) {
                    AppFeedback.showError(
                        ctx,
                        AppLocalizations.of(ctx)!.subscriptionEnterTrx);
                    return;
                  }
                  setModalState(() => isSubmitting = true);
                  try {
                    await onSubmit(trxIdController.text.trim());
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    onSubmitted();
                  } catch (_) {
                    if (ctx.mounted) {
                      AppFeedback.showError(
                          ctx,
                          AppLocalizations.of(ctx)!.shopSaveError);
                    }
                  } finally {
                    if (ctx.mounted) setModalState(() => isSubmitting = false);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
    trxIdController.dispose();
  }
}
