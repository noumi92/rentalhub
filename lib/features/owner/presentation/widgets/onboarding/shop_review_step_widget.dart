import 'package:flutter/material.dart';
import '../../../../../l10n/app_localizations.dart';

/// Audit §5 (P2-2): the Review step of owner onboarding — every value
/// the owner entered on steps 1–4, read-only, before the application
/// is submitted. Nothing here is editable and nothing is invented:
/// payout methods and attached documents are the lists the caller
/// built from the actual form state (an empty documents list renders
/// an honest "none attached" line, not a placeholder).
class ShopReviewStepWidget extends StatelessWidget {
  const ShopReviewStepWidget({
    super.key,
    required this.shopName,
    required this.ownerName,
    required this.cnic,
    required this.whatsapp,
    required this.phone,
    required this.openingHours,
    required this.shopLogoName,
    required this.address,
    required this.city,
    required this.payoutMethods,
    required this.attachedDocuments,
  });

  final String shopName;
  final String ownerName;
  final String cnic;
  final String whatsapp;
  final String phone;
  final String openingHours;
  final String? shopLogoName;
  final String address;
  final String city;
  final List<String> payoutMethods;
  final List<String> attachedDocuments;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.onboardingReviewTitle, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(l10n.onboardingReviewHint, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 12),
        _section(context, l10n.onboardingStepShopDetails, [
          _row(context, l10n.onboardingReviewShopName, shopName),
          _row(context, l10n.onboardingReviewOwnerName, ownerName),
          _row(context, l10n.onboardingReviewCnic, cnic.isEmpty ? '—' : cnic),
          _row(context, l10n.onboardingReviewWhatsapp, whatsapp),
          _row(context, l10n.onboardingReviewPhone, phone.isEmpty ? '—' : phone),
          _row(context, l10n.onboardingReviewOpeningHours, openingHours),
          if (shopLogoName != null) _row(context, l10n.onboardingReviewShopLogo, shopLogoName!),
        ]),
        const SizedBox(height: 12),
        _section(context, l10n.onboardingStepLocation, [
          _row(context, l10n.onboardingReviewAddress, address),
          _row(context, l10n.onboardingReviewCity, city),
        ]),
        const SizedBox(height: 12),
        _section(context, l10n.onboardingStepPayouts, [
          if (payoutMethods.isEmpty)
            Text('—', style: Theme.of(context).textTheme.bodyMedium)
          else
            ...payoutMethods.map((m) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(children: [const Icon(Icons.check_circle_rounded, size: 16), const SizedBox(width: 6), Expanded(child: Text(m, style: Theme.of(context).textTheme.bodyMedium))]),
                )),
        ]),
        const SizedBox(height: 12),
        _section(context, l10n.onboardingStepKyc, [
          if (attachedDocuments.isEmpty)
            Text(l10n.onboardingReviewNoDocuments, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant))
          else
            ...attachedDocuments.map((d) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(children: [const Icon(Icons.attach_file_rounded, size: 16), const SizedBox(width: 6), Expanded(child: Text(d, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyMedium))]),
                )),
        ]),
      ],
    );
  }

  Widget _section(BuildContext context, String title, List<Widget> children) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant))),
          const SizedBox(width: 8),
          Expanded(flex: 3, child: Text(value.isEmpty ? '—' : value, textAlign: TextAlign.end, style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
