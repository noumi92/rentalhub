import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';

/// Phone-test round 4: the fleet tab's quick-action row, rendered
/// directly beneath the KPI tiles ([FleetMetricsRow]).
///
/// Five icon + short-label actions to the sub-screens the fleet tab
/// already connects to. The row scrolls horizontally so it can never
/// overflow at narrow widths or large text scales. Labels are 12sp
/// regular, never bold; Handover is the filled primary action, the
/// rest are tonal.
///
/// Destinations (all real routes, no dead buttons):
/// * Handover — the QR scan (`/owner/scan`); scanning a booking QR
///   opens that booking's handover screen, so the scan is the
///   fleet-level handover entry point (there is no booking id to
///   open `/owner/handover/:id` with from here).
/// * Requests — the booking-requests triage list (`/owner/requests`).
/// * Add Vehicle — the gated add flow (approval + plan car cap).
/// * Schedule — the multi-car fleet calendar (`/owner/fleet/calendar`).
/// * Customers — the customers list (`/owner/customers`).
class FleetQuickActions extends StatelessWidget {
  const FleetQuickActions({
    super.key,
    required this.onHandover,
    required this.onRequests,
    required this.onAddVehicle,
    required this.onSchedule,
    required this.onCustomers,
  });

  final VoidCallback onHandover;
  final VoidCallback onRequests;
  final VoidCallback onAddVehicle;
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
            key: const Key('fleet-action-handover'),
            onPressed: onHandover,
            icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
            label: Text(l10n.dashboardScheduleHandover, style: labelStyle),
          ),
          const SizedBox(width: 8),
          FilledButton.tonalIcon(
            key: const Key('fleet-action-requests'),
            onPressed: onRequests,
            icon: const Icon(Icons.inbox_rounded, size: 18),
            label: Text(l10n.navRequests, style: labelStyle),
          ),
          const SizedBox(width: 8),
          FilledButton.tonalIcon(
            key: const Key('fleet-action-add-vehicle'),
            onPressed: onAddVehicle,
            icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
            label: Text(l10n.fleetAddVehicle, style: labelStyle),
          ),
          const SizedBox(width: 8),
          FilledButton.tonalIcon(
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
