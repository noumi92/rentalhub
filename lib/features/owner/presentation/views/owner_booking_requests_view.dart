import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/custom_curved_header.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../bookings/data/datasources/booking_remote_data_source.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../widgets/operations/request_triage_card.dart';

class OwnerBookingRequestsView extends StatefulWidget {
  final String shopId;

  const OwnerBookingRequestsView({
    super.key,
    this.shopId = 'shop-1',
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
  String _filter = 'requested';

  List<BookingEntity> get _filtered =>
      _requests.where((b) => b.status == _filter).toList();

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final ds = sl<BookingRemoteDataSource>();
      final bookings = await ds.getShopBookings(widget.shopId);
      setState(() {
        // Phase B (D1): the whole pipeline stays visible — new
        // requests, proofs waiting for verification, and approved
        // bookings waiting for the customer to pay.
        _requests = bookings
            .where((b) =>
                b.status == 'requested' ||
                b.status == 'payment_submitted' ||
                b.status == 'approved')
            .toList();
      });
    } catch (_) {
      if (mounted) setState(() => _hasError = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _approveRequest(BookingEntity booking) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _processingId = booking.bookingId);
    try {
      final ds = sl<BookingRemoteDataSource>();
      await ds.updateBookingStatus(bookingId: booking.bookingId, status: 'approved');
      if (mounted) {
        AppFeedback.showSuccess(context, l10n.requestsApproved(booking.bookingId));
        // Phase B (D1): the approved booking stays in the list under
        // the Approved filter instead of vanishing.
        setState(() => _requests = _requests
            .map((b) => b.bookingId == booking.bookingId
                ? b.copyWith(status: 'approved')
                : b)
            .toList());
      }
    } catch (e) {
      if (mounted) AppFeedback.showError(context, l10n.requestsApprovalFailed('$e'));
    } finally {
      if (mounted) setState(() => _processingId = null);
    }
  }

  Future<void> _rejectRequest(BookingEntity booking) async {
    // Phase B (D3): a rejection always carries a reason — the
    // customer sees it and knows what to fix.
    final l10n = AppLocalizations.of(context)!;
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.requestsRejectTitle),
        content: TextField(
          controller: reasonController,
          autofocus: true,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: l10n.requestsRejectReasonLabel,
            hintText: l10n.requestsRejectReasonHint,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(reasonController.text.trim()),
            child: Text(l10n.requestsRejectButton),
          ),
        ],
      ),
    );
    if (reason == null || reason.isEmpty || !mounted) return;
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
        setState(() => _requests.removeWhere((b) => b.bookingId == booking.bookingId));
      }
    } catch (e) {
      if (mounted) AppFeedback.showError(context, l10n.requestsDeclineFailed('$e'));
    } finally {
      if (mounted) setState(() => _processingId = null);
    }
  }

  Widget _filterChip(AppLocalizations l10n, String status, String label) {
    final selected = _filter == status;
    final count = _requests.where((b) => b.status == status).length;
    return ChoiceChip(
      materialTapTargetSize: MaterialTapTargetSize.padded,
      label: Text(l10n.requestsFilterChip(label, count)),
      selected: selected,
      onSelected: (_) => setState(() => _filter = status),
    );
  }

  String _emptyLabel(AppLocalizations l10n) => {'payment_submitted': l10n.requestsEmptyProof, 'approved': l10n.requestsEmptyApproved}[_filter] ?? l10n.requestsEmptyNew;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            CustomCurvedHeader(
              variant: CustomCurvedHeaderVariant.compact,
              titleWidget: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.requestsTitle, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: Colors.white)),
                  Text(l10n.requestsAwaitingReview(_filtered.length), style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.primaryContainer)),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white),
                  tooltip: l10n.requestsScanQrTooltip,
                  onPressed: () => context.push(RouteNames.ownerQrScan),
                ),
                IconButton(
                  tooltip: l10n.requestsRefreshTooltip,
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: _loadRequests,
                ),
              ],
            ),
            Expanded(
              // E2: shared loading / error / empty states.
              child: _isLoading
                  ? AppLoadingState(message: l10n.requestsLoading)
                  : _hasError
                      ? AppErrorState(message: l10n.requestsLoadError, onRetry: _loadRequests)
                      : Column(
                          children: [
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                              child: Row(
                                children: [
                                  _filterChip(l10n, 'requested', l10n.requestsFilterNew),
                                  const SizedBox(width: 8),
                                  _filterChip(l10n, 'payment_submitted', l10n.requestsFilterProof),
                                  const SizedBox(width: 8),
                                  _filterChip(l10n, 'approved', l10n.statusApproved),
                                ],
                              ),
                            ),
                            Expanded(
                              child: _filtered.isEmpty
                                  // E2: shared empty state.
                                  ? AppEmptyState(title: _emptyLabel(l10n), message: l10n.requestsEmptyMessage)
                                  : ListView.separated(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 14),
                                      itemCount: _filtered.length,
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(height: 12),
                                      itemBuilder: (context, index) {
                                        final b = _filtered[index];
                                        return InkWell(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          onTap: () => context.push(RouteNames
                                              .ownerRequestsDetail
                                              .replaceFirst(
                                                  ':id', b.bookingId)),
                                          child: RequestTriageCard(
                                            booking: b,
                                            isProcessing:
                                                _processingId == b.bookingId,
                                            onApprove: () => _approveRequest(b),
                                            onReject: () => _rejectRequest(b),
                                            onVerifyProof: () => context.push(
                                                RouteNames.ownerRequestsDetail
                                                    .replaceFirst(
                                                        ':id', b.bookingId)),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
