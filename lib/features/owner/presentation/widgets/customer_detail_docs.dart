import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../customer/domain/entities/customer_entity.dart';
import '../../../../core/theme/card_decoration.dart';

/// Owner-deck finish (#35): the documents/photo section of the
/// customer profile. One tile per captured file; a missing file shows
/// an honest "Not provided" state, never a placeholder image. URLs
/// only — the record never carries bytes.
class CustomerDetailDocs extends StatelessWidget {
  const CustomerDetailDocs({super.key, required this.customer});

  final CustomerEntity customer;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tiles = <(String, String?)>[
      (l10n.customerDetailProfilePhoto, customer.profilePhotoUrl),
      (l10n.customerDetailCnicFront, customer.cnicFrontUrl),
      (l10n.customerDetailCnicBack, customer.cnicBackUrl),
      (l10n.customerDetailLicenseFront, customer.licenseFrontUrl),
      (l10n.customerDetailLicenseBack, customer.licenseBackUrl),
      (l10n.customerDetailSignature, customer.signatureUrl),
    ];
    return Wrap(
      children: [for (final (label, url) in tiles) _tile(context, l10n, label, url)],
    );
  }

  Widget _tile(BuildContext context, AppLocalizations l10n, String label, String? url) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 8, bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: AppCardDecoration.of(context, radius: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          SizedBox(
            height: 84,
            child: url == null || url.isEmpty
                ? Center(child: Text(l10n.customerDetailNoDocument, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall))
                : ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(url,
                        width: double.infinity, height: 84, fit: BoxFit.cover,
                        errorBuilder: (_, Object error, StackTrace? stack) => Center(child: Text(l10n.customerDetailNoDocument, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall))),
                  ),
          ),
        ],
      ),
    );
  }
}
