import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';

/// Team B (UI/UX audit 2026-11-15, PW-18): the payment-proof
/// rejection dialog, extracted from [OwnerPaymentVerificationView]
/// so the view stays under the 250-line cap. Returns the trimmed
/// rejection reason, or null when the owner cancels. A rejection
/// always carries a reason — the customer sees it and knows what to
/// fix and resubmit.
Future<String?> showPaymentRejectDialog(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  final reasonController = TextEditingController();
  final reason = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.paymentVerificationRejectTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.paymentVerificationRejectNote),
          const SizedBox(height: 12),
          TextField(
            controller: reasonController,
            autofocus: true,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: l10n.paymentVerificationReasonLabel,
              hintText: l10n.paymentVerificationReasonHint,
              // OW-m29: 16 dp, same as every other dialog field.
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(dialogContext).pop(reasonController.text.trim()),
          child: Text(l10n.paymentVerificationRejectButton),
        ),
      ],
    ),
  );
  return reason;
}
