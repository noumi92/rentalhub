import 'package:flutter/material.dart';

import '../../../../core/utils/date_format.dart';
import '../../../../core/utils/money_format.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../customer/utils/customer_grouping.dart';
import 'customer_active_rental_banner.dart';
import 'customer_list_card_header.dart';
import 'customer_row_book_action.dart';

/// Walk-in CRM extraction from [OwnerCustomersListView] (250-line
/// cap): one customer row — the card, its header badges, the
/// expanded bookings and the Book action. The list view owns the
/// filtering and passes the already-derived per-row flags in
/// ([blacklisted], [blocked], [kycIncomplete], [dormant]); this
/// widget only renders.
class CustomerListRowCard extends StatelessWidget {
  const CustomerListRowCard({
    super.key,
    required this.customer,
    required this.blacklisted,
    required this.blocked,
    required this.kycIncomplete,
    required this.dormant,
    required this.expanded,
    required this.onToggleExpand,
    required this.isLast,
  });

  final CustomerSummary customer;
  final bool blacklisted;
  final bool blocked;
  final bool kycIncomplete;
  final bool dormant;
  final bool expanded;
  final VoidCallback onToggleExpand;

  /// The last card carries no bottom margin — the list padding
  /// (16 dp) is the bottom gap (BP-14).
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = customer;
    return Card(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Column(
        children: [
          CustomerListCardHeader(
            customer: c,
            blacklisted: blacklisted,
            blocked: blocked,
            kycIncomplete: kycIncomplete,
            dormant: dormant,
            expanded: expanded,
            onTap: onToggleExpand,
          ),
          // Phase 3: the mint active-rental banner (from the
          // already-loaded bookings — no new fetch) renders only
          // when an active booking exists; ALL bookings are still
          // listed below it.
          if (expanded) CustomerActiveRentalBanner(bookings: c.bookings),
          if (expanded)
            ...c.bookings.map((b) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.receipt_long_rounded, size: 18),
                  title: Text('${b.vehicleName ?? l10n.summaryVehicle} • ${b.packageType}', maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text('${formatDate(context, b.pickupTime)} • ${_statusLabel(l10n, b.status)}', maxLines: 2, overflow: TextOverflow.ellipsis), // Audit 2026-11-15 DS-5: localized date, never raw d/m/y.
                  // C5: grouped amount.
                  trailing: Text(l10n.amountRs(formatRs(b.totalAmount)), style: const TextStyle(fontWeight: FontWeight.w600)),
                )),
          if (expanded && c.bookings.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(l10n.customersNoBookings, style: Theme.of(context).textTheme.bodySmall),
            ),
          // #18: Book for this customer — wizard opens prefilled
          // (name, phone, CNIC); adding the customer itself stays
          // a separate step.
          if (expanded) CustomerRowBookAction(customer: c),
        ],
      ),
    );
  }
}

/// Stored booking statuses mapped to localized labels — the stored
/// value itself is never changed.
String _statusLabel(AppLocalizations l10n, String status) => {'requested': l10n.requestsStatusRequested, 'payment_submitted': l10n.statusProofSubmitted, 'approved': l10n.statusApproved, 'paid': l10n.statusPaid, 'active': l10n.active, 'completed': l10n.statusCompleted, 'rejected': l10n.statusRejected, 'cancelled': l10n.statusCancelled}[status] ?? status;
