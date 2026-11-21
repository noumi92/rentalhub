import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../customer/domain/entities/customer_entity.dart';

/// Walk-in CRM: the blocked/archived banner on the customer
/// detail screen. Rendered only when the shop status is blocked or
/// archived — an active customer gets no banner.
class CustomerBlockedBanner extends StatelessWidget {
  const CustomerBlockedBanner({super.key, required this.shopStatus});

  final String shopStatus;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final brightness = Theme.of(context).brightness;
    final archived = shopStatus == CustomerEntity.statusArchived;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: archived
            ? Theme.of(context).colorScheme.surfaceContainerHighest
            : AppColors.errorContainerFor(brightness),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            archived
                ? Icons.archive_rounded
                : Icons.block_rounded,
            size: 20,
            color: archived
                ? Theme.of(context).colorScheme.onSurfaceVariant
                : AppColors.errorOnContainerFor(brightness),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              archived
                  ? l10n.customerDetailArchivedBanner
                  : l10n.customerDetailBlockedBanner,
              style: TextStyle(
                color: archived
                    ? Theme.of(context).colorScheme.onSurfaceVariant
                    : AppColors.errorOnContainerFor(brightness),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
