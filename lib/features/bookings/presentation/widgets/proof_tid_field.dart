import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';

/// The transaction-ID field on the proof-upload screen, with its
/// label. The inline error marks the field instead of surfacing
/// only as a snackbar (§11).
class ProofTidField extends StatelessWidget {
  const ProofTidField({
    super.key,
    required this.controller,
    required this.error,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String? error;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.proofTidLabel,
            style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: l10n.proofTidHint,
            errorText: error,
            hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            prefixIcon: const Icon(Icons.receipt_long_rounded),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Theme.of(context).dividerColor)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }
}
