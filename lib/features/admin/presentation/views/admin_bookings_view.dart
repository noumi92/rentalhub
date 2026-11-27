import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../bookings/data/models/booking_model.dart';
import '../../data/datasources/admin_platform_data_source.dart';
import '../widgets/admin_booking_list_header.dart';
import '../widgets/admin_booking_list_tile.dart';
import '../widgets/admin_count_line.dart';
import '../widgets/admin_load_more_button.dart';
import '../widgets/admin_sort_menu.dart';
import '../widgets/admin_shell.dart';

/// Phase D (D1) — the bookings list: every booking, filterable by
/// lifecycle status, searchable by booking id, customer, or vehicle.
///
/// Phase 3 (3.4): the list pages (20 rows at a time) through
/// [AdminPlatformDataSource.getBookingsPage] instead of stopping at
/// a silent 200-row cap, search covers the whole list through the
/// data source (400 ms debounce, like Customers/Tickets), and the
/// count line says how many of the total are shown.
class AdminBookingsView extends StatefulWidget {
  const AdminBookingsView({super.key});

  @override
  State<AdminBookingsView> createState() => _AdminBookingsViewState();
}

class _AdminBookingsViewState extends State<AdminBookingsView> {
  static const _pageSize = 20;

  final _searchController = TextEditingController();
  Timer? _searchTimer;
  List<BookingModel> _bookings = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasError = false;
  bool _isSearching = false;
  String _filter = 'all';
  String _sort = AdminListSort.dateNewest;
  String _searchQuery = '';
  Object? _cursor;
  bool _hasMore = false;
  int? _total;

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
    _searchTimer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool reset = true}) async {
    if (reset) {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _bookings = [];
        _cursor = null;
        _hasMore = false;
        _total = null;
      });
    } else {
      setState(() => _isLoadingMore = true);
    }
    try {
      final ds = sl<AdminPlatformDataSource>();
      if (_searchQuery.isNotEmpty) {
        final found = await ds.searchBookings(
          _searchQuery,
          status: _filter,
          limit: 50,
        );
        _setLoaded(AdminPlatformDataSource.sortBookings(found, _sort), isSearching: true);
        return;
      }
      final page = await ds.getBookingsPage(
        status: _filter,
        limit: _pageSize,
        cursor: reset ? null : _cursor,
        sort: _sort,
      );
      _setLoaded(reset ? page.items : [..._bookings, ...page.items],
          cursor: page.cursor, hasMore: page.hasMore, total: page.total);
    } catch (_) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  void _setLoaded(
    List<BookingModel> bookings, {
    Object? cursor,
    bool hasMore = false,
    int? total,
    bool isSearching = false,
  }) {
    if (!mounted) return;
    setState(() {
      _bookings = bookings;
      _isSearching = isSearching;
      _cursor = cursor;
      _hasMore = hasMore;
      _total = total;
      _isLoading = false;
      _isLoadingMore = false;
    });
  }

  void _onSearchChanged(String value) {
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 400), () {
      final query = value.trim();
      if (query == _searchQuery) return;
      setState(() => _searchQuery = query);
      _load();
    });
  }

  void _onFilter(String filter) {
    if (filter == _filter) return;
    setState(() => _filter = filter);
    _load();
  }

  void _onSort(String sort) {
    if (sort == _sort) return;
    setState(() => _sort = sort);
    _load();
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
            AdminBookingListHeader(
              searchController: _searchController,
              onSearchChanged: _onSearchChanged,
              statuses: _statuses,
              filter: _filter,
              onFilter: _onFilter,
              sort: _sort,
              onSort: _onSort,
            ),
            const SizedBox(height: 16),
            if (!_isLoading && !_hasError && _bookings.isNotEmpty)
              _isSearching
                  ? Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          _bookings.length >= 50
                              ? l10n.adminAuditFirstMatches(50)
                              : l10n.adminAuditMatching(_bookings.length),
                          style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant),
                        ),
                      ),
                    )
                  : AdminCountLine(shown: _bookings.length, total: _total),
            Expanded(
              child: _isLoading
                  ? const AppLoadingState()
                  : _hasError
                      ? AppErrorState(
                          message: l10n.admin2_bookingsLoadFailed,
                          onRetry: _load,
                        )
                      : _bookings.isEmpty
                          ? AppEmptyState(
                              title: l10n.admin2_bookingsEmptyTitle,
                              message: l10n.admin2_bookingsEmptyHint,
                            )
                          : ListView.separated(
                          itemCount: _bookings.length +
                              (_hasMore && !_isSearching ? 1 : 0),
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            if (i >= _bookings.length) {
                              return AdminLoadMoreButton(
                                isLoadingMore: _isLoadingMore,
                                onPressed: () => _load(reset: false),
                              );
                            }
                            final b = _bookings[i];
                            return AdminBookingListTile(
                              booking: b,
                              compact: compact,
                              onTap: () => context.go(
                                RouteNames.adminBookingDetail
                                    .replaceFirst(':bookingId', b.bookingId),
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
}
