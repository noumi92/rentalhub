import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/money_format.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../../../customer/domain/entities/customer_entity.dart';
import '../widgets/customer_blocked_banner.dart';
import '../widgets/customer_derived_status.dart';
import '../widgets/customer_detail_actions.dart';
import '../widgets/customer_detail_bookings_section.dart';
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
    this.onReload,
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
  final VoidCallback? onReload;

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
            if (!blockedOrArchived) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const ValueKey('customer_detail_new_booking'),
                  onPressed: () => context.push(
                    '${RouteNames.ownerManualBooking}?customerId=${Uri.encodeComponent(customer.customerId)}',
                  ),
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                  label: Text(l10n.walkInNewBookingForCustomer),
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (customer.guarantorCustomerId != null &&
                customer.guarantorCustomerId!.isNotEmpty) ...[
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.verified_user_outlined, size: 18),
                title: Text(l10n.walkInGuarantorLabel,
                    style: const TextStyle(fontWeight: FontWeight.w500)),
                subtitle: Text(
                  '${customer.guarantorRelation ?? l10n.kycWizardRelationOther} • ${customer.guarantorCustomerId}',
                ),
              ),
            ],
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
          CustomerDetailBookingsSection(
            bookings: bookings,
            onBookingUpdated: onReload,
          ),
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
