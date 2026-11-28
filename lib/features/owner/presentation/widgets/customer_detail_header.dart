import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../customer/domain/entities/customer_entity.dart';
import 'customer_kyc_slots.dart';

/// Minimalist customer profile hero header: 56px circular initial avatar,
/// bold name, phone/CNIC line, single wrapping row of soft-tinted semantic
/// micro-badges, and an actionable KYC alert strip with an inline `Add KYC >`
/// button that switches straight to the KYC & Docs tab.
class CustomerDetailHeader extends StatelessWidget {
  const CustomerDetailHeader({
    super.key,
    required this.customer,
    required this.blacklisted,
    required this.shopStatus,
    required this.kycIncomplete,
    required this.dormant,
    required this.frequent,
    this.onAddKyc,
  });

  final CustomerEntity customer;
  final bool blacklisted;
  final String shopStatus;
  final bool kycIncomplete;
  final bool dormant;
  final bool frequent;
  final VoidCallback? onAddKyc;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final isWalkIn = customer.source == 'walk_in';
    final approval = customer.approvalStatus;
    final hasKyc = kycUploadedCount(customer) > 0;

    final phoneCnic = [
      if (customer.phone.isNotEmpty) customer.phone,
      if (customer.cnic != null && customer.cnic!.trim().isNotEmpty)
        customer.cnic!,
    ].join(' • ');

    final showAlert = kycIncomplete ||
        (approval == 'rejected' &&
            (customer.rejectionReason?.trim().isNotEmpty ?? false));
    final alertMessage = approval == 'rejected' &&
            (customer.rejectionReason?.trim().isNotEmpty ?? false)
        ? customer.rejectionReason!
        : !hasKyc
            ? l10n.customerDetailKycNotOnFile
            : l10n.customerDetailKycIncompletePrompt;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: brightness == Brightness.dark
                  ? AppColors.primaryContainerOnDark
                  : AppColors.primaryContainer,
              child: Text(
                customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
                style: TextStyle(
                  color: brightness == Brightness.dark
                      ? Colors.white
                      : AppColors.primaryDark,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
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
                      _statusChip(
                        context,
                        shopStatus == CustomerEntity.statusBlocked
                            ? l10n.customerStatusBlocked
                            : shopStatus == CustomerEntity.statusArchived
                                ? l10n.customerStatusArchived
                                : l10n.customerStatusActive,
                        shopStatus == CustomerEntity.statusActive
                            ? AppColors.successBadgeFor(brightness)
                            : AppColors.errorBadgeFor(brightness),
                        shopStatus == CustomerEntity.statusActive
                            ? AppColors.successBadgeTextFor(brightness)
                            : AppColors.errorBadgeTextFor(brightness),
                      ),
                      if (isWalkIn && !kycIncomplete)
                        _statusChip(
                          context,
                          l10n.manualBookingKycDone,
                          AppColors.successBadgeFor(brightness),
                          AppColors.successBadgeTextFor(brightness),
                        ),
                      if (!isWalkIn)
                        _statusChip(
                          context,
                          approval == 'approved'
                              ? l10n.statusApproved
                              : approval == 'rejected'
                                  ? l10n.statusRejected
                                  : l10n.customerDetailApprovalPending,
                          approval == 'approved'
                              ? AppColors.successBadgeFor(brightness)
                              : approval == 'rejected'
                                  ? AppColors.errorBadgeFor(brightness)
                                  : AppColors.warningContainerFor(brightness),
                          approval == 'approved'
                              ? AppColors.successBadgeTextFor(brightness)
                              : approval == 'rejected'
                                  ? AppColors.errorBadgeTextFor(brightness)
                                  : AppColors.warningOnContainerFor(brightness),
                        ),
                      if (frequent)
                        _statusChip(
                          context,
                          l10n.customerStatusFrequent,
                          AppColors.successBadgeFor(brightness),
                          AppColors.successBadgeTextFor(brightness),
                        ),
                      if (kycIncomplete)
                        _statusChip(
                          context,
                          l10n.customersBadgeKycIncomplete,
                          AppColors.warningContainerFor(brightness),
                          AppColors.warningOnContainerFor(brightness),
                        ),
                      if (blacklisted)
                        _statusChip(
                          context,
                          l10n.customersBlacklisted,
                          AppColors.errorBadgeFor(brightness),
                          AppColors.errorBadgeTextFor(brightness),
                        ),
                      if (dormant)
                        _statusChip(
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
        if (showAlert) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.errorContainerFor(brightness),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 18,
                  color: AppColors.errorOnContainerFor(brightness),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    alertMessage,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.errorOnContainerFor(brightness),
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
                if (kycIncomplete && onAddKyc != null)
                  TextButton(
                    key: const ValueKey('customer_detail_add_kyc_btn'),
                    onPressed: onAddKyc,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.orangeTextFor(brightness),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 36),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.customerDetailAddKyc,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(width: 2),
                        const Icon(Icons.chevron_right_rounded, size: 16),
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

  Widget _statusChip(BuildContext context, String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
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
