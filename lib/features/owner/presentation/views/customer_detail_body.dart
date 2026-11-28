import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../../../customer/domain/entities/customer_entity.dart';
import '../widgets/customer_blocked_banner.dart';
import '../widgets/customer_derived_status.dart';
import '../widgets/customer_detail_actions.dart';
import '../widgets/customer_detail_bookings_section.dart';
import '../widgets/customer_detail_header.dart';
import '../widgets/customer_detail_kpi_and_tabs.dart';
import '../widgets/customer_detail_kyc_section.dart';
import '../widgets/customer_detail_personal_tab.dart';

/// Minimalist CRM customer detail body: hero header with actionable KYC
/// banner, 3-column bento KPI row, full-width terracotta "New Booking" CTA,
/// animated 3-tab segmented switcher, and tab content.
class CustomerDetailBody extends StatefulWidget {
  const CustomerDetailBody({
    super.key,
    required this.customer,
    this.guarantor,
    required this.bookings,
    required this.blacklisted,
    required this.shopId,
    required this.acting,
    required this.onApprove,
    required this.onReject,
    required this.onBlockToggle,
    required this.onEdit,
    this.onEditGuarantor,
    required this.onArchive,
    required this.onReplaceSlot,
    this.onReload,
  });

  final CustomerEntity customer;
  final CustomerEntity? guarantor;
  final List<BookingEntity> bookings;
  final bool blacklisted;
  final String shopId;
  final bool acting;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onBlockToggle;
  final VoidCallback onEdit;
  final VoidCallback? onEditGuarantor;
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
            onAddKyc: () => setState(() => _tabIndex = 2),
          ),
          if (blockedOrArchived) ...[
            const SizedBox(height: 12),
            CustomerBlockedBanner(shopStatus: statuses.shopStatus),
          ],
          const SizedBox(height: 14),
          CustomerDetailKpiRow(
            bookingCount: widget.bookings.length,
            totalSpent: _totalSpent,
            totalDues: _totalDues,
          ),
          if (isWalkIn && !blockedOrArchived) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                key: const ValueKey('customer_detail_new_booking'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.orangeFill,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => context.push(
                  '${RouteNames.ownerManualBooking}?customerId=${Uri.encodeComponent(customer.customerId)}',
                ),
                icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                label: Text(
                  l10n.walkInNewBookingForCustomer,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          CustomerDetailSegmentedTabs(
            tabs: [
              l10n.customersTabBookings,
              l10n.customersTabPersonal,
              l10n.customersTabKyc,
            ],
            selectedIndex: _tabIndex,
            onChanged: (i) => setState(() => _tabIndex = i),
          ),
          const SizedBox(height: 16),
          if (_tabIndex == 0)
            CustomerDetailBookingsSection(
              bookings: widget.bookings,
              onBookingUpdated: widget.onReload,
            )
          else if (_tabIndex == 1)
            CustomerDetailPersonalTab(
              customer: customer,
              guarantor: widget.guarantor,
              isWalkIn: isWalkIn,
              onAddOrEditGuarantor: isWalkIn ? widget.onEditGuarantor : null,
            )
          else
            CustomerDetailKycSection(
              customer: customer,
              onReplaceSlot: isWalkIn ? widget.onReplaceSlot : null,
            ),
          if (!isWalkIn) ...[
            const SizedBox(height: 20),
            CustomerDetailActions(
              isWalkIn: false,
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
        ],
      ),
    );
  }
}
