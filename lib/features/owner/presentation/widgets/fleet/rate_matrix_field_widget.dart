import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../l10n/app_localizations.dart';

class RateMatrixFieldWidget extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final String kmCap;

  /// Audit §6: a disabled package's price field is greyed out and
  /// not editable (the add-vehicle rates step already does this).
  final bool enabled;

  const RateMatrixFieldWidget({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.kmCap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    // Audit 2026-11-15 DS-10: the currency prefix comes from the
    // currencyPrefix .arb key, never a Dart literal.
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: enabled ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  kmCap,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Audit §6: flex-based, not a fixed 130dp — the field
          // squeezes at 360px with a long Urdu label + Rs. prefix.
          Expanded(
            flex: 2,
            child: TextField(
              controller: controller,
              enabled: enabled,
              keyboardType: TextInputType.number,
              // OW-m5: digits only — typing "7,500" or "12.5" used to
              // fail int.tryParse with only the generic "invalid
              // field" error. The formatter strips separators on
              // paste too.
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                // Audit §6: prices are the most important content —
                // onSurface, never small orange text (~3:1).
                color: Theme.of(context).colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                prefixText: l10n.currencyPrefix,
                prefixStyle: Theme.of(context).textTheme.bodyMedium,
                // Audit 2026-11-15 DS-10: the hint prop was accepted
                // but never passed to the field — every localized
                // hint in the rate editors was silently dropped.
                hintText: hint,
                isDense: true,
                filled: true,
                fillColor: enabled
                    ? Theme.of(context).colorScheme.surfaceContainerHighest
                    : Theme.of(context).colorScheme.surfaceContainer,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Theme.of(context).dividerColor),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

