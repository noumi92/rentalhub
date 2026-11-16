import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';

/// Phone-test round 4: the fleet tab's quick-action row, rendered
/// directly beneath the segmented filter bar ([FleetFilterChips]).
///
/// Showroom redesign (Phase 2, 2026-11-16): Handover QR and Requests
/// moved INTO the search bar ([FleetSearchField]) and Add Vehicle
/// moved to the orange pill in the AppBar — this row keeps only the
/// two remaining actions, Schedule and Customers. Labels are 12sp
/// regular, never bold; Schedule is the filled primary action.
///
/// Destinations (all real routes, no dead buttons):
/// * Schedule — the multi-car fleet calendar (`/owner/fleet/calendar`).
/// * Customers — the customers list (`/owner/customers`).
class FleetQuickActions extends StatelessWidget {
  const FleetQuickActions({
    super.key,
    required this.onSchedule,
    required this.onCustomers,
  });

  final VoidCallback onSchedule;
  final VoidCallback onCustomers;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Small regular labels — labelMedium is already 12sp, so only the
    // weight is overridden (no ad-hoc size here: the typography test
    // caps ad-hoc sizes at 40). The icon carries the emphasis, not
    // the text weight.
    final labelStyle = Theme.of(context).textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w400,
        );
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          FilledButton.icon(
            key: const Key('fleet-action-schedule'),
            onPressed: onSchedule,
            icon: const Icon(Icons.calendar_month_rounded, size: 18),
            label: Text(l10n.fleetSchedule, style: labelStyle),
          ),
          const SizedBox(width: 8),
          FilledButton.tonalIcon(
            key: const Key('fleet-action-customers'),
            onPressed: onCustomers,
            icon: const Icon(Icons.people_outline_rounded, size: 18),
            label: Text(l10n.customersTitle, style: labelStyle),
          ),
        ],
      ),
    );
  }
}
