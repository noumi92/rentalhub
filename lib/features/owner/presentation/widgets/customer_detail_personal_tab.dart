import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../customer/domain/entities/customer_entity.dart';

/// Structured Personal Info tab inside the redesigned customer detail
/// screen: displays identity fields, license details, guarantor info,
/// and the walk-in Security Wallet entry point.
class CustomerDetailPersonalTab extends StatelessWidget {
  final CustomerEntity customer;
  final bool isWalkIn;

  const CustomerDetailPersonalTab({
    super.key,
    required this.customer,
    required this.isWalkIn,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final rows = <(String, String?)>[
      (l10n.addCustomerName, customer.name),
      (l10n.kycWizardFatherName, customer.fatherName),
      (l10n.kycWizardWhatsappNumber, customer.phone),
      (l10n.addCustomerCnic, customer.cnic),
      (l10n.kycWizardDateOfBirth, customer.dateOfBirth),
      (l10n.kycWizardCnicExpiry, customer.cnicExpiry),
      (l10n.kycWizardAddress, customer.address),
      (l10n.kycWizardLicenseNumber, customer.licenseNumber),
      (l10n.kycWizardLicenseExpiry, customer.licenseExpiry),
      if (customer.guarantorCustomerId != null &&
          customer.guarantorCustomerId!.isNotEmpty)
        (
          l10n.walkInGuarantorLabel,
          '${customer.guarantorRelation ?? l10n.kycWizardRelationOther} • ${customer.guarantorCustomerId}',
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                for (var i = 0; i < rows.length; i++) ...[
                  if (i > 0) const Divider(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          rows[i].$1,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: Text(
                          (rows[i].$2 == null || rows[i].$2!.trim().isEmpty)
                              ? '—'
                              : rows[i].$2!,
                          textAlign: TextAlign.end,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        if (isWalkIn) ...[
          const SizedBox(height: 12),
          Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              leading:
                  const Icon(Icons.account_balance_wallet_outlined, size: 20),
              title: Text(
                l10n.customerDetailSecurityWallet,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              trailing: const Icon(Icons.chevron_right_rounded, size: 20),
              onTap: () => context.push(
                RouteNames.ownerCustomerSecurityWallet
                    .replaceFirst(':id', customer.customerId),
                extra: customer,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
