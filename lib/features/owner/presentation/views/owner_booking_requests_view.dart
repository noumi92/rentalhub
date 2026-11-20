import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../bookings/data/datasources/booking_remote_data_source.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../../../bookings/utils/booking_request_time.dart';
import '../../../bookings/utils/live_booking_stream.dart';
import '../services/whatsapp_credits_data_source.dart';
import '../widgets/operations/approve_booking_sheet.dart';
import '../widgets/operations/request_reject_dialog.dart';
import '../widgets/operations/requests_list_body.dart';
import '../widgets/operations/walk_in_booking_fab.dart';

class OwnerBookingRequestsView extends StatefulWidget {
  final String shopId;

  /// Injectable Firestore for the approve sheet (tests only).
  final FirebaseFirestore? firestore;

  const OwnerBookingRequestsView({
    super.key,
    required this.shopId,
    this.firestore,
  });

  @override
  State<OwnerBookingRequestsView> createState() => _OwnerBookingRequestsViewState();
}

class _OwnerBookingRequestsViewState extends State<OwnerBookingRequestsView> {
  List<BookingEntity> _requests = [];
  bool _isLoading = true;
  // E2: a load failure used to fall through silently to an empty
  // list; it now renders an error state with retry.
  bool _hasError = false;
  String? _processingId;
  // FG-4 (UI/UX audit 2026-11-15): proofs first — the most urgent
  // bucket (payment proofs awaiting verification) is the default,
  // not new requests.
  String _filter = 'payment_submitted';
  // FG-4: the requests' request times, for oldest-first order and
  // the oldest-wait line (see booking_request_time.dart).
  Map<String, DateTime?> _requestTimes = {};
  final _searchController = TextEditingController();
  String _searchQuery = '';
  // Audit impl (worker E, W6): the WhatsApp zero-balance banner only
  // shows once the real balance is known (null = not loaded yet).
  int? _waBalance;
  int _waSkipped = 0;
  // Live updates (Item 2): the subscription behind the triage list.
  StreamSubscription<List<BookingEntity>>? _bookingsSub;

  List<BookingEntity> get _filtered {
    final query = _searchQuery.trim().toLowerCase();
    final list = _requests.where((b) {
      if (b.status != _filter) return false;
      if (query.isEmpty) return true;
      return (b.customerName ?? '').toLowerCase().contains(query) ||
          (b.customerPhone ?? '').toLowerCase().contains(query) ||
          (b.vehicleName ?? '').toLowerCase().contains(query) ||
          b.bookingId.toLowerCase().contains(query);
    }).toList();
    // FG-4: oldest first within the filter (an unknown request time
    // sorts last, never first).
    return sortByRequestAgeOldestFirst(list, _requestTimes);
  }

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
    _loadRequests();
    _loadWaBanner();
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
        // Phase B (D1): the whole pipeline stays visible — new requests, proofs waiting for verification, and approved bookings waiting for the customer to pay. Audit §5 item 2: rejected bookings stay visible too, under the Rejected tab. O16: active rentals and completed bookings stay visible too, under the Active and Completed tabs.
        _requests = bookings.where((b) => b.status == 'requested' || b.status == 'payment_submitted' || b.status == 'approved' || b.status == 'rejected' || b.status == 'active' || b.status == 'completed').toList();
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
      },
    );
  }

  Future<void> _rejectRequest(BookingEntity booking) async {
    // Phase B (D3): a rejection always carries a reason — the
    // customer sees it and knows what to fix.
    final l10n = AppLocalizations.of(context)!;
    final reason = await showRequestRejectDialog(context);
    if (reason == null || !mounted) return;
    setState(() => _processingId = booking.bookingId);
    try {
      final ds = sl<BookingRemoteDataSource>();
      await ds.updateBookingStatus(
        bookingId: booking.bookingId,
        status: 'rejected',
        rejectionReason: reason,
      );
      if (mounted) {
        AppFeedback.showInfo(context, l10n.requestsRejected(booking.bookingId));
        // Audit §5 item 2: a rejected booking stays in the list
        // under the Rejected tab instead of vanishing.
        setState(() => _requests = _requests
            .map((b) => b.bookingId == booking.bookingId
                ? b.copyWith(status: 'rejected')
                : b)
            .toList());
      }
    } catch (e) {
      if (mounted) AppFeedback.showError(context, l10n.requestsDeclineFailed('$e'));
    } finally {
      if (mounted) setState(() => _processingId = null);
    }
  }

  String _emptyLabel(AppLocalizations l10n) => {'payment_submitted': l10n.requestsEmptyProof, 'approved': l10n.requestsEmptyApproved, 'rejected': l10n.bookingEmptyRejected, 'active': l10n.requestsEmptyActive, 'completed': l10n.requestsEmptyCompleted}[_filter] ?? l10n.requestsEmptyNew;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // FG-4: the oldest proof wait, surfaced in the list header.
    final oldestProofWait = oldestWaitFor(_requests.where((b) => b.status == 'payment_submitted'), _requestTimes);
    return Scaffold(
      // Walk-in booking is an extended FAB ([WalkInBookingFab]).
      floatingActionButton: const WalkInBookingFab(),
      // C1: MinimalAppBar owns the top inset; SafeArea must not add it
      // again or the navy header gains a dead band.
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            MinimalAppBar(
              title: l10n.bookingsManagementTitle,
              subtitle: oldestProofWait == null
                  ? l10n.requestsAwaitingReview(_filtered.length)
                  : '${l10n.requestsAwaitingReview(_filtered.length)} · ${l10n.requestsOldestProofWait(waitDurationLabel(l10n, oldestProofWait))}',
              actions: [
                IconButton(
                  icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white),
                  tooltip: l10n.requestsScanQrTooltip,
                  onPressed: () => context.push(RouteNames.ownerQrScan),
                ),
                IconButton(
                  tooltip: l10n.requestsCalendarTooltip,
                  icon: const Icon(Icons.calendar_month_rounded, color: Colors.white),
                  onPressed: () => context.push(RouteNames.ownerFleetCalendar),
                ),
              ],
            ),
            Expanded(
              // The list body lives in RequestsListBody so this view
              // stays under the 250-line cap; pull-to-refresh re-runs [_loadRequests].
              child: RefreshIndicator(
                onRefresh: _loadRequests,
                child: RequestsListBody(
                  isLoading: _isLoading,
                  hasError: _hasError,
                  loadingMessage: l10n.requestsLoading,
                  errorMessage: l10n.requestsLoadError,
                  emptyTitle: _emptyLabel(l10n),
                  emptyMessage: l10n.requestsEmptyMessage,
                  requests: _requests,
                  filtered: _filtered,
                  filter: _filter,
                  searchController: _searchController,
                  onSearchChanged: (q) => setState(() => _searchQuery = q),
                  onFilterChanged: (s) => setState(() => _filter = s),
                  waBalance: _waBalance,
                  waSkipped: _waSkipped,
                  processingId: _processingId,
                  onRetry: _loadRequests,
                  onApprove: _approveRequest,
                  onReject: _rejectRequest,
                  onOpenDetail: (b) => context.push(RouteNames
                      .ownerRequestsDetail
                      .replaceFirst(':id', b.bookingId)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
