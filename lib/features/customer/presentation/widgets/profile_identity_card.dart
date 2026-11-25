import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// Profile hub (2026-11-25): the identity card on the Profile tab —
/// the customer's own details in one place. Name, phone and email
/// always show (with an honest dash when missing); date of birth,
/// father's name and address show only when the record has them —
/// they are editable in the edit flow, previously read-only for the
/// customer. The CNIC lives in [ProfileCnicRow] below this card,
/// masked by default.
class ProfileIdentityCard extends StatelessWidget {
  const ProfileIdentityCard({
    super.key,
    required this.name,
    required this.phone,
    required this.email,
    required this.dateOfBirth,
    required this.fatherName,
    required this.address,
  });

  final String name;
  final String phone;
  final String email;
  final String? dateOfBirth;
  final String? fatherName;
  final String? address;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.profileIdentityTitle,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            _Row(label: l10n.editFullName, value: name),
            _Row(label: l10n.editPhone, value: phone),
            if (email.isNotEmpty) _Row(label: l10n.profileEmail, value: email),
            if (dateOfBirth != null && dateOfBirth!.isNotEmpty)
              _Row(label: l10n.editDateOfBirth, value: dateOfBirth!),
            if (fatherName != null && fatherName!.isNotEmpty)
              _Row(label: l10n.editFatherName, value: fatherName!),
            if (address != null && address!.isNotEmpty)
              _Row(label: l10n.editAddress, value: address!),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
