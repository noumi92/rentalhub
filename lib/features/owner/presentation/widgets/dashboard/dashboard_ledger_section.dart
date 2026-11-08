import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/routing/route_names.dart';
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
        // Audit fix (§2): the ledger shows the newest 8 only — a
        // "View all requests" row links to the full Requests tab, so
        // the history is discoverable instead of hidden behind the tab.
        if (!isEmpty)
          InkWell(
            onTap: () => context.go(RouteNames.ownerRequests),
            child: Padding(
              // 15 px vertical padding puts the row at the §4.6 48 dp
              // minimum tap height.
              padding: const EdgeInsets.symmetric(vertical: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.dashboardViewAllRequests,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
