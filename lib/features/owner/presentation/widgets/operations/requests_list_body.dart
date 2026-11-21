import 'package:flutter/material.dart';

import '../../../../../core/widgets/app_state_views.dart';
import '../../../../bookings/domain/entities/booking_entity.dart';
import '../../views/owner_whatsapp_zero_balance_sheet.dart';
import 'request_triage_card.dart';
import 'requests_filter_bar.dart';

/// Audit impl (O14 + W6): the requests tab body, extracted from
/// [OwnerBookingRequestsView] so the view stays under the 250-line
/// cap — loading / error / empty states, the WhatsApp zero-balance
/// banner, the search + triage filter bar, and the request cards.
/// Pure display + callbacks; the owning view holds the lists and
/// performs the approve / reject writes.
class RequestsListBody extends StatelessWidget {
  final bool isLoading;
  final bool hasError;
  final String loadingMessage;
  final String errorMessage;
  final String emptyTitle;
  final String emptyMessage;
  final List<BookingEntity> requests;
  final List<BookingEntity> filtered;
  final String filter;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onFilterChanged;
  final int? waBalance;
  final int waSkipped;
  final String? processingId;
  final VoidCallback onRetry;
  final ValueChanged<BookingEntity> onApprove;
  final ValueChanged<BookingEntity> onReject;
  final ValueChanged<BookingEntity> onOpenDetail;

  const RequestsListBody({
    super.key,
    required this.isLoading,
    required this.hasError,
    required this.loadingMessage,
    required this.errorMessage,
    required this.emptyTitle,
    required this.emptyMessage,
    required this.requests,
    required this.filtered,
    required this.filter,
    required this.searchController,
    required this.onSearchChanged,
    required this.onFilterChanged,
    required this.waBalance,
    required this.waSkipped,
    required this.processingId,
    required this.onRetry,
    required this.onApprove,
    required this.onReject,
    required this.onOpenDetail,
  });

  @override
  Widget build(BuildContext context) {
    // E2: shared loading / error / empty states.
    if (isLoading) return AppLoadingState(message: loadingMessage);
    if (hasError) {
      return AppErrorState(message: errorMessage, onRetry: onRetry);
    }
    return Column(
      children: [
        // Audit impl (worker E, W6): amber banner above the triage
        // list, only when the real balance is 0 and messages were
        // skipped.
        if (waBalance != null &&
            WhatsappZeroBalanceBanner.shouldShow(
              balance: waBalance!,
              skippedCount: waSkipped,
            ))
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: WhatsappZeroBalanceBanner(skippedCount: waSkipped),
          ),
        RequestsFilterBar(
          searchController: searchController,
          onSearchChanged: onSearchChanged,
          filter: filter,
          // Item 4: counts for every chip, including the new All /
          // Paid / Disputed / Cancelled ones — 'all' is the whole
          // list, the rest are exact status counts.
          counts: {
            'all': requests.length,
            for (final s in [
              'requested',
              'payment_submitted',
              'approved',
              'paid',
              'active',
              'disputed',
              'completed',
              'rejected',
              'cancelled'
            ])
              s: requests.where((b) => b.status == s).length,
          },
          onFilterChanged: onFilterChanged,
        ),
        Expanded(
          child: filtered.isEmpty
              // E2: shared empty state.
              ? AppEmptyState(title: emptyTitle, message: emptyMessage)
              : ListView.separated(
                  // Pull-to-refresh (user layout, 2026-11-16): the
                  // list must stay draggable even with few items, or
                  // the RefreshIndicator above it never triggers.
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final b = filtered[index];
                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => onOpenDetail(b),
                      child: RequestTriageCard(
                        booking: b,
                        isProcessing: processingId == b.bookingId,
                        onApprove: () => onApprove(b),
                        onReject: () => onReject(b),
                        onVerifyProof: () => onOpenDetail(b),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
