import 'package:flutter/material.dart';

import '../../../../core/widgets/masked_value.dart';
import '../../../../l10n/app_localizations.dart';

/// E1: the customer's own CNIC on their profile, masked by default.
/// The edit sheet keeps the raw CNIC field (editing needs the real
/// value); this is the only read-only CNIC display on the profile.
/// Owner-side CNIC views stay unmasked — this row is customer-only.
class ProfileCnicRow extends StatelessWidget {
  const ProfileCnicRow({super.key, required this.cnic});

  final String cnic;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(Icons.badge_outlined, color: colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.cnicLabel,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                  MaskedValue(
                    value: cnic,
                    maskedValue: MaskedValue.maskCnic(cnic),
                    style: Theme.of(context).textTheme.bodyMedium,
                    showTooltip: l10n.cnicShow,
                    hideTooltip: l10n.cnicHide,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
