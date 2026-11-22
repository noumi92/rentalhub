import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/money_format.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../bookings/data/models/booking_model.dart';
import '../../data/datasources/admin_platform_data_source.dart';
import '../widgets/admin_shell.dart';
import '../widgets/admin_status_chip.dart';

/// Phase D (D1) — the bookings list: every booking, filterable by
/// lifecycle status, searchable by booking id, customer, or vehicle.
class AdminBookingsView extends StatefulWidget {
  const AdminBookingsView({super.key});

  @override
  State<AdminBookingsView> createState() => _AdminBookingsViewState();
}

class _AdminBookingsViewState extends State<AdminBookingsView> {
  final _searchController = TextEditingController();
  List<BookingModel> _bookings = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _filter = 'all';

  static const _statuses = [
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
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!_isLoading) setState(() => _hasError = false);
    try {
      final bookings =
          await sl<AdminPlatformDataSource>().getBookings(status: _filter);
      if (mounted) {
        setState(() {
          _bookings = bookings;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _hasError = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<BookingModel> get _visible {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _bookings;
    return _bookings.where((b) {
      return b.bookingId.toLowerCase().contains(query) ||
          (b.customerName ?? '').toLowerCase().contains(query) ||
          (b.vehicleName ?? '').toLowerCase().contains(query) ||
          (b.shopName ?? '').toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final compact =
        windowSizeClassOf(context) == WindowSizeClass.compact;
    return AdminShell(
      activeRoute: RouteNames.adminBookings,
      title: l10n.admin2_navBookings,
      subtitle: l10n.admin2_bookingsSubtitle,
      onRefresh: _load,
      child: Padding(
        padding: EdgeInsets.all(compact ? 16 : 24),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: l10n.admin2_bookingsSearchHint,
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Theme.of(context).dividerColor),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (var i = 0; i < _statuses.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      ChoiceChip(
                        label: Text(humanizeStatus(_statuses[i], l10n)),
                        selected: _filter == _statuses[i],
                        onSelected: (_) {
                          setState(() {
                            _filter = _statuses[i];
                            _isLoading = true;
                          });
                          _load();
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const AppLoadingState()
                  : _hasError
                      ? AppErrorState(
                          message: l10n.admin2_bookingsLoadFailed,
                          onRetry: _load,
                        )
                      : _visible.isEmpty
                          ? AppEmptyState(
                              title: l10n.admin2_bookingsEmptyTitle,
                              message: l10n.admin2_bookingsEmptyHint,
                            )
                          : ListView.separated(
                          itemCount: _visible.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            final b = _visible[i];
                            // Compact: the status chip moves into the
                            // subtitle — as a trailing widget beside a
                            // long vehicle • booking title it overflows
                            // at 360px.
                            return Card(
                              margin: EdgeInsets.zero,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                    color: Theme.of(context).dividerColor),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.primary
                                      .withValues(alpha: 0.12),
                                  child: const Icon(Icons.receipt_long_rounded,
                                      ),
                                ),
                                title: Text(
                                    '${b.vehicleName ?? b.vehicleId} • ${b.bookingId}',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 14,
                                        )),
                                subtitle: compact
                                    ? Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '${b.customerName ?? l10n.admin2_bookingsCustomer} • ${b.shopName ?? ''} • ${l10n.amountRs(formatRs(b.totalAmount))} • ${humanizeStatus(b.tripType, l10n)}',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Theme.of(context).colorScheme.onSurfaceVariant),
                                          ),
                                          const SizedBox(height: 6),
                                          _statusChip(context, b.status),
                                        ],
                                      )
                                    : Text(
                                        '${b.customerName ?? l10n.admin2_bookingsCustomer} • ${b.shopName ?? ''} • ${l10n.amountRs(formatRs(b.totalAmount))} • ${humanizeStatus(b.tripType, l10n)}',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Theme.of(context).colorScheme.onSurfaceVariant),
                                      ),
                                isThreeLine: compact,
                                trailing: compact
                                    ? null
                                    : _statusChip(context, b.status),
                                onTap: () => context.go(
                                  RouteNames.adminBookingDetail
                                      .replaceFirst(':bookingId', b.bookingId),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(BuildContext context, String status) {
    final tone = switch (status) {
      'completed' => AdminStatusTone.success,
      'active' || 'paid' => AdminStatusTone.info,
      'disputed' => AdminStatusTone.warning,
      'rejected' || 'cancelled' => AdminStatusTone.danger,
      _ => AdminStatusTone.neutral,
    };
    // Was the raw enum ('payment_submitted'); now a human label.
    return AdminStatusChip(
        label: humanizeStatus(status, AppLocalizations.of(context)),
        tone: tone);
  }
}
