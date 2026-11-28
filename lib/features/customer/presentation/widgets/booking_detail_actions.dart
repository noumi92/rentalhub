import 'package:flutter/material.dart';

import '../../../../core/widgets/debounced_button.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../../../bookings/utils/booking_next_step.dart';
import '../../../../l10n/app_localizations.dart';

/// The status-driven actions for one booking. Extracted from
/// [CustomerBookingDetailView] so the view stays under the
/// 250-line cap (rulebook §2.2).
///
/// Next-step batch (2026-11-21): the primary action comes from
/// [resolveCustomerNextStep] — the same resolver the list card
/// uses, so card and detail can never disagree about what comes
/// next. `requested` and `payment_submitted` have no primary:
/// requested shows the "Waiting for approval" line, and
/// payment_submitted is covered by the detail view's
/// "Proof with shop" info card (there is no customer
/// proof-viewer route, so no button is offered there).
class BookingDetailActions extends StatelessWidget {
  const BookingDetailActions({
    super.key,
    required this.booking,
    this.onPayAdvance,
    this.onViewPass,
    this.onViewActiveTrip,
    this.onTrackDispute,
    this.onCancel,
    this.onRateTrip,
    this.onFileDispute,
    this.onBrowseShops,
  });

  final BookingEntity booking;
  final VoidCallback? onPayAdvance;
  final VoidCallback? onViewPass;
  final VoidCallback? onViewActiveTrip;
  final VoidCallback? onTrackDispute;
  final VoidCallback? onCancel;
  final VoidCallback? onRateTrip;
  final VoidCallback? onFileDispute;
  final VoidCallback? onBrowseShops;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: _actions(context, AppLocalizations.of(context)!),
    );
  }

  List<Widget> _actions(BuildContext context, AppLocalizations l10n) {
    final step = resolveCustomerNextStep(booking);
    final widgets = <Widget>[];

    // The primary next step, from the shared resolver.
    switch (step.kind) {
      case BookingNextStepKind.payAdvance:
        if (onPayAdvance != null) {
          widgets.add(DebouncedButton(
            text: step.label(l10n, booking),
            icon: Icons.payment_rounded,
            onPressed: () async => onPayAdvance!.call(),
          ));
        }
      case BookingNextStepKind.viewPass:
        if (onViewPass != null) {
          widgets.add(DebouncedButton(
            text: step.label(l10n, booking),
            icon: Icons.qr_code_rounded,
            onPressed: () async => onViewPass!.call(),
          ));
        }
      case BookingNextStepKind.viewActiveTrip:
        if (onViewActiveTrip != null) {
          widgets.add(DebouncedButton(
            text: step.label(l10n, booking),
            icon: Icons.directions_car_rounded,
            onPressed: () async => onViewActiveTrip!.call(),
          ));
        }
      case BookingNextStepKind.rateTrip:
        if (onRateTrip != null) {
          widgets.add(DebouncedButton(
            text: step.label(l10n, booking),
            icon: Icons.star_rounded,
            onPressed: () async => onRateTrip!.call(),
          ));
        }
      case BookingNextStepKind.trackDispute:
        if (onTrackDispute != null) {
          widgets.add(DebouncedButton(
            text: step.label(l10n, booking),
            icon: Icons.gavel_rounded,
            onPressed: () async => onTrackDispute!.call(),
          ));
        }
      case BookingNextStepKind.browseShops:
        if (onBrowseShops != null) {
          widgets.add(DebouncedButton(
            text: step.label(l10n, booking),
            icon: Icons.search_rounded,
            onPressed: () async => onBrowseShops!.call(),
          ));
        }
      case BookingNextStepKind.fileDispute:
        if (onFileDispute != null) {
          widgets.add(OutlinedButton.icon(
            onPressed: onFileDispute,
            icon: const Icon(Icons.report_problem_outlined),
            label: Text(l10n.fileDispute),
          ));
        }
      case BookingNextStepKind.none:
      case BookingNextStepKind.approve:
      case BookingNextStepKind.verifyProof:
      case BookingNextStepKind.recordPayment:
      case BookingNextStepKind.startHandover:
      case BookingNextStepKind.returnSettlement:
      case BookingNextStepKind.viewDispute:
      case BookingNextStepKind.rateCustomer:
        // Owner-only kinds — the customer resolver never returns
        // them — and `none` (requested / payment_submitted):
        // no primary action.
        break;
    }

    // `requested`: no primary — the ball is in the shop's court.
    if (booking.status == 'requested') {
      widgets.add(Text(
        l10n.nextStepWaitingApproval,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ));
    }

    // Secondary actions: Cancel while the booking can still be
    // called off, File a Dispute once the trip is done.
    if (booking.status == 'requested' || booking.status == 'approved') {
      if (onCancel != null) {
        if (widgets.isNotEmpty) widgets.add(const SizedBox(height: 10));
        widgets.add(
          booking.status == 'requested'
              ? DebouncedButton(
                  text: l10n.cancelBooking,
                  icon: Icons.cancel_outlined,
                  onPressed: () async => onCancel!.call(),
                )
              : OutlinedButton.icon(
                  onPressed: onCancel,
                  icon: const Icon(Icons.cancel_outlined),
                  label: Text(l10n.cancelBooking),
                ),
        );
      }
    }
    if (booking.status == 'completed' && onFileDispute != null) {
      if (widgets.isNotEmpty) widgets.add(const SizedBox(height: 10));
      widgets.add(OutlinedButton.icon(
        onPressed: onFileDispute,
        icon: const Icon(Icons.report_problem_outlined),
        label: Text(l10n.fileDispute),
      ));
    }
    return widgets;
  }
}
