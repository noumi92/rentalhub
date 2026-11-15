import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';

/// Audit §4: the fleet search field (name or plate), extracted from
/// [OwnerFleetView] so the view stays under the 250-line cap.
class FleetSearchField extends StatelessWidget {
  final ValueChanged<String> onChanged;

  const FleetSearchField({super.key, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: l10n.fleetSearchHint,
          prefixIcon: const Icon(Icons.search_rounded),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          // Audit 2026-11-15 DS-12: no explicit border — the theme
          // owns the radius-16 input border (a radius-12 border here
          // drifted from every other search field).
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }
}
