import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../customer/domain/entities/customer_entity.dart';
import 'customer_kyc_slots.dart';

/// Showroom redesign Phase 3 — the slim identity card of the
/// customer profile: avatar, name, phone + CNIC on ONE line, and the
/// status pills end-aligned (directional, so they flip in RTL).
/// Below it, ONE merged red alert banner (errorContainer token)
/// carrying the rejection reason and the KYC status together — it
/// renders only when there is something to flag (rejected, or no
/// KYC file on record).
class CustomerDetailHeader extends StatelessWidget {
  const CustomerDetailHeader({
    super.key,
    required this.customer,
    required this.blacklisted,
  });

  final CustomerEntity customer;
  final bool blacklisted;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final brightness = Theme.of(context).brightness;
    final approval = customer.approvalStatus;
    final (approvalBg, approvalFg) = approval == 'approved'
        ? (
            AppColors.successBadgeFor(brightness),
            AppColors.successBadgeTextFor(brightness),
          )
        : approval == 'rejected'
            ? (
                AppColors.errorBadgeFor(brightness),
                AppColors.errorBadgeTextFor(brightness),
              )
            : (
                AppColors.orangeContainerFor(brightness),
                AppColors.orangeOnContainerFor(brightness),
              );
    final approvalLabel = approval == 'approved'
        ? l10n.statusApproved
        : approval == 'rejected'
            ? l10n.statusRejected
            : l10n.customerDetailApprovalPending;
    final hasKyc = kycUploadedCount(customer) > 0;
    // Merged alert: rejection reason first, KYC status second.
    final alertLines = <String>[
      if (approval == 'rejected' && customer.rejectionReason != null)
        customer.rejectionReason!,
      if (!hasKyc)
        l10n.customerDetailKycNotOnFile
      else if (approval == 'rejected')
        l10n.customerDetailKycOnFile,
    ];
    final phoneCnic = [
      if (customer.phone.isNotEmpty) customer.phone,
      if (customer.cnic != null) customer.cnic!,
    ].join(' • ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primary,
              radius: 28,
              child: Text(
                  customer.name.isNotEmpty
                      ? customer.name[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(customer.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  if (phoneCnic.isNotEmpty)
                    Text(phoneCnic,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // End-aligned pills (directional: left in RTL).
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _pill(context, approvalLabel, approvalBg, approvalFg),
                const SizedBox(height: 6),
                if (blacklisted)
                  _pill(
                      context,
                      l10n.customersBlacklisted,
                      AppColors.errorBadgeFor(brightness),
                      AppColors.errorBadgeTextFor(brightness))
                else
                  _pill(
                      context,
                      l10n.customerDetailNotBlacklisted,
                      AppColors.successBadgeFor(brightness),
                      AppColors.successBadgeTextFor(brightness)),
              ],
            ),
          ],
        ),
        if (alertLines.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.errorContainerFor(brightness),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.error_outline_rounded,
                    size: 20,
                    color: AppColors.errorOnContainerFor(brightness)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final line in alertLines)
                        Text(line,
                            style: TextStyle(
                                color: AppColors.errorOnContainerFor(
                                    brightness))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
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
