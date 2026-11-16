import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';

/// Audit §4: the fleet search field (name or plate), extracted from
/// [OwnerFleetView] so the view stays under the 250-line cap.
///
/// Showroom redesign (Phase 2, 2026-11-16): Handover QR and Requests
/// live INSIDE this bar, as icon buttons on its trailing side — the
/// quick-actions row loses those two buttons. Both are icon-only
/// (tooltip carries the label); [onHandover]/[onRequests] are null in
/// embeds that render the field without navigation, and the buttons
/// are then hidden.
class FleetSearchField extends StatelessWidget {
  final ValueChanged<String> onChanged;
  final VoidCallback? onHandover;
  final VoidCallback? onRequests;

  const FleetSearchField({
    super.key,
    required this.onChanged,
    this.onHandover,
    this.onRequests,
  });

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
          // E3: every IconButton carries a tooltip. The keys keep the
          // fleet-tab navigation tests addressing the same actions
          // they used to find in the quick-actions row.
          suffixIcon: (onHandover == null && onRequests == null)
              ? null
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (onHandover != null)
                      IconButton(
                        key: const Key('fleet-action-handover'),
                        tooltip: l10n.fleetHandoverQr,
                        icon: const Icon(Icons.qr_code_scanner_rounded),
                        onPressed: onHandover,
                      ),
                    if (onRequests != null)
                      IconButton(
                        key: const Key('fleet-action-requests'),
                        tooltip: l10n.navRequests,
                        icon: const Icon(Icons.inbox_rounded),
                        onPressed: onRequests,
                      ),
                  ],
                ),
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
