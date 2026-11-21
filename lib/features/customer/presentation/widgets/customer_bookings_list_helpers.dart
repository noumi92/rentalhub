import 'package:flutter/material.dart';

import '../../../bookings/domain/entities/booking_entity.dart';
import '../../../bookings/utils/booking_next_step.dart';
import '../../../../l10n/app_localizations.dart';

/// Customer bookings list helpers, extracted from
/// CustomerBookingsView so the view stays under the 250-line cap
/// (rulebook §2.2).
///
/// Next-step batch (2026-11-21): the tabs gain a Disputed chip —
/// All, Pending, Approved, Active, Disputed, Done — and the card
/// action comes from [resolveCustomerNextStep], the same resolver
/// the detail actions use, so card and detail can never disagree.

/// The six tab labels, in order. The index is the tab id the view
/// keeps in `_selectedTab` and the `initialTab` param sets.
const int customerBookingTabsCount = 6;

/// Tab index for a `?tab=` query value (`all`, `pending`,
/// `approved`, `active`, `disputed`, `done`). Unknown or missing
/// values fall back to All (tab 0) — the save navigations pass
/// `?tab=all` so a just-saved booking is visible at once.
int customerTabIndexFromName(String? name) {
  switch (name) {
    case 'pending':
      return 1;
    case 'approved':
      return 2;
    case 'active':
      return 3;
    case 'disputed':
      return 4;
    case 'done':
      return 5;
    case 'all':
    default:
      return 0;
  }
}

List<String> customerBookingTabs(AppLocalizations l10n) => [
      l10n.filterAll,
      l10n.pending,
      l10n.statusApproved,
      l10n.active,
      l10n.statusDisputed,
      l10n.done,
    ];

/// The bookings shown under [tab]: Pending groups `requested` +
/// `payment_submitted`, Active groups `paid` + `active`, Done
/// groups `completed` + `cancelled` + `rejected`, Disputed is an
/// exact match, and anything else (tab 0) is All.
List<BookingEntity> filterCustomerBookings(List<BookingEntity> all, int tab) {
  switch (tab) {
    case 1:
      return all
          .where((b) =>
              b.status == 'requested' || b.status == 'payment_submitted')
          .toList();
    case 2:
      return all.where((b) => b.status == 'approved').toList();
    case 3:
      return all
          .where((b) => b.status == 'paid' || b.status == 'active')
          .toList();
    case 4:
      return all.where((b) => b.status == 'disputed').toList();
    case 5:
      return all
          .where((b) =>
              b.status == 'completed' ||
              b.status == 'cancelled' ||
              b.status == 'rejected')
          .toList();
    default:
      return all;
  }
}

/// The list card's inline action for [booking], from the shared
/// next-step resolver: approved pays the advance, paid opens the
/// pass directly (not the detail screen), active opens the trip,
/// completed rates it, disputed tracks it. Every other status has
/// no card action — the detail screen carries it, or nothing does.
///
/// The label reuses the short list labels where they exist
/// (`bookingsPayAdvance`, `bookingsViewPass`, `bookingsRateTrip`)
/// and the next-step labels for the two new actions.
({String? label, VoidCallback? callback}) customerCardAction(
  AppLocalizations l10n,
  BookingEntity booking, {
  void Function(BookingEntity booking)? onPayAdvance,
  void Function(BookingEntity booking)? onViewPass,
  void Function(BookingEntity booking)? onViewActiveTrip,
  void Function(BookingEntity booking)? onRateTrip,
  void Function(BookingEntity booking)? onTrackDispute,
}) {
  switch (resolveCustomerNextStep(booking).kind) {
    case BookingNextStepKind.payAdvance:
      return (
        label: l10n.bookingsPayAdvance,
        callback: () => onPayAdvance?.call(booking),
      );
    case BookingNextStepKind.viewPass:
      return (
        label: l10n.bookingsViewPass,
        callback: () => onViewPass?.call(booking),
      );
    case BookingNextStepKind.viewActiveTrip:
      return (
        label: l10n.nextStepViewActiveTrip,
        callback: () => onViewActiveTrip?.call(booking),
      );
    case BookingNextStepKind.rateTrip:
      return (
        label: l10n.bookingsRateTrip,
        callback: () => onRateTrip?.call(booking),
      );
    case BookingNextStepKind.trackDispute:
      return (
        label: l10n.nextStepTrackDispute,
        callback: () => onTrackDispute?.call(booking),
      );
    default:
      return (label: null, callback: null);
  }
}
