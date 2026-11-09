import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';

/// The mandatory rejection-reason dialog, shared by the requests list
/// and the requested detail (Phase B, D3): a rejection always carries
/// a reason — the customer sees it and knows what to fix. Returns the
/// trimmed reason, or null when the owner cancels / leaves it blank.
Future<String?> showRequestRejectDialog(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  final reasonController = TextEditingController();
  final reason = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.requestsRejectTitle),
      content: TextField(
        controller: reasonController,
        autofocus: true,
        maxLines: 3,
        decoration: InputDecoration(
          labelText: l10n.requestsRejectReasonLabel,
          hintText: l10n.requestsRejectReasonHint,
          border: const OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(dialogContext).pop(reasonController.text.trim()),
          child: Text(l10n.requestsRejectButton),
        ),
      ],
    ),
  );
  if (reason == null || reason.isEmpty) return null;
  return reason;
}
