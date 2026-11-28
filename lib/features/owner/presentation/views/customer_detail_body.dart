import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
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
import '../widgets/customer_detail_personal_tab.dart';

/// Redesigned CRM customer detail body: compact profile header, 3-KPI
/// summary strip, quick "+ New Booking" CTA for walk-ins, and 3 clean
/// horizontal tabs (Bookings | Personal Info | KYC & Docs), followed
/// by customer management actions.
class CustomerDetailBody extends StatefulWidget {
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
  final String shopId;
  final bool acting;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onBlockToggle;
  final VoidCallback onEdit;
  final VoidCallback onArchive;
  final ValueChanged<String>? onReplaceSlot;
  final VoidCallback? onReload;

  @override
  State<CustomerDetailBody> createState() => _CustomerDetailBodyState();
}

class _CustomerDetailBodyState extends State<CustomerDetailBody> {
  static const _dueStatuses = {'approved', 'paid', 'active', 'completed'};
  int _tabIndex = 0;

  int get _totalSpent => widget.bookings.fold(0, (s, b) => s + b.totalAmount);
  int get _totalDues => widget.bookings
      .where((b) => _dueStatuses.contains(b.status) && b.remainingBalance > 0)
      .fold(0, (s, b) => s + b.remainingBalance);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final customer = widget.customer;
    final statuses = derivedCustomerStatuses(
      customer: customer,
      bookings: widget.bookings,
      shopId: widget.shopId,
    );
    final isWalkIn = customer.source == 'walk_in';
    final blockedOrArchived =
        statuses.shopStatus == CustomerEntity.statusBlocked ||
            statuses.shopStatus == CustomerEntity.statusArchived;

    final tabs = [
      (Icons.receipt_long_rounded, l10n.customersTabBookings),
      (Icons.person_outline_rounded, l10n.customersTabPersonal),
      (Icons.badge_outlined, l10n.customersTabKyc),
    ];

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomerDetailHeader(
            customer: customer,
            blacklisted: widget.blacklisted,
            shopStatus: statuses.shopStatus,
            kycIncomplete: statuses.kycIncomplete,
            dormant: statuses.dormant,
            frequent: statuses.frequent,
          ),
          if (blockedOrArchived) ...[
            const SizedBox(height: 12),
            CustomerBlockedBanner(shopStatus: statuses.shopStatus),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              _kpiTile(context, l10n.customersTabBookings,
                  '${widget.bookings.length}'),
              const SizedBox(width: 8),
              _kpiTile(context, l10n.customerDetailTotalSpent,
                  l10n.amountRs(formatRs(_totalSpent))),
              const SizedBox(width: 8),
              _kpiTile(
                context,
                l10n.customerDetailTotalDues,
                l10n.amountRs(formatRs(_totalDues)),
                highlight: _totalDues > 0,
              ),
            ],
          ),
          if (isWalkIn && !blockedOrArchived) ...[
            const SizedBox(height: 12),
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
          ],
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < tabs.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  ChoiceChip(
                    key: ValueKey('customer_detail_tab_$i'),
                    avatar: Icon(tabs[i].$1, size: 16),
                    label: Text(tabs[i].$2),
                    selected: _tabIndex == i,
                    onSelected: (_) => setState(() => _tabIndex = i),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (_tabIndex == 0)
            CustomerDetailBookingsSection(
              bookings: widget.bookings,
              onBookingUpdated: widget.onReload,
            )
          else if (_tabIndex == 1)
            CustomerDetailPersonalTab(
              customer: customer,
              isWalkIn: isWalkIn,
            )
          else
            CustomerDetailKycSection(
              customer: customer,
              onReplaceSlot: isWalkIn ? widget.onReplaceSlot : null,
            ),
          const SizedBox(height: 20),
          CustomerDetailActions(
            isWalkIn: isWalkIn,
            approvalStatus: customer.approvalStatus,
            shopStatus: statuses.shopStatus,
            acting: widget.acting,
            onApprove: widget.onApprove,
            onReject: widget.onReject,
            onBlockToggle: widget.onBlockToggle,
            onEdit: widget.onEdit,
            onArchive: widget.onArchive,
          ),
        ],
      ),
    );
  }

  Widget _kpiTile(
    BuildContext context,
    String label,
    String value, {
    bool highlight = false,
  }) {
    final brightness = Theme.of(context).brightness;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: highlight
              ? AppColors.orangeContainerFor(brightness)
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: highlight
                        ? AppColors.orangeTextFor(brightness)
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: highlight
                        ? AppColors.orangeTextFor(brightness)
                        : null,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
