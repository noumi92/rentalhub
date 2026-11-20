import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../../core/routing/auth_route_guard.dart';
import '../../../../core/utils/current_shop.dart';
import '../../../../core/utils/shop_id_resolution.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../domain/entities/booking_entity.dart';
import '../widgets/approved_accounts_body.dart';
import '../../../../features/owner/presentation/widgets/operations/requested_booking_detail.dart';
import '../../../../l10n/app_localizations.dart';

/// §10: a merely `requested` booking no longer renders the "Reservation
/// Request Approved!" banner with an Upload-proof CTA — proof before
/// approval is the wrong order, and detail had no approve/reject at
/// all. A requested booking now renders [RequestedBookingDetail]
/// (summary + Approve/Reject); the banner and payment accounts render
/// only once the booking is actually `approved` (or further along).
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
                      onApproved: (updated) =>
                          setState(() => _booking = updated),
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
