import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/money_format.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../../../bookings/utils/booking_next_step.dart';
import '../widgets/operations/approve_booking_sheet.dart';
import '../widgets/operations/booking_fare_breakdown.dart';
import '../widgets/operations/owner_add_payment_sheet.dart';
import '../widgets/operations/owner_booking_cancel.dart';
import '../widgets/operations/request_triage_actions.dart';

/// Unified Owner Booking Details page. Hosts all booking info (customer,
/// vehicle, dates, fare breakdown, status) and every owner action button
/// (Approve/Decline, Add Payment, Start Handover, Return & Settle,
/// Collect Dues, Cancel, View Dispute, Rate Customer) so the bookings
/// list stays clean and compact.
class OwnerBookingDetailView extends StatefulWidget {
  final BookingEntity booking;
  final VoidCallback? onBack;
  final FirebaseFirestore? firestore;

  const OwnerBookingDetailView({
    super.key,
    required this.booking,
    this.onBack,
    this.firestore,
  });

  @override
  State<OwnerBookingDetailView> createState() => _OwnerBookingDetailViewState();
}

class _OwnerBookingDetailViewState extends State<OwnerBookingDetailView> {
  late BookingEntity _booking;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _booking = widget.booking;
  }

  @override
  void didUpdateWidget(covariant OwnerBookingDetailView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.booking != widget.booking) _booking = widget.booking;
  }

  String _statusLabel(AppLocalizations l10n, String status) => {
        'requested': l10n.requestsStatusRequested,
        'payment_submitted': l10n.statusProofSubmitted,
        'approved': l10n.statusApproved,
        'paid': l10n.statusPaid,
        'active': l10n.active,
        'completed': l10n.statusCompleted,
        'rejected': l10n.statusRejected,
        'cancelled': l10n.statusCancelled,
        'disputed': l10n.statusDisputed,
      }[status] ??
      status;

  Future<void> _approve() async {
    final l10n = AppLocalizations.of(context)!;
    await showApproveBookingSheet(
      context,
      booking: _booking,
      firestore: widget.firestore,
      onApproved: (updated) {
        if (!mounted) return;
        setState(() => _booking = updated);
        AppFeedback.showSuccess(
            context, l10n.requestsApproved(updated.bookingId));
        goToAllOwnerBookings(context);
      },
    );
  }

  Future<void> _runAction(
    Future<BookingEntity?> Function() run, {
    bool goToAllOnDone = false,
  }) async {
    setState(() => _processing = true);
    final updated = await run();
    if (!mounted) return;
    setState(() {
      _processing = false;
      if (updated != null) _booking = updated;
    });
    if (updated != null && goToAllOnDone) goToAllOwnerBookings(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final b = _booking;
    final fmt = DateFormat('d MMM yyyy, h:mm a');
    final isWalkIn = b.origin == 'walk_in';
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            MinimalAppBar(
              title: l10n.ownerBookingDetailTitle,
              subtitle: '#${b.bookingId}',
              onBack: widget.onBack ?? () => context.pop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(
                          label: Text(_statusLabel(l10n, b.status)),
                          backgroundColor:
                              AppColors.successContainerFor(brightness),
                        ),
                        Chip(
                          label: Text(isWalkIn
                              ? l10n.bookingsTabWalkIn
                              : l10n.bookingsTabOnline),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          children: [
                            _row(context, l10n.requestsCustomerFallback,
                                b.customerName ?? '—'),
                            _row(context, l10n.kycWizardWhatsappNumber,
                                b.customerPhone ?? '—'),
                            if (b.customerCnic != null &&
                                b.customerCnic!.isNotEmpty)
                              _row(context, l10n.addCustomerCnic,
                                  b.customerCnic!),
                            const Divider(height: 18),
                            _row(context, l10n.summaryVehicle,
                                b.vehicleName ?? b.vehicleId),
                            if (b.vehiclePlate != null)
                              _row(
                                  context, l10n.summaryPlate, b.vehiclePlate!),
                            _row(context, l10n.packageLabel, b.packageType),
                            _row(context, l10n.bookingFarePickup,
                                fmt.format(b.pickupTime)),
                            _row(context, l10n.bookingFareReturn,
                                fmt.format(b.returnTime)),
                            const Divider(height: 18),
                            _row(context, l10n.bookingFareTotal,
                                l10n.amountRs(formatRs(b.totalAmount)),
                                bold: true),
                            _row(context, l10n.bookingFareAdvancePaid,
                                l10n.amountRs(formatRs(b.advancePaid))),
                            _row(context, l10n.bookingFareRemaining,
                                l10n.amountRs(formatRs(b.remainingBalance)),
                                bold: true),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    BookingFareBreakdown(booking: b),
                    if (b.rejectionReason != null &&
                        b.rejectionReason!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(b.rejectionReason!,
                          style: Theme.of(context).textTheme.bodyMedium),
                    ],
                    const SizedBox(height: 16),
                    RequestTriageActions(
                      booking: b,
                      isProcessing: _processing,
                      onApprove: _approve,
                      onReject: () => _runAction(
                        () => rejectBookingRequest(context, b),
                        goToAllOnDone: true,
                      ),
                      onRecordPayment: () => _runAction(
                          () => showOwnerAddPaymentSheet(context, booking: b)),
                      onCancel: () => _runAction(
                        () => cancelWalkInBooking(context, b),
                        goToAllOnDone: true,
                      ),
                      onVerifyProof: () => context.push(RouteNames
                          .ownerRequestsDetail
                          .replaceFirst(':id', b.bookingId)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value,
      {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: TextStyle(
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
