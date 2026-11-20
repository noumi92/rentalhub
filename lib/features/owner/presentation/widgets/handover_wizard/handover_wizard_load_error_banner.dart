import 'package:flutter/material.dart';

import '../../../../../core/theme/card_decoration.dart';
import '../../../../../l10n/app_localizations.dart';

/// Item 9 (O26–O30): the wizard shell's load-error banner. The
/// shop / vehicle load failed: say so and offer a retry instead of
/// silently certifying against the 'RentalHub' / Rs. 0 fallbacks
/// (audit C4, same as the old single view). Inline, not a
/// SnackBar — a SnackBar floats over the wizard's bottom nav bar
/// and swallows its taps.
/// Extracted so the shell stays under the 250-line cap.
class HandoverWizardLoadErrorBanner extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const HandoverWizardLoadErrorBanner({
    super.key,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppCardDecoration.shadow(context),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded,
              color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
              child: Text(l10n.fleetLoadError(error),
                  style: Theme.of(context).textTheme.bodySmall)),
          TextButton(
              onPressed: onRetry, child: Text(l10n.commonRetry)),
        ],
      ),
    );
  }
}
