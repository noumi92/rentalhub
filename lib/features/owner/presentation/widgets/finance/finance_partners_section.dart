import 'package:flutter/material.dart';
import '../../../../../l10n/app_localizations.dart';

import  '../../../../finance/domain/entities/partner_share_entity.dart';

/// Phase B (H4): the shop's partners and their profit share. The
/// share is a record — the money itself moves through the ledger
/// as an expense transfer when it is paid out.
class FinancePartnersSection extends StatelessWidget {
  final List<PartnerShareEntity> partners;
  final VoidCallback onAddPartner;

  const FinancePartnersSection({
    super.key,
    required this.partners,
    required this.onAddPartner,
  });

  @override
  Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l10n.financePartners,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                )),
            TextButton.icon(
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(l10n.financeAddPartner),
              onPressed: onAddPartner,
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (partners.isEmpty)
          Text(l10n.financePartnersEmpty,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ...partners.map((p) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(p.partnerName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    )),
                Text(l10n.financePartnerShareLine(p.sharePercent),
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          );
        }),
      ],
    );
  }
}
