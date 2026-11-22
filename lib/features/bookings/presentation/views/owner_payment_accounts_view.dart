import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../../core/routing/auth_route_guard.dart';
import '../../../../core/utils/current_shop.dart';
import '../../../../core/utils/shop_id_resolution.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../domain/entities/booking_entity.dart';
import '../../utils/booking_next_step.dart';
import '../widgets/approved_accounts_body.dart';
import '../../../../features/owner/presentation/views/owner_booking_confirmed_view.dart';
import '../../../../features/owner/presentation/views/owner_booking_summary_view.dart';
import '../../../../features/owner/presentation/widgets/operations/requested_booking_detail.dart';
import '../../../../l10n/app_localizations.dart';

/// §10: a merely `requested` booking no longer renders the "Reservation
/// Request Approved!" banner with an Upload-proof CTA — proof before
/// approval is the wrong order, and detail had no approve/reject at
/// all. A requested booking now renders [RequestedBookingDetail]
/// (summary + Approve/Reject); the banner and payment accounts render
/// only once the booking is actually `approved` — NOT "or further
/// along": a `paid` / `active` booking already had its proof verified
/// (verification is implicit in the status), and terminal / `disputed`
/// bookings must never see an Upload Proof CTA. Those statuses are
/// routed to the Confirmed / read-only summary views instead (see
/// [build]); the router does the same branching, this is defence in
/// depth for a direct push.
class OwnerPaymentAccountsView extends StatefulWidget {
  final BookingEntity booking;
  final VoidCallback? onProceedToUploadProof;
  final VoidCallback? onBack;

  /// Injectable Firestore for tests; production uses the default
  /// instance (see [_OwnerPaymentAccountsViewState._resolveOwner]).
  final FirebaseFirestore? firestore;

  const OwnerPaymentAccountsView({
    super.key,
    required this.booking,
    this.onProceedToUploadProof,
    this.onBack,
    this.firestore,
  });

  @override
  State<OwnerPaymentAccountsView> createState() =>
      _OwnerPaymentAccountsViewState();
}

class _OwnerPaymentAccountsViewState extends State<OwnerPaymentAccountsView> {
  late BookingEntity _booking;

  /// The shop ids this signed-in owner may act for — the bare UID
  /// plus the shop doc id it owns. Starts as the bare UID so the
  /// first frame behaves as before; the async resolution below
  /// widens it once Firestore answers.
  Set<String> _ownerShopIds = {};

  @override
  void initState() {
    super.initState();
    _booking = widget.booking;
    _ownerShopIds = {currentShopId()};
    _resolveOwnerShopIds();
  }

  /// Shop-id linking (2026-11-15): customer bookings carry the shop
  /// DOCUMENT id (`shop_<uid>`) while [currentShopId] is the bare
  /// UID, so a direct `==` failed for the rightful owner. Resolve
  /// both forms once and test membership — a different shop's owner
  /// still matches nothing. Fails soft to the bare UID when
  /// Firestore is unavailable.
  Future<void> _resolveOwnerShopIds() async {
    FirebaseFirestore? fs;
    if (widget.firestore != null) {
      fs = widget.firestore;
    } else {
      try {
        fs = FirebaseFirestore.instance;
      } catch (_) {}
    }
    final ids = await candidateShopIds(fs, currentShopId());
    if (mounted) setState(() => _ownerShopIds = ids.toSet());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isRequested = _booking.status == 'requested';
    // Role gate (integration): this view is shared by the customer
    // payment-proof route and the owner request-detail route. A
    // customer deep-linking a merely `requested` booking must see
    // the summary WITHOUT owner Approve/Reject actions. The owner
    // is the signed-in user whose uid is the booking's shop id and
    // whose locked role is 'owner'; anything else (customer role,
    // another shop, signed out) gets the summary only. Default deny.
    final isShopOwner = AuthRouteGuard.lockedRole == 'owner' &&
        _ownerShopIds.contains(_booking.shopId);
    // Next-step batch (2026-11-21): defence in depth — the detail
    // route no longer sends past-payment or terminal / disputed
    // bookings here, but a direct push (or the shared customer
    // proof route) still must never show the Upload Proof CTA. A
    // `paid` / `active` booking opens the Confirmed view for its
    // owner — the Start Handover step lives there — and the
    // read-only summary for anyone else; terminal and `disputed`
    // bookings get the read-only summary. Only `requested` and
    // `approved` reach the Scaffold below.
    if (!isRequested) {
      switch (_booking.status) {
        case 'paid':
        case 'active':
          return isShopOwner
              ? OwnerBookingConfirmedView(
                  booking: _booking, onBack: widget.onBack)
              : OwnerBookingSummaryView(
                  booking: _booking, onBack: widget.onBack);
        case 'payment_submitted':
        case 'completed':
        case 'rejected':
        case 'cancelled':
        case 'disputed':
          return OwnerBookingSummaryView(
              booking: _booking, onBack: widget.onBack);
      }
    }
    return Scaffold(
      // C1: MinimalAppBar owns the top inset.
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            MinimalAppBar(
              title: isRequested
                  ? l10n.requestsTitle
                  : l10n.paymentAccountsTitle,
              subtitle: isRequested
                  ? l10n.paymentVerificationBooking(_booking.bookingId)
                  : null,
              onBack: widget.onBack,
            ),
            Expanded(
              child: isRequested
                  ? RequestedBookingDetail(
                      booking: _booking,
                      showActions: isShopOwner,
                      firestore: widget.firestore,
                      // Navigate-back rule (2026-11-21): after the
                      // approve save, go to All Bookings — same as
                      // the triage-path approve — instead of flipping
                      // to the accounts view.
                      onApproved: (_) => goToAllOwnerBookings(context),
                    )
                  : ApprovedAccountsBody(
                      booking: _booking,
                      firestore: widget.firestore,
                      onProceedToUploadProof:
                          widget.onProceedToUploadProof,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
