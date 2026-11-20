import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';

/// Fleet search bar (user layout, 2026-11-18): the white bar under
/// the navy header — a search TextField (name or plate, actually
/// filtering the list) with a magnifier prefix icon. Extracted
/// from [OwnerFleetView] so the view stays under the 250-line cap.
///
/// Item 1 (2026-11-20): the Schedule (calendar) and Handover QR
/// action buttons that used to sit inside this bar are REMOVED —
/// the user called them duplicates. Both destinations stay
/// reachable elsewhere, so nothing is orphaned: the fleet calendar
/// (`/owner/fleet/calendar`) from the Bookings screen app-bar
/// calendar icon, and the QR scan (`/owner/scan`) from the
/// Dashboard "Scan QR" quick action, the Bookings app-bar QR icon,
/// and the booking-confirmed screen. The search field itself (with
/// its magnifier prefix) is the search affordance, not a duplicate
/// action, and stays.
///
/// DS-12: the inner TextField carries NO explicit border — its
/// InputDecoration leaves `border` null and the Theme override below
/// renders it borderless, so the theme border test still holds. The
/// bar's own shape (radius 16 + hairline) lives on the container,
/// the same card language as the rest of the screen.
class FleetSearchField extends StatelessWidget {
  final ValueChanged<String> onChanged;

  const FleetSearchField({
    super.key,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          children: [
            Expanded(
              // Borderless inner field: the Theme override renders
              // no input border (DS-12 checks the widget's own
              // decoration.border is null, which still holds — the
              // shape lives on the container above).
              child: Theme(
                data: Theme.of(context).copyWith(
                  inputDecorationTheme: const InputDecorationTheme(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                  ),
                ),
                child: TextField(
                  onChanged: onChanged,
                  decoration: InputDecoration(
                    hintText: l10n.fleetSearchHint,
                    prefixIcon: const Icon(Icons.search_rounded),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
