import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// Audit impl (O49): the sign-out confirmation dialog. Mount this
/// on the Settings sign-out action (owner_settings_view.dart,
/// which worker C does not own): on confirm the caller signs out
/// and navigates to the signed-out state (`ownerSignedOut` route);
/// on cancel nothing happens.
Future<bool> showSignOutConfirmDialog(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.signOutConfirmTitle),
      content: Text(l10n.signOutConfirmBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(l10n.signOutConfirmYes),
        ),
      ],
    ),
  );
  return confirmed == true;
}
