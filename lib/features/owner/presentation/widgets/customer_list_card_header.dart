import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/money_format.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../customer/utils/customer_grouping.dart';

/// Minimalist customer list header: 44px circular initial avatar, bold name,
/// muted phone/CNIC subtitle, soft-tinted semantic micro-badges, and a
/// top-right tabular metric pill (`Rs. 21,525 · 7 trips`).
class CustomerListCardHeader extends StatelessWidget {
  const CustomerListCardHeader({
    super.key,
    required this.customer,
    required this.blacklisted,
    required this.expanded,
    required this.onTap,
    this.blocked = false,
    this.kycIncomplete = false,
    this.dormant = false,
  });

  final CustomerSummary customer;
  final bool blacklisted;
  final bool expanded;
  final VoidCallback onTap;
  final bool blocked;
  final bool kycIncomplete;
  final bool dormant;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final c = customer;
    final phoneCnic = [
      if (c.phone.isNotEmpty) c.phone,
      if (c.cnic != null && c.cnic!.trim().isNotEmpty) c.cnic!,
    ].join(' • ');

    return InkWell(
      onTap: onTap,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: brightness == Brightness.dark
                  ? AppColors.primaryContainerOnDark
                  : AppColors.primaryContainer,
              child: Text(
                c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                style: TextStyle(
                  color: brightness == Brightness.dark
                      ? Colors.white
                      : AppColors.primaryDark,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          c.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            l10n.customersBookingTotal(
                              l10n.amountRs(formatRs(c.totalSpent)),
                              c.bookingCount,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: cs.onSurfaceVariant,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (phoneCnic.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      phoneCnic,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (c.bookingCount >= 2)
                        _softBadge(
                          context,
                          l10n.customersBadgeRegular,
                          AppColors.successBadgeFor(brightness),
                          AppColors.successBadgeTextFor(brightness),
                        )
                      else
                        _softBadge(
                          context,
                          l10n.customersBadgeNew,
                          AppColors.orangeContainerFor(brightness),
                          AppColors.orangeTextFor(brightness),
                        ),
                      if (kycIncomplete)
                        _softBadge(
                          context,
                          l10n.customersBadgeKycIncomplete,
                          AppColors.warningContainerFor(brightness),
                          AppColors.warningOnContainerFor(brightness),
                        ),
                      if (blacklisted)
                        _softBadge(
                          context,
                          l10n.customersBlacklisted,
                          AppColors.errorBadgeFor(brightness),
                          AppColors.errorBadgeTextFor(brightness),
                        ),
                      if (blocked)
                        _softBadge(
                          context,
                          l10n.customersBadgeBlocked,
                          AppColors.errorBadgeFor(brightness),
                          AppColors.errorBadgeTextFor(brightness),
                        ),
                      if (dormant)
                        _softBadge(
                          context,
                          l10n.customersBadgeDormant,
                          cs.surfaceContainerHighest,
                          cs.onSurfaceVariant,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _softBadge(BuildContext context, String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
