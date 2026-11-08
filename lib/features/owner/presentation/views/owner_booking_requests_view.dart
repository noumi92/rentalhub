import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/custom_curved_header.dart';
import '../../../bookings/data/datasources/booking_remote_data_source.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import '../widgets/operations/request_triage_card.dart';

class OwnerBookingRequestsView extends StatefulWidget {
  final String shopId;
  final VoidCallback? onBack;

  const OwnerBookingRequestsView({
    super.key,
    this.shopId = 'shop-1',
    this.onBack,
  });

  @override
  State<OwnerBookingRequestsView> createState() => _OwnerBookingRequestsViewState();
}

class _OwnerBookingRequestsViewState extends State<OwnerBookingRequestsView> {
  List<BookingEntity> _requests = [];
  bool _isLoading = true;
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
    setState(() => _isLoading = true);
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
      // Fallback
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _approveRequest(BookingEntity booking) async {
    setState(() => _processingId = booking.bookingId);
    try {
      final ds = sl<BookingRemoteDataSource>();
      await ds.updateBookingStatus(bookingId: booking.bookingId, status: 'approved');
      if (mounted) {
        AppFeedback.showSuccess(context, 'Booking #${booking.bookingId} approved! Payment instructions sent to customer.');
        // Phase B (D1): the approved booking stays in the list under
        // the Approved filter instead of vanishing.
        setState(() => _requests = _requests
            .map((b) => b.bookingId == booking.bookingId
                ? b.copyWith(status: 'approved')
                : b)
            .toList());
      }
    } catch (e) {
      if (mounted) AppFeedback.showError(context, 'Approval failed: $e');
    } finally {
      if (mounted) setState(() => _processingId = null);
    }
  }

  Future<void> _rejectRequest(BookingEntity booking) async {
    // Phase B (D3): a rejection always carries a reason — the
    // customer sees it and knows what to fix.
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reject this request?'),
        content: TextField(
          controller: reasonController,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Reason (required)',
            hintText: 'e.g. Vehicle is not available on those dates',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(reasonController.text.trim()),
            child: const Text('Reject Request'),
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
        AppFeedback.showInfo(context, 'Booking #${booking.bookingId} rejected.');
        setState(() => _requests.removeWhere((b) => b.bookingId == booking.bookingId));
      }
    } catch (e) {
      if (mounted) AppFeedback.showError(context, 'Decline failed: $e');
    } finally {
      if (mounted) setState(() => _processingId = null);
    }
  }

  Widget _filterChip(String status, String label) {
    final selected = _filter == status;
    final count = _requests.where((b) => b.status == status).length;
    return ChoiceChip(
      label: Text('$label ($count)'),
      selected: selected,
      onSelected: (_) => setState(() => _filter = status),
    );
  }

  String get _emptyLabel => const {
        'payment_submitted': 'No payment proofs waiting for verification',
        'approved': 'No approved bookings waiting for payment',
      }[_filter] ?? 'No pending booking requests';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            CustomCurvedHeader(
              height: 100,
              leadingWidget: widget.onBack != null
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                      onPressed: widget.onBack,
                    )
                  : null,
              titleWidget: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Booking Requests Triage', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: Colors.white)),
                  Text('${_filtered.length} Requests Awaiting Review', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.primaryContainer)),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white),
                  tooltip: 'Scan booking QR',
                  onPressed: () => context.push(RouteNames.ownerQrScan),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: _loadRequests,
                ),
              ],
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                          child: Row(
                            children: [
                              _filterChip('requested', 'New'),
                              const SizedBox(width: 8),
                              _filterChip('payment_submitted', 'Proof'),
                              const SizedBox(width: 8),
                              _filterChip('approved', 'Approved'),
                            ],
                          ),
                        ),
                        Expanded(
                          child: _filtered.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.inbox_rounded, size: 52, color: AppColors.textMuted),
                                      const SizedBox(height: 12),
                                      Text(_emptyLabel, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textMuted)),
                                    ],
                                  ),
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  itemCount: _filtered.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    final b = _filtered[index];
                                    return InkWell(
                                      borderRadius: BorderRadius.circular(12),
                                      onTap: () => context.push(
                                        RouteNames.ownerRequestsDetail
                                            .replaceFirst(':id', b.bookingId),
                                      ),
                                      child: RequestTriageCard(
                                        booking: b,
                                        isProcessing: _processingId == b.bookingId,
                                        onApprove: () => _approveRequest(b),
                                        onReject: () => _rejectRequest(b),
                                        onVerifyProof: () => context.push(
                                          RouteNames.ownerRequestsDetail
                                              .replaceFirst(':id', b.bookingId),
                                        ),
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
