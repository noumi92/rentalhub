import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/money_format.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../customer/utils/customer_grouping.dart';

/// Showroom redesign Phase 3 — the collapsed customer row: avatar,
/// name + Regular / New / Blacklisted badges, then phone + CNIC on
/// ONE line, with the booking-total pill end-aligned at the top
/// right (directional: the pill column is `CrossAxisAlignment.end`,
/// so it flips in RTL). The pill renders through the
/// `customersBookingTotal` key with a localised money amount — never
/// a raw 'Rs. \$amount'.
///
/// Walk-in CRM badges (all optional, default off): [blocked]
/// reuses the Blacklisted badge visual (errorDark); [kycIncomplete]
/// marks a saved record whose KYC slots are not all present;
/// [dormant] marks a customer with no booking in 90 days. All three
/// derive from data the list already loads — see
/// `customer_status_helpers`.
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
    final c = customer;
    final phoneCnic = [
      if (c.phone.isNotEmpty) c.phone,
      if (c.cnic != null) c.cnic!,
    ].join(' • ');
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primary,
              child: Text(c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(c.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600)),
                      if (c.bookingCount >= 2)
                        _badge(
                            context,
                            l10n.customersBadgeRegular,
                            AppColors.accentSuccessStrong),
                      if (c.bookingCount <= 1)
                        _badge(context, l10n.customersBadgeNew,
                            AppColors.orangeFill),
                      if (blacklisted)
                        // Audit §18: white on Colors.red is 3.68:1 —
                        // errorDark #DC2626 is ~4.9:1.
                        _badge(context, l10n.customersBlacklisted,
                            AppColors.errorDark),
                      if (blocked)
                        // Same visual as the Blacklisted badge: a
                        // blocked customer is equally unbookable.
                        _badge(context, l10n.customersBadgeBlocked,
                            AppColors.errorDark),
                      if (kycIncomplete)
                        // Amber-800 #92400E carries white at ~6.8:1.
                        _badge(context, l10n.customersBadgeKycIncomplete,
                            AppColors.warningOnContainer),
                      if (dormant)
                        // Slate #64748B carries white at ~4.9:1.
                        _badge(context, l10n.customersBadgeDormant,
                            AppColors.textMuted),
                    ],
                  ),
                  if (phoneCnic.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(phoneCnic,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    l10n.customersBookingTotal(
                        l10n.amountRs(formatRs(c.totalSpent)),
                        c.bookingCount),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(fontWeight: FontWeight.w500),
                  ),
                ),
                Icon(expanded
                    ? Icons.expand_less_rounded
                    : Icons.expand_more_rounded),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Badge labels are w500, never bold (redesign rule).
  Widget _badge(BuildContext context, String label, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white, fontWeight: FontWeight.w500)),
    );
  }
}
