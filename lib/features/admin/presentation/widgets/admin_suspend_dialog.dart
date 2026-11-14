import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// The suspend / unsuspend dialog for a shop: asks for the reason
/// (stored on the shop doc and in the audit log) and returns it, or
/// null when the admin cancels.
Future<String?> showSuspendDialog(
  BuildContext context, {
  required bool suspend,
}) async {
  final reasonController = TextEditingController();
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(suspend ? AppLocalizations.of(ctx)!.admin2_suspendTitle : AppLocalizations.of(ctx)!.admin2_suspendLiftTitle),
      content: TextField(
        controller: reasonController,
        // AD-m21: autofocus on the reason field, radius 16
        // (rulebook) with a label instead of a hint-only field.
        autofocus: true,
        maxLines: 2,
        decoration: InputDecoration(
          labelText: AppLocalizations.of(ctx)!.admin2_suspendReasonLabel,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(AppLocalizations.of(ctx)!.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(AppLocalizations.of(ctx)!.admin2_confirm),
        ),
      ],
    ),
  );
  if (confirmed != true) return null;
  return reasonController.text.trim();
}
