import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../customer/domain/entities/customer_entity.dart';
import 'customer_detail_docs.dart';
import 'customer_kyc_slots.dart';

/// Showroom redesign Phase 3 — the KYC section of the customer
/// profile: one header carrying the REAL uploaded count
/// (`customerDetailKycDocumentsCount`, e.g. "KYC Documents (3/11
/// Uploaded)") above the 3-column document grid. The old boolean
/// `hasKyc` ("documents on file" / "no record") is replaced by the
/// count — see [kycUploadedCount].
class CustomerDetailKycSection extends StatelessWidget {
  const CustomerDetailKycSection({super.key, required this.customer});

  final CustomerEntity customer;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.customerDetailKycDocumentsCount(
              kycUploadedCount(customer), kycTotalSlots),
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        CustomerDetailDocs(customer: customer),
      ],
    );
  }
}
