import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../bookings/domain/entities/booking_entity.dart';
import 'dashboard_ledger_item.dart';

/// E1: the dashboard's "Completed Trip Ledger & Settlements" section,
/// extracted verbatim from [OwnerDashboardView] so the view stays under
/// the 250-line cap once the quick-action tiles are added. No behaviour
/// change: [ledger] is the newest-first top 8, [isEmpty] is whether the
/// shop has any bookings at all.
class DashboardLedgerSection extends StatelessWidget {
  const DashboardLedgerSection({
    super.key,
    required this.isEmpty,
    required this.ledger,
  });

  final bool isEmpty;
  final List<BookingEntity> ledger;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.dashboardLedgerTitle,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        if (isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(l10n.dashboardLedgerEmpty,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700)),
            ),
          )
        else
          ...ledger.map((b) => DashboardLedgerItem(
                bookingId: b.bookingId,
                vehicleName: b.vehicleName ?? l10n.dashboardLedgerVehicle,
                customerName: b.customerName ?? l10n.dashboardLedgerCustomer,
                amount: b.totalAmount,
                status: b.status,
              )),
      ],
    );
  }
}
