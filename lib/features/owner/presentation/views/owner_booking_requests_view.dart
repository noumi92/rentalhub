import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../../../bookings/utils/booking_next_step.dart';
import '../../../bookings/utils/booking_request_time.dart';
import '../../../bookings/utils/live_booking_stream.dart';
import '../services/whatsapp_credits_data_source.dart';
import '../widgets/operations/approve_booking_sheet.dart';
import '../widgets/operations/owner_booking_cancel.dart';
import '../widgets/operations/owner_requests_view_body.dart';
import '../widgets/operations/walk_in_booking_fab.dart';

class OwnerBookingRequestsView extends StatefulWidget {
  final String shopId;

  /// Injectable Firestore for the approve sheet (tests only).
  final FirebaseFirestore? firestore;

  /// Initial status filter, from the `?filter=` query param on the
  /// route. Defaults to the Proof bucket (FG-4). Save flows navigate
  /// here with `?filter=all` so the just-saved booking — whose new
  /// status is usually NOT in the Proof bucket — is visible at once.
  final String initialFilter;

  const OwnerBookingRequestsView({
    super.key,
    required this.shopId,
    this.firestore,
    this.initialFilter = 'payment_submitted',
  });

  @override
  State<OwnerBookingRequestsView> createState() => _OwnerBookingRequestsViewState();
}

class _OwnerBookingRequestsViewState extends State<OwnerBookingRequestsView> {
  List<BookingEntity> _requests = [];
  bool _isLoading = true;
  // E2: a load failure used to fall through silently to an empty list; it now renders an error state with retry.
  bool _hasError = false;
  String? _processingId;
  // FG-4 (UI/UX audit 2026-11-15): proofs first — the most urgent
  // bucket (payment proofs awaiting verification) is the default,
  // not new requests.
  String _filter = 'payment_submitted';

  /// The status values the filter bar understands, plus 'all'.
  /// Anything else (e.g. a bad `?filter=` value) falls back to the
  /// Proof default instead of showing an empty list.
  static const _knownFilters = {
    'all',
    'requested',
    'approved',
    'payment_submitted',
    'paid',
    'active',
    'disputed',
    'completed',
    'rejected',
    'cancelled',
  };
  // FG-4: the requests' request times, for oldest-first order and the oldest-wait line (see booking_request_time.dart).
  Map<String, DateTime?> _requestTimes = {};
  final _searchController = TextEditingController();
  String _searchQuery = '';
  // Audit impl (worker E, W6): the WhatsApp zero-balance banner only shows once the real balance is known (null = not loaded yet).
  int? _waBalance;
  int _waSkipped = 0;
  // Live updates (Item 2): the subscription behind the triage list.
  StreamSubscription<List<BookingEntity>>? _bookingsSub;

  // FG-4: fetch the request times for newly arrived bookings (the
  // session cache keeps this to one doc read per booking).
  Future<void> _refreshRequestTimes(List<BookingEntity> list) async {
    final times = await BookingRequestTimes.fetch(list.map((b) => b.bookingId));
    if (mounted) setState(() => _requestTimes = {..._requestTimes, ...times});
  }

  @override
  void dispose() {
    _bookingsSub?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (_knownFilters.contains(widget.initialFilter)) {
      _filter = widget.initialFilter;
    }
    _loadRequests();
    _loadWaBanner();
  }

  @override
  void didUpdateWidget(covariant OwnerBookingRequestsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync unconditionally: go_router page keys are path-only — change
    // detection would miss consecutive saves landing on `?filter=all`.
    if (_knownFilters.contains(widget.initialFilter)) {
      setState(() => _filter = widget.initialFilter);
    }
  }

  /// Audit impl (worker E, W6): reads the real WhatsApp credit
  /// balance and the real skipped-message count; the banner stays
  /// hidden when either read fails.
  Future<void> _loadWaBanner() async {
    try {
      final ds = WhatsappCreditsDataSource();
      final balance = await ds.getBalance(widget.shopId);
      final skipped = await ds.getSkippedCount(widget.shopId);
      if (mounted) setState(() { _waBalance = balance; _waSkipped = skipped; });
    } catch (_) {
      // Banner stays hidden when credits cannot be read.
    }
  }

