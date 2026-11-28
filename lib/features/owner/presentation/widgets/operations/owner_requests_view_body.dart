import 'package:flutter/material.dart';

import '../../../../../core/widgets/minimal_app_bar.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../bookings/domain/entities/booking_entity.dart';
import '../../../../bookings/utils/booking_request_time.dart';
import 'requests_list_body.dart';

/// The bookings tab's full body — header, pull-to-refresh, 2 origin tabs
/// (Walk-in / Online), minimized status filters, and compact list rows.
class OwnerRequestsViewBody extends StatelessWidget {
  final String title;
  final Duration? oldestProofWait;
  final VoidCallback onScanQr;
  final VoidCallback onCalendar;
  final bool isLoading;
  final bool hasError;
  final String loadingMessage;
  final String errorMessage;
  final String emptyMessage;
  final List<BookingEntity> requests;
  final Map<String, DateTime?> requestTimes;
  final String filter;
  final String originTab;
  final ValueChanged<String>? onOriginTabChanged;
  final String searchQuery;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onFilterChanged;
  final int? waBalance;
  final int waSkipped;
  final String? processingId;
  final Future<void> Function() onRefresh;
  final VoidCallback onRetry;
  final ValueChanged<BookingEntity> onApprove;
  final ValueChanged<BookingEntity> onReject;
  final ValueChanged<BookingEntity> onOpenDetail;
  final ValueChanged<BookingEntity>? onCancel;
  final ValueChanged<BookingEntity>? onRecordPayment;

  const OwnerRequestsViewBody({
    super.key,
    required this.title,
    required this.oldestProofWait,
    required this.onScanQr,
    required this.onCalendar,
    required this.isLoading,
    required this.hasError,
    required this.loadingMessage,
    required this.errorMessage,
    required this.emptyMessage,
    required this.requests,
    required this.requestTimes,
    required this.filter,
    this.originTab = 'walk_in',
    this.onOriginTabChanged,
    required this.searchQuery,
    required this.searchController,
    required this.onSearchChanged,
    required this.onFilterChanged,
    required this.waBalance,
    required this.waSkipped,
    required this.processingId,
    required this.onRefresh,
    required this.onRetry,
    required this.onApprove,
    required this.onReject,
    required this.onOpenDetail,
    this.onCancel,
    this.onRecordPayment,
  });

  List<BookingEntity> get _filtered {
    final query = searchQuery.trim().toLowerCase();
    final list = requests.where((b) {
      final isWalkIn = b.origin == 'walk_in';
      if (originTab == 'walk_in' && !isWalkIn) return false;
      if (originTab == 'online' && isWalkIn) return false;
      if (!RequestsListBody.matchesStatusBucket(b, filter)) return false;
      if (query.isEmpty) return true;
      return (b.customerName ?? '').toLowerCase().contains(query) ||
          (b.customerPhone ?? '').toLowerCase().contains(query) ||
          (b.vehicleName ?? '').toLowerCase().contains(query) ||
          b.bookingId.toLowerCase().contains(query);
    }).toList();
    return sortByRequestAgeOldestFirst(list, requestTimes);
  }

  String _emptyLabel(AppLocalizations l10n) => {
        'pending': l10n.requestsEmptyNew,
        'paid': l10n.requestsEmptyPaid,
        'active': l10n.requestsEmptyActive,
        'completed': l10n.requestsEmptyCompleted,
        'cancelled': l10n.requestsEmptyCancelled,
        'all': l10n.requestsEmptyAll,
      }[filter] ??
      l10n.requestsEmptyAll;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final walkInCount = requests.where((b) => b.origin == 'walk_in').length;
    final onlineCount = requests.length - walkInCount;
    final filtered = _filtered;

    return SafeArea(
      top: false,
      child: Column(
        children: [
          MinimalAppBar(
            title: title,
            subtitle: l10n.requestsAwaitingReview(filtered.length),
            actions: [
              IconButton(
                icon: const Icon(Icons.qr_code_scanner_rounded,
                    color: Colors.white),
                tooltip: l10n.requestsScanQrTooltip,
                onPressed: onScanQr,
              ),
              IconButton(
                tooltip: l10n.requestsCalendarTooltip,
                icon: const Icon(Icons.calendar_month_rounded,
                    color: Colors.white),
                onPressed: onCalendar,
              ),
            ],
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: onRefresh,
              child: RequestsListBody(
                isLoading: isLoading,
                hasError: hasError,
                loadingMessage: loadingMessage,
                errorMessage: errorMessage,
                emptyTitle: _emptyLabel(l10n),
                emptyMessage: emptyMessage,
                requests: requests,
                filtered: filtered,
                filter: filter,
                originTab: originTab,
                walkInCount: walkInCount,
                onlineCount: onlineCount,
                onOriginTabChanged: onOriginTabChanged,
                searchController: searchController,
                onSearchChanged: onSearchChanged,
                onFilterChanged: onFilterChanged,
                waBalance: waBalance,
                waSkipped: waSkipped,
                processingId: processingId,
                onRetry: onRetry,
                onApprove: onApprove,
                onReject: onReject,
                onCancel: onCancel,
                onRecordPayment: onRecordPayment,
                onOpenDetail: onOpenDetail,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
