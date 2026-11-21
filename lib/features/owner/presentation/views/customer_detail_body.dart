import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../core/utils/money_format.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../../../customer/domain/entities/customer_entity.dart';
import '../widgets/customer_blocked_banner.dart';
import '../widgets/customer_derived_status.dart';
import '../widgets/customer_detail_actions.dart';
import '../widgets/customer_detail_header.dart';
import '../widgets/customer_detail_kyc_section.dart';

/// The scroll content of the customer detail screen, extracted
/// from [OwnerCustomerDetailView] so the view stays under the
/// 250-line cap: identity header + status chips, blocked/archived
/// banner, KYC grid (tappable for walk-in replace), totals, rental
/// history and the action row. Pure view — all state and callbacks
/// come from the parent.
class CustomerDetailBody extends StatelessWidget {
  const CustomerDetailBody({
    super.key,
    required this.customer,
    required this.bookings,
    required this.blacklisted,
    required this.shopId,
    required this.acting,
    required this.onApprove,
    required this.onReject,
    required this.onBlockToggle,
    required this.onEdit,
    required this.onArchive,
    required this.onReplaceSlot,
  });

  final CustomerEntity customer;
  final List<BookingEntity> bookings;
  final bool blacklisted;

  /// Canonical shop id, for the per-shop status + derived chips.
  final String shopId;
  final bool acting;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onBlockToggle;
  final VoidCallback onEdit;
  final VoidCallback onArchive;

  /// Field name of the tapped KYC slot, or null to keep the grid
  /// display-only (online customers).
  final ValueChanged<String>? onReplaceSlot;

  static const _dueStatuses = {'approved', 'paid', 'active', 'completed'};

  int get _totalSpent => bookings.fold(0, (s, b) => s + b.totalAmount);
  int get _totalDues => bookings.where((b) => _dueStatuses.contains(b.status) && b.remainingBalance > 0).fold(0, (s, b) => s + b.remainingBalance);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final statuses = derivedCustomerStatuses(
        customer: customer, bookings: bookings, shopId: shopId);
    final isWalkIn = customer.source == 'walk_in';
    final blockedOrArchived = statuses.shopStatus == CustomerEntity.statusBlocked ||
        statuses.shopStatus == CustomerEntity.statusArchived;
    return SingleChildScrollView(
      // Pull-to-refresh (user layout, 2026-11-16): the scroll view
      // must stay draggable even when the content is short, or the
      // RefreshIndicator above it never triggers.
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Phase 3: slim identity card + merged red alert banner
          // (rejection reason + KYC status together).
          CustomerDetailHeader(
            customer: customer,
            blacklisted: blacklisted,
            shopStatus: statuses.shopStatus,
            kycIncomplete: statuses.kycIncomplete,
            dormant: statuses.dormant,
            frequent: statuses.frequent,
          ),
          if (blockedOrArchived) ...[
            const SizedBox(height: 16),
            CustomerBlockedBanner(shopStatus: statuses.shopStatus),
          ],
          const SizedBox(height: 16),
          // Phase 3: KYC header carries the real uploaded count
          // (e.g. "KYC Documents (3/11 Uploaded)") over the 3x4
          // dashed grid of all 11 tracked slots. Walk-in only:
          // tapping a tile replaces that slot in place.
          CustomerDetailKycSection(
            customer: customer,
            onReplaceSlot: isWalkIn ? onReplaceSlot : null,
          ),
          const SizedBox(height: 8),
          Row(children: [Expanded(child: Text(l10n.customerDetailTotalSpent, style: const TextStyle(fontWeight: FontWeight.w500))), Text(l10n.amountRs(formatRs(_totalSpent)), style: const TextStyle(fontWeight: FontWeight.w500))]),
          const SizedBox(height: 4),
          Row(children: [Expanded(child: Text(l10n.customerDetailTotalDues, style: const TextStyle(fontWeight: FontWeight.w500))), Text(l10n.amountRs(formatRs(_totalDues)), style: const TextStyle(fontWeight: FontWeight.w500))]),
          const SizedBox(height: 16),
          // Worker C: walk-in wallets are shop-managed — the owner
          // opens this customer's Security wallet here. Online
          // customers maintain their own wallet, so no entry point
          // is offered for them (and the view refuses them too).
          if (isWalkIn) ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.account_balance_wallet_outlined, size: 18),
              title: Text(l10n.customerDetailSecurityWallet, style: const TextStyle(fontWeight: FontWeight.w500)),
              trailing: const Icon(Icons.chevron_right_rounded, size: 20),
              onTap: () => context.push(
                RouteNames.ownerCustomerSecurityWallet.replaceFirst(':id', customer.customerId),
                extra: customer,
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text(l10n.customerDetailRentalHistory, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          if (bookings.isEmpty)
            Text(l10n.customersNoBookings, style: Theme.of(context).textTheme.bodySmall)
          else
            ...bookings.map((b) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.receipt_long_rounded, size: 18),
                  title: Text('${b.vehicleName ?? l10n.summaryVehicle} • ${b.packageType}'),
                  subtitle: Text('${formatDate(context, b.pickupTime)} • ${_statusLabel(l10n, b.status)}'), // Audit 2026-11-15 DS-5: localized date, never raw d/m/y.
                  trailing: Text(l10n.amountRs(formatRs(b.totalAmount)), style: const TextStyle(fontWeight: FontWeight.w600)),
                )),
          const SizedBox(height: 16),
          CustomerDetailActions(
            isWalkIn: isWalkIn,
            approvalStatus: customer.approvalStatus,
            shopStatus: statuses.shopStatus,
            acting: acting,
            onApprove: onApprove,
            onReject: onReject,
            onBlockToggle: onBlockToggle,
            onEdit: onEdit,
            onArchive: onArchive,
          ),
        ],
      ),
    );
  }
}

/// Stored booking statuses mapped to localized labels — the stored
/// value itself is never changed.
String _statusLabel(AppLocalizations l10n, String status) => {'requested': l10n.requestsStatusRequested, 'payment_submitted': l10n.statusProofSubmitted, 'approved': l10n.statusApproved, 'paid': l10n.statusPaid, 'active': l10n.active, 'completed': l10n.statusCompleted, 'rejected': l10n.statusRejected, 'cancelled': l10n.statusCancelled}[status] ?? status;