  /// Live updates (Item 2): the triage list follows the shop's bookings stream — a customer submit lands here while the owner is looking at the list, and an approve / reject re-renders it without a manual refresh. Pull-to-refresh and the error-state retry re-run this method, which re-subscribes.
  Future<void> _loadRequests() async {
    await _bookingsSub?.cancel();
    _bookingsSub = null;
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    _bookingsSub = subscribeLiveBookings((ds) => ds.streamShopBookings(widget.shopId), (bookings) {
      if (!mounted) return;
      setState(() {
        // Item 3 (2026-11-21): NO status whitelist here. The old
        // one dropped 'paid' / 'disputed' / 'cancelled', so those
        // bookings vanished — a full-advance walk-in is born 'paid'
        // and never appeared at all. The stream is already
        // shop-scoped; the filter bar is what narrows the view.
        _requests = bookings.toList();
        _isLoading = false;
      });
      _refreshRequestTimes(bookings);
    }, onError: () {
      if (mounted) setState(() { _hasError = true; _isLoading = false; });
    });
    if (_bookingsSub == null && mounted) setState(() { _hasError = true; _isLoading = false; });
  }

  /// O18: approving opens the approve sheet instead of a one-tap flip.
  Future<void> _approveRequest(BookingEntity booking) async {
    final l10n = AppLocalizations.of(context)!;
    await showApproveBookingSheet(
      context,
      booking: booking,
      firestore: widget.firestore,
      onApproved: (updated) {
        if (!mounted) return;
        AppFeedback.showSuccess(context, l10n.requestsApproved(updated.bookingId));
        // Phase B (D1): the approved booking stays under Approved.
        setState(() => _requests = _requests
            .map((b) => b.bookingId == updated.bookingId ? updated : b)
            .toList());
        // Item 2 navigate-back: every booking-flow save lands on
        // All Bookings, so the just-approved booking is visible at
        // once (it is no longer in the Proof bucket).
        goToAllOwnerBookings(context);
      },
    );
  }

  /// Runs an owner status action (reject / cancel) with the
  /// processing flag, swapping the updated row in on success.
  /// The dialog opens behind the flag (it is modal, so the card
  /// buttons are unreachable while it is up). Item 2 navigate-back:
  /// a successful reject / cancel lands on All Bookings, so the
  /// just-saved booking is visible at once.
  Future<void> _applyOwnerAction(
    BookingEntity booking,
    Future<BookingEntity?> Function() run,
  ) async {
    setState(() => _processingId = booking.bookingId);
    final updated = await run();
    if (!mounted) return;
    setState(() {
      _processingId = null;
      if (updated != null) {
        _requests = _requests
            .map((b) => b.bookingId == updated.bookingId ? updated : b)
            .toList();
      }
    });
    if (updated != null) goToAllOwnerBookings(context);
  }

  Future<void> _rejectRequest(BookingEntity booking) =>
      _applyOwnerAction(booking, () => rejectBookingRequest(context, booking));

  /// Worker B: owner cancel for walk-in `approved` / `paid`
  /// bookings — the dialog, status flip and Security release live
  /// in [cancelWalkInBooking]; online bookings never reach here
  /// (the triage card hides the button, and the flow guards too).
  Future<void> _cancelRequest(BookingEntity booking) =>
      _applyOwnerAction(booking, () => cancelWalkInBooking(context, booking));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // FG-4: the oldest proof wait, surfaced in the list header.
    final oldestProofWait = oldestWaitFor(_requests.where((b) => b.status == 'payment_submitted'), _requestTimes);
    return Scaffold(
      // Walk-in booking is an extended FAB ([WalkInBookingFab]).
      floatingActionButton: const WalkInBookingFab(),
      // The header, refresh and list live in OwnerRequestsViewBody
      // (incl. the SafeArea, top: false) so this view stays under
      // the 250-line cap.
      body: OwnerRequestsViewBody(
        title: l10n.bookingsManagementTitle,
        oldestProofWait: oldestProofWait,
        onScanQr: () => context.push(RouteNames.ownerQrScan),
        onCalendar: () => context.push(RouteNames.ownerFleetCalendar),
        isLoading: _isLoading,
        hasError: _hasError,
        loadingMessage: l10n.requestsLoading,
        errorMessage: l10n.requestsLoadError,
        emptyMessage: l10n.requestsEmptyMessage,
        requests: _requests,
        requestTimes: _requestTimes,
        filter: _filter,
        searchQuery: _searchQuery,
        searchController: _searchController,
        onSearchChanged: (q) => setState(() => _searchQuery = q),
        onFilterChanged: (s) => setState(() => _filter = s),
        waBalance: _waBalance,
        waSkipped: _waSkipped,
        processingId: _processingId,
        onRefresh: _loadRequests,
        onRetry: _loadRequests,
        onApprove: _approveRequest,
        onReject: _rejectRequest,
        onCancel: _cancelRequest,
        onOpenDetail: (b) => context.push(RouteNames
            .ownerRequestsDetail
            .replaceFirst(':id', b.bookingId)),
      ),
    );
  }
}
