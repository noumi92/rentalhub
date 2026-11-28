import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../customer/domain/entities/customer_entity.dart';
import 'manual_booking_radio_dot.dart';
import 'operations/triage_trust_row.dart';

/// O21: one registered-customer card in the walk-in step 1 list —
/// avatar + name + phone/CNIC, live trust score, blacklist / KYC /
/// saved-signature chips. A blacklisted or blocked customer is shown
/// but not selectable: tapping reports the refusal instead of
/// selecting. (An archived customer never reaches this card — the
/// step filters archived records out of the pick list.)
class ManualBookingCustomerCard extends StatelessWidget {
  const ManualBookingCustomerCard({
    super.key,
    required this.customer,
    required this.selected,
    required this.blacklisted,
    required this.blocked,
    required this.kycDone,
    this.shopId,
    this.completedTrips,
    this.trustScore,
    required this.onSelected,
  });

  final CustomerEntity customer;
  final bool selected;
  final bool blacklisted;
  final bool blocked;
  final bool kycDone;
  final String? shopId;
  final int? completedTrips;
  final double? trustScore;
  final ValueChanged<CustomerEntity> onSelected;

  static String _digits(String? value) =>
      (value ?? '').replaceAll(RegExp(r'\D'), '');

  static String _maskedCnic(String? cnic) {
    final digits = _digits(cnic);
    if (digits.length < 7) return cnic ?? '';
    return '${digits.substring(0, 5)}-*****-${digits.substring(digits.length - 1)}';
  }

  static String _initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final brightness = Theme.of(context).brightness;
    final c = customer;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        key: ValueKey('manual-booking-customer-${c.customerId}'),
        onTap: () {
          if (blacklisted) {
            AppFeedback.showError(context, l10n.manualBookingBlacklisted);
            return;
          }
          if (blocked) {
            AppFeedback.showError(context, l10n.manualBookingBlocked);
            return;
          }
          onSelected(c);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? AppColors.orangeFill
                  : Theme.of(context).dividerColor,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ManualBookingRadioDot(selected: selected, enabled: !blacklisted && !blocked),
                  CircleAvatar(
                    radius: 20,
                    child: Text(_initials(c.name),
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        Text('${c.phone} • ${_maskedCnic(c.cnic)}',
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
              TriageTrustRow(
                customerId: c.customerId,
                shopId: shopId,
                trustScore: trustScore,
                completedTrips: completedTrips,
                kycStatus: kycDone ? 'verified' : 'missing',
                cnicVerified: (c.cnicFrontUrl?.isNotEmpty ?? false) &&
                        (c.cnicBackUrl?.isNotEmpty ?? false)
                    ? true
                    : null,
                licenseVerified: (c.licenseFrontUrl?.isNotEmpty ?? false) &&
                        (c.licenseBackUrl?.isNotEmpty ?? false)
                    ? true
                    : null,
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _chip(
                    context,
                    blacklisted
                        ? l10n.manualBookingBlacklistedCustomer
                        : l10n.manualBookingNotBlacklisted,
                    blacklisted
                        ? AppColors.dangerTextFor(brightness)
                        : AppColors.successTextFor(brightness),
                    blacklisted
                        ? AppColors.errorContainerFor(brightness)
                        : AppColors.successContainerFor(brightness),
                  ),
                  if (blocked)
                    _chip(
                      context,
                      l10n.manualBookingBlockedCustomer,
                      AppColors.dangerTextFor(brightness),
                      AppColors.errorContainerFor(brightness),
                    ),
                  _chip(
                    context,
                    kycDone
                        ? l10n.manualBookingKycDone
                        : l10n.manualBookingKycPending,
                    kycDone
                        ? AppColors.successTextFor(brightness)
                        : AppColors.warningTextFor(brightness),
                    kycDone
                        ? AppColors.successContainerFor(brightness)
                        : AppColors.warningContainerFor(brightness),
                  ),
                  _chip(
                    context,
                    c.signatureUrl != null
                        ? l10n.manualBookingSavedSignature
                        : l10n.manualBookingNoSignature,
                    c.signatureUrl != null
                        ? AppColors.successTextFor(brightness)
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    c.signatureUrl != null
                        ? AppColors.successContainerFor(brightness)
                        : Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(BuildContext context, String label, Color fg, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(fontWeight: FontWeight.w500, color: fg)),
    );
  }
}
