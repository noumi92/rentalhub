import 'package:flutter/material.dart';

import '../../../../../core/widgets/app_state_views.dart';
import '../../../../bookings/domain/entities/booking_entity.dart';
import '../../views/owner_whatsapp_zero_balance_sheet.dart';
import 'owner_booking_list_tile.dart';
import 'requests_filter_bar.dart';

/// Simplified bookings list body: 2 tabs (Walk-in / Online), minimal
/// status filter chips, and compact scannable rows — tapping any row
/// opens the Booking Details page where all full details & buttons live.
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
  final String originTab;
  final int walkInCount;
  final int onlineCount;
  final ValueChanged<String>? onOriginTabChanged;
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
  final ValueChanged<BookingEntity>? onCancel;
  final ValueChanged<BookingEntity>? onRecordPayment;

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
    this.originTab = 'walk_in',
    this.walkInCount = 0,
    this.onlineCount = 0,
    this.onOriginTabChanged,
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
    this.onCancel,
    this.onRecordPayment,
  });

  static bool matchesStatusBucket(BookingEntity b, String filter) {
    return switch (filter) {
      'all' => true,
      'pending' => const {'requested', 'payment_submitted', 'approved'}
          .contains(b.status),
      'cancelled' => const {'cancelled', 'rejected'}.contains(b.status),
      _ => b.status == filter,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return AppLoadingState(message: loadingMessage);
    if (hasError) {
      return AppErrorState(message: errorMessage, onRetry: onRetry);
    }
    final scoped = requests
        .where((b) =>
            originTab == 'walk_in'
                ? b.origin == 'walk_in'
                : b.origin != 'walk_in')
        .toList();

    return Column(
      children: [
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
          originTab: originTab,
          walkInCount: walkInCount,
          onlineCount: onlineCount,
          onOriginTabChanged: onOriginTabChanged,
          counts: {
            'all': scoped.length,
            'pending':
                scoped.where((b) => matchesStatusBucket(b, 'pending')).length,
            'paid': scoped.where((b) => b.status == 'paid').length,
            'active': scoped.where((b) => b.status == 'active').length,
            'completed': scoped.where((b) => b.status == 'completed').length,
            'cancelled': scoped
                .where((b) => matchesStatusBucket(b, 'cancelled'))
                .length,
          },
          onFilterChanged: onFilterChanged,
        ),
        Expanded(
          child: filtered.isEmpty
              ? LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: AppEmptyState(
                        title: emptyTitle,
                        message: emptyMessage,
                      ),
                    ),
                  ),
                )
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final b = filtered[index];
                    return OwnerBookingListTile(
                      key: ValueKey(b.bookingId),
                      booking: b,
                      onTap: () => onOpenDetail(b),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
