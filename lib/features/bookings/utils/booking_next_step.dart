import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/route_names.dart';
import '../../../core/utils/money_format.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/entities/booking_entity.dart';

/// "All Bookings" — the owner Requests list with the ALL filter
/// selected. Every booking-flow save navigates here (with [go],
/// never [pop]) so the just-saved booking — whose new status is
/// usually NOT in the Proof bucket the list defaults to — is
/// visible at once. The list is stream-driven, so the fresh
/// navigation reflects the write.
void goToAllOwnerBookings(BuildContext context) {
  context.go('${RouteNames.ownerRequests}?filter=all');
}

/// The single primary next step for a booking, resolved from its status
/// (plus origin/role where it matters). The owner triage card, the
/// owner detail path, the customer list card and the customer detail
/// actions ALL call this resolver, so card and detail can never
/// disagree about what comes next in the booking journey.
///
/// The resolver returns the step kind and (where it is a navigation)
/// the route; the caller maps the kind to the action. `approve` has
/// no route — the caller opens the approve sheet.
enum BookingNextStepKind {
  none,
  approve,
  verifyProof,
  recordPayment,
  startHandover,
  returnSettlement,
  viewDispute,
  rateCustomer,
  payAdvance,
  viewPass,
  viewActiveTrip,
  rateTrip,
  trackDispute,
  browseShops,
  fileDispute,
}

class BookingNextStep {
  const BookingNextStep(this.kind);

  final BookingNextStepKind kind;

  bool get hasAction => kind != BookingNextStepKind.none;

  /// Route template with a `:id` placeholder, or null when the action
  /// is a callback/sheet handled by the caller (approve).
  String? get route {
    switch (kind) {
      case BookingNextStepKind.verifyProof:
        return RouteNames.ownerRequestsDetail;
      case BookingNextStepKind.startHandover:
        return RouteNames.ownerHandover;
      case BookingNextStepKind.returnSettlement:
        return RouteNames.ownerReturnLanding;
      case BookingNextStepKind.viewDispute:
        return RouteNames.ownerDisputes;
      case BookingNextStepKind.rateCustomer:
        return RouteNames.ownerRateCustomer;
      case BookingNextStepKind.payAdvance:
        return RouteNames.customerBookingApproved;
      case BookingNextStepKind.viewPass:
        return RouteNames.customerPickupPass;
      case BookingNextStepKind.viewActiveTrip:
        return RouteNames.customerActiveTrip;
      case BookingNextStepKind.rateTrip:
        return RouteNames.customerRateTrip;
      case BookingNextStepKind.trackDispute:
        return RouteNames.customerDisputes;
      case BookingNextStepKind.browseShops:
        return RouteNames.customerHome;
      case BookingNextStepKind.fileDispute:
        return RouteNames.customerDisputes;
      case BookingNextStepKind.approve:
      case BookingNextStepKind.recordPayment:
      case BookingNextStepKind.none:
        return null;
    }
  }

  /// Destination with the booking id substituted, or null when the
  /// step has no route.
  String? destination(BookingEntity booking) {
    final r = route;
    if (r == null) return null;
    return r.replaceFirst(':id', booking.bookingId);
  }

  String label(AppLocalizations l10n, BookingEntity booking) {
    switch (kind) {
      case BookingNextStepKind.approve:
        return l10n.requestsApprovePay;
      case BookingNextStepKind.verifyProof:
        return l10n.requestsVerifyProof;
      case BookingNextStepKind.recordPayment:
        return l10n.walkInAddPayment;
      case BookingNextStepKind.startHandover:
        return l10n.bookingConfirmedStartHandover;
      case BookingNextStepKind.returnSettlement:
        return l10n.contractProceedReturn;
      case BookingNextStepKind.viewDispute:
        return l10n.nextStepViewResolveDispute;
      case BookingNextStepKind.rateCustomer:
        return l10n.rateCustomer;
      case BookingNextStepKind.payAdvance:
        return l10n.payAdvanceAmount(formatRs(booking.advanceRequired));
      case BookingNextStepKind.viewPass:
        return l10n.viewPickupPass;
      case BookingNextStepKind.viewActiveTrip:
        return l10n.nextStepViewActiveTrip;
      case BookingNextStepKind.rateTrip:
        return l10n.rateThisTrip;
      case BookingNextStepKind.trackDispute:
        return l10n.nextStepTrackDispute;
      case BookingNextStepKind.browseShops:
        return l10n.browseOtherShops;
      case BookingNextStepKind.fileDispute:
        return l10n.fileDispute;
      case BookingNextStepKind.none:
        return '';
    }
  }
}

/// Owner next step. `approved` has no primary CTA — the ball is in
/// the customer's court (the caller shows the "Waiting for payment"
/// line with the payment deadline instead). `completed` resolves to
/// the post-trip Rate customer step (the return flow itself lands on
/// All Bookings and never routes here); `rejected` and `cancelled`
/// are terminal.
BookingNextStep resolveOwnerNextStep(BookingEntity booking) {
  switch (booking.status) {
    case 'requested':
      return const BookingNextStep(BookingNextStepKind.approve);
    case 'approved':
      // Walk-in bookings are 100% owner-managed — never stall on
      // online customer payment proof.
      if (booking.origin == 'walk_in') {
        return const BookingNextStep(BookingNextStepKind.recordPayment);
      }
      return const BookingNextStep(BookingNextStepKind.none);
    case 'payment_submitted':
      return const BookingNextStep(BookingNextStepKind.verifyProof);
    case 'paid':
      return const BookingNextStep(BookingNextStepKind.startHandover);
    case 'active':
      return const BookingNextStep(BookingNextStepKind.returnSettlement);
    case 'disputed':
      return const BookingNextStep(BookingNextStepKind.viewDispute);
    case 'completed':
      return const BookingNextStep(BookingNextStepKind.rateCustomer);
    default:
      return const BookingNextStep(BookingNextStepKind.none);
  }
}

/// Customer next step. `requested` (waiting for the shop to approve)
/// and `payment_submitted` (waiting for verification) have no primary
/// CTA — the caller shows the waiting info instead.
BookingNextStep resolveCustomerNextStep(BookingEntity booking) {
  switch (booking.status) {
    case 'approved':
    case 'payment_rejected':
      return const BookingNextStep(BookingNextStepKind.payAdvance);
    case 'paid':
      return const BookingNextStep(BookingNextStepKind.viewPass);
    case 'active':
      return const BookingNextStep(BookingNextStepKind.viewActiveTrip);
    case 'completed':
      return const BookingNextStep(BookingNextStepKind.rateTrip);
    case 'disputed':
      return const BookingNextStep(BookingNextStepKind.trackDispute);
    case 'rejected':
      return const BookingNextStep(BookingNextStepKind.browseShops);
    case 'cancelled':
      return const BookingNextStep(BookingNextStepKind.fileDispute);
    default:
      return const BookingNextStep(BookingNextStepKind.none);
  }
}
