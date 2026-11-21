import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../customer/domain/entities/customer_entity.dart';

/// Walk-in CRM: the action row at the bottom of the customer
/// detail screen.
///
/// Walk-in records are shop-managed: Block/Unblock, Edit and
/// Archive (an archived record offers Restore instead of Archive).
/// Online records stay approved/rejected by the super admin — the
/// existing Approve/Reject buttons are unchanged and only
/// Block/Unblock is added (no Edit, no Archive, no KYC replace).
class CustomerDetailActions extends StatelessWidget {
  const CustomerDetailActions({
    super.key,
    required this.isWalkIn,
    required this.approvalStatus,
    required this.shopStatus,
    required this.acting,
    required this.onApprove,
    required this.onReject,
    required this.onBlockToggle,
    required this.onEdit,
    required this.onArchive,
  });

  final bool isWalkIn;
  final String approvalStatus;
  final String shopStatus;
  final bool acting;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onBlockToggle;
  final VoidCallback onEdit;
  final VoidCallback onArchive;

  /// The Archive confirm dialog. Returns true only when the owner
  /// confirms — archiving hides the customer from the shop's active
  /// list but keeps the record (delete = archive, never hard).
  static Future<bool> confirmArchive(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.customerDetailArchiveTitle),
        content: Text(l10n.customerDetailArchiveMessage),
        actions: [
          TextButton(
            key: const ValueKey('customer_archive_cancel'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            key: const ValueKey('customer_archive_confirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.customerDetailArchive),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final blocked = shopStatus == CustomerEntity.statusBlocked;
    final archived = shopStatus == CustomerEntity.statusArchived;
    if (isWalkIn) {
      return Row(
        children: [
          Expanded(
            child: DebouncedButton(
              text: archived
                  ? l10n.customerDetailRestore
                  : blocked
                      ? l10n.customerDetailUnblock
                      : l10n.customerDetailBlock,
              icon: archived
                  ? Icons.restore_rounded
                  : blocked
                      ? Icons.lock_open_rounded
                      : Icons.block_rounded,
              backgroundColor: blocked || archived
                  ? AppColors.accentSuccessStrong
                  : AppColors.errorDark,
              isLoading: acting,
              onPressed: onBlockToggle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DebouncedButton(
              text: l10n.customerDetailEdit,
              icon: Icons.edit_rounded,
              backgroundColor: AppColors.primary,
              isLoading: acting,
              onPressed: onEdit,
            ),
          ),
          if (!archived) ...[
            const SizedBox(width: 12),
            Expanded(
              child: DebouncedButton(
                text: l10n.customerDetailArchive,
                icon: Icons.archive_rounded,
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                textColor: Theme.of(context).colorScheme.onSurface,
                isLoading: acting,
                onPressed: onArchive,
              ),
            ),
          ],
        ],
      );
    }
    // Online: the existing Approve/Reject pair, unchanged, plus
    // Block/Unblock below it.
    final approval = approvalStatus;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // OW-m14: the button matching the current status is disabled (DebouncedButton has no disabled slot, so the decided action is dimmed + input-blocked); the opposite action stays available.
        Row(
          children: [
            Expanded(child: Opacity(opacity: approval == 'approved' ? 0.5 : 1, child: AbsorbPointer(absorbing: approval == 'approved', child: DebouncedButton(text: l10n.customerDetailApprove, icon: Icons.check_rounded, backgroundColor: AppColors.accentSuccessStrong, isLoading: acting, onPressed: onApprove)))),
            const SizedBox(width: 12),
            Expanded(child: Opacity(opacity: approval == 'rejected' ? 0.5 : 1, child: AbsorbPointer(absorbing: approval == 'rejected', child: DebouncedButton(text: l10n.customerDetailReject, icon: Icons.close_rounded, backgroundColor: AppColors.errorDark, isLoading: acting, onPressed: onReject)))),
          ],
        ),
        const SizedBox(height: 12),
        DebouncedButton(
          text: blocked
              ? l10n.customerDetailUnblock
              : l10n.customerDetailBlock,
          icon: blocked ? Icons.lock_open_rounded : Icons.block_rounded,
          backgroundColor: blocked
              ? AppColors.accentSuccessStrong
              : AppColors.errorDark,
          isLoading: acting,
          onPressed: onBlockToggle,
        ),
      ],
    );
  }
}
