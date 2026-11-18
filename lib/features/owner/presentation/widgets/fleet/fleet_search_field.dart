import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';

/// Fleet search bar (user layout, 2026-11-18): the white bar under
/// the navy header — a search TextField (name or plate, actually
/// filtering the list) on the left, a VerticalDivider, then compact
/// Handover QR and Requests buttons on the right, plus an icon-only
/// Schedule (calendar) button first among them: the fleet calendar
/// is reachable ONLY from here (the header carries no icons — the
/// reference design shows title + Add Vehicle pill only). Extracted
/// from [OwnerFleetView] so the view stays under the 250-line cap.
///
/// Showroom redesign (Phase 2, 2026-11-16): Handover QR and
/// Requests live INSIDE this bar — the quick-actions row loses those
/// two buttons. Both are icon + short text (tooltip carries the
/// label); [onHandover]/[onRequests]/[onSchedule] are null in embeds
/// that render the field without navigation, and the buttons are then
/// hidden. The "Requests" button reads the `navRequests` label —
/// "Bookings" since batch 3 renamed the tab — not a new key.
///
/// DS-12: the inner TextField carries NO explicit border — its
/// InputDecoration leaves `border` null and the Theme override below
/// renders it borderless, so the theme border test still holds. The
/// bar's own shape (radius 16 + hairline) lives on the container,
/// the same card language as the rest of the screen.
class FleetSearchField extends StatelessWidget {
  final ValueChanged<String> onChanged;
  final VoidCallback? onSchedule;
  final VoidCallback? onHandover;
  final VoidCallback? onRequests;

  const FleetSearchField({
    super.key,
    required this.onChanged,
    this.onSchedule,
    this.onHandover,
    this.onRequests,
  });

  Widget _barButton(BuildContext context, {required Key key, required String tooltip, required IconData icon, required String label, required VoidCallback onPressed}) {
    // Flexible + FittedBox: the button scales its label down
    // instead of overflowing — at 360px / 1.35x / 200% text scale
    // the two buttons share the bar evenly with the search field
    // (1:1:1 flex), so nothing here can push the field to zero
    // width or spill past the bar edge.
    return Flexible(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Tooltip(
          message: tooltip,
          child: TextButton.icon(
            key: key,
            onPressed: onPressed,
            icon: Icon(icon, size: 18),
            label: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              minimumSize: const Size(0, 40),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ),
      ),
    );
  }

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
              // The field takes twice the flex of each text button,
              // so the icon-only Schedule button (40dp) never
              // squeezes it below a usable width at 360px.
              flex: 2,
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
            if (onSchedule != null || onHandover != null || onRequests != null) ...[
              const SizedBox(
                height: 24,
                child: VerticalDivider(width: 16, thickness: 1),
              ),
              if (onSchedule != null)
                IconButton(
                  key: const Key('fleet-action-schedule'),
                  tooltip: l10n.fleetSchedule,
                  icon: const Icon(Icons.calendar_month_rounded, size: 20),
                  onPressed: onSchedule!,
                  style: IconButton.styleFrom(minimumSize: const Size(40, 40), tapTargetSize: MaterialTapTargetSize.shrinkWrap, padding: const EdgeInsets.all(6)),
                ),
              if (onHandover != null)
                _barButton(context, key: const Key('fleet-action-handover'), tooltip: l10n.fleetHandoverQr, icon: Icons.qr_code_scanner_rounded, label: l10n.fleetHandoverQr, onPressed: onHandover!),
              if (onRequests != null)
                _barButton(context, key: const Key('fleet-action-requests'), tooltip: l10n.navRequests, icon: Icons.inbox_rounded, label: l10n.navRequests, onPressed: onRequests!),
            ],
          ],
        ),
      ),
    );
  }
}
