import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/account_deletion_service.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../l10n/app_localizations.dart';

/// Google Play Account Deletion Policy compliant tile + confirmation dialog.
/// Shared by both Customer Settings and Owner Settings.
class DeleteAccountTile extends StatelessWidget {
  const DeleteAccountTile({
    super.key,
    required this.isOwner,
    this.service,
    this.onDeleted,
  });

  final bool isOwner;
  final AccountDeletionService? service;
  final VoidCallback? onDeleted;

  Future<void> _confirmAndDelete(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final brightness = Theme.of(context).brightness;
    var acknowledged = false;
    var deleting = false;

    final deleted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(l10n.deleteAccountDialogTitle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.deleteAccountDialogBody,
                  style: Theme.of(ctx).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  value: acknowledged,
                  onChanged: deleting
                      ? null
                      : (v) => setDialogState(() => acknowledged = v ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    l10n.deleteAccountConfirmCheck,
                    style: Theme.of(ctx).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: deleting ? null : () => Navigator.of(ctx).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.errorDark,
                foregroundColor: Colors.white,
              ),
              onPressed: (!acknowledged || deleting)
                  ? null
                  : () async {
                      setDialogState(() => deleting = true);
                      final res = await (service ?? AccountDeletionService())
                          .deleteCurrentAccount(isOwner: isOwner);
                      if (!ctx.mounted) return;
                      if (res.status == AccountDeletionStatus.success) {
                        Navigator.of(ctx).pop(true);
                        return;
                      }
                      setDialogState(() => deleting = false);
                      Navigator.of(ctx).pop(false);
                      if (!context.mounted) return;
                      AppFeedback.showError(
                        context,
                        res.status == AccountDeletionStatus.requiresRecentLogin
                            ? l10n.deleteAccountReauthRequired
                            : l10n.deleteAccountError,
                      );
                    },
              child: deleting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(l10n.deleteAccountConfirmButton),
            ),
          ],
        ),
      ),
    );

    if (deleted == true && context.mounted) {
      AppFeedback.showSuccess(context, l10n.deleteAccountSuccess);
      if (onDeleted != null) {
        onDeleted!.call();
      } else {
        context.go(isOwner ? RouteNames.ownerSignedOut : RouteNames.auth);
      }
    } else {
      // keep brightness referenced cleanly
      assert(brightness == Brightness.light || brightness == Brightness.dark);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final danger = AppColors.dangerTextFor(Theme.of(context).brightness);
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: danger.withValues(alpha: 0.35)),
      ),
      child: ListTile(
        leading: Icon(Icons.delete_forever_rounded, color: danger),
        title: Text(
          l10n.deleteAccountTitle,
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.w600, color: danger),
        ),
        subtitle: Text(
          l10n.deleteAccountSubtitle,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: Icon(Icons.chevron_right_rounded, color: danger),
        onTap: () => _confirmAndDelete(context),
      ),
    );
  }
}
