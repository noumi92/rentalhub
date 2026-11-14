import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// A confirmation dialog for destructive admin actions (revoke a role,
/// reset TOTP, withdraw an invite). Returns true only when the admin
/// confirms.
Future<bool> showAdminConfirmDialog(
  BuildContext context, {
  required String title,
  required String body,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(body),
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
  return confirmed == true;
}
