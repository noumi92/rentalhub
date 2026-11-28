import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/signature_profile_service.dart';
import '../../../../core/widgets/profile_signature_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../customer/domain/entities/customer_entity.dart';
import 'customer_detail_docs.dart';
import 'customer_kyc_slots.dart';

/// Minimalist KYC Documents tab section: header with uploaded count pill
/// (`X / 4 Uploaded`), sleek 4px rounded progress bar, and the 2×2 dashed
/// upload grid for CNIC & Driving License only.
class CustomerDetailKycSection extends StatelessWidget {
  const CustomerDetailKycSection({
    super.key,
    required this.customer,
    this.onReplaceSlot,
  });

  final CustomerEntity customer;
  final ValueChanged<String>? onReplaceSlot;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final uploaded = kycUploadedCount(customer);
    final progress = kycTotalSlots == 0 ? 0.0 : uploaded / kycTotalSlots;
    final complete = uploaded >= kycTotalSlots;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.customerDetailKycDocumentsTitle,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: complete
                    ? AppColors.successBadgeFor(brightness)
                    : cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                l10n.customerDetailKycUploadedPill(uploaded, kycTotalSlots),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: complete
                          ? AppColors.successBadgeTextFor(brightness)
                          : cs.onSurfaceVariant,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 4,
            backgroundColor: cs.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(
              complete ? AppColors.accentSuccessStrong : AppColors.orangeFill,
            ),
          ),
        ),
        const SizedBox(height: 14),
        CustomerDetailDocs(customer: customer, onReplaceSlot: onReplaceSlot),
        const SizedBox(height: 16),
        ProfileSignatureCard(
          key: ValueKey('customer_kyc_sig_${customer.customerId}'),
          title: l10n.handoverCustomerSignature,
          onLoad: () async =>
              (await SignatureProfileService.loadCustomerSignature(
                      customer.customerId))
                  .pngBytes,
          onSave: (bytes) => SignatureProfileService.saveCustomerSignature(
            customer.customerId,
            bytes,
          ),
        ),
      ],
    );
  }
}
