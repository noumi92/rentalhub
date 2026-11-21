import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../customer/domain/entities/customer_entity.dart';

/// Walk-in CRM: the status pills under the customer identity row —
/// the same pill shape as the approval/blacklist pills in
/// [CustomerDetailHeader]. The shop status (Active / Blocked /
/// Archived) always shows; KYC Incomplete, Dormant and Frequent
/// are derived and show alongside it when they apply.
class CustomerStatusChips extends StatelessWidget {
  const CustomerStatusChips({
    super.key,
    required this.shopStatus,
    required this.kycIncomplete,
    required this.dormant,
    required this.frequent,
  });

  final String shopStatus;
  final bool kycIncomplete;
  final bool dormant;
  final bool frequent;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final brightness = Theme.of(context).brightness;
    final chips = <(String, Color, Color)>[
      if (shopStatus == CustomerEntity.statusBlocked)
        (
          l10n.customerStatusBlocked,
          AppColors.errorBadgeFor(brightness),
          AppColors.errorBadgeTextFor(brightness),
        )
      else if (shopStatus == CustomerEntity.statusArchived)
        (
          l10n.customerStatusArchived,
          Theme.of(context).colorScheme.surfaceContainerHighest,
          Theme.of(context).colorScheme.onSurfaceVariant,
        )
      else
        (
          l10n.customerStatusActive,
          AppColors.successBadgeFor(brightness),
          AppColors.successBadgeTextFor(brightness),
        ),
      if (kycIncomplete)
        (
          l10n.customerStatusKycIncomplete,
          AppColors.orangeContainerFor(brightness),
          AppColors.orangeOnContainerFor(brightness),
        ),
      if (dormant)
        (
          l10n.customerStatusDormant,
          Theme.of(context).colorScheme.surfaceContainerHighest,
          Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      if (frequent)
        (
          l10n.customerStatusFrequent,
          AppColors.primary,
          Colors.white,
        ),
    ];
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final (label, bg, fg) in chips) _pill(context, label, bg, fg),
      ],
    );
  }

  // Badge labels are w500, never bold (redesign rule).
  Widget _pill(BuildContext context, String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: fg, fontWeight: FontWeight.w500)),
    );
  }
}
