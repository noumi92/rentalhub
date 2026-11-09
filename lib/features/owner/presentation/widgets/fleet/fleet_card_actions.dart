import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';

/// Audit §5 (O05/O30): the fleet card's action rows, extracted from
/// [FleetVehicleCard] so the card stays under the 250-line cap. Row 1
/// is the existing Edit rates / Booking calendar pair; row 2 is the
/// deck's literal "Edit Rent" (→ rate matrix) and "Update Price"
/// (→ fare table) actions. The second row only renders when at least
/// one of its callbacks is provided (tests render the card without it).
class FleetCardActions extends StatelessWidget {
  const FleetCardActions({
    super.key,
    required this.onEditRates,
    required this.onViewCalendar,
    this.onEditRent,
    this.onUpdatePrice,
  });

  final VoidCallback onEditRates;
  final VoidCallback onViewCalendar;
  final VoidCallback? onEditRent;
  final VoidCallback? onUpdatePrice;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(icon: const Icon(Icons.tune_rounded, size: 18), label: Text(l10n.fleetEditRatesTooltip), onPressed: onEditRates),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(icon: const Icon(Icons.calendar_month_rounded, size: 18), label: Text(l10n.fleetCalendarTooltip), onPressed: onViewCalendar),
              ),
            ],
          ),
          if (onEditRent != null || onUpdatePrice != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (onEditRent != null)
                  Expanded(
                    child: OutlinedButton.icon(icon: const Icon(Icons.edit_rounded, size: 18), label: Text(l10n.fleetEditRent), onPressed: onEditRent),
                  ),
                if (onEditRent != null && onUpdatePrice != null) const SizedBox(width: 8),
                if (onUpdatePrice != null)
                  Expanded(
                    child: OutlinedButton.icon(icon: const Icon(Icons.price_change_rounded, size: 18), label: Text(l10n.fleetUpdatePrice), onPressed: onUpdatePrice),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
