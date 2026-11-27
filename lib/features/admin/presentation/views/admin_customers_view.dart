import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/datasources/admin_people_data_source.dart';
import '../widgets/admin_count_line.dart';
import '../widgets/admin_customer_list_header.dart';
import '../widgets/admin_customer_list_tile.dart';
import '../widgets/admin_load_more_button.dart';
import '../widgets/admin_shell.dart';

/// Phase C (C1) — the customers list: every customer, searchable,
/// with their CNIC state. Tap a customer for the detail screen
/// (trust score with breakdown, KYC, bookings, notes, actions).
class AdminCustomersView extends StatefulWidget {
  const AdminCustomersView({super.key});

  @override
  State<AdminCustomersView> createState() => _AdminCustomersViewState();
}

class _AdminCustomersViewState extends State<AdminCustomersView> {
  static const _pageSize = 20;

  final _searchController = TextEditingController();
  Timer? _searchTimer;
  List<AdminCustomerRow> _rows = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasError = false;
  bool _isSearching = false;
  String _cnicFilter = 'all';
  String _sort = 'nameAsc';
  String _searchQuery = '';
  Object? _cursor;
  bool _hasMore = false;
  int? _total;

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

  // F-m2 + F-m8: the list pages (20 rows at a time) instead of
  // stopping at a silent 200-row cap, search covers the whole
  // list through the data source, and each row carries its stored
  // trust score and flags.
  Future<void> _load({bool reset = true}) async {
    if (reset) {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _rows = [];
        _cursor = null;
        _hasMore = false;
        _total = null;
      });
    } else {
      setState(() => _isLoadingMore = true);
    }
    try {
      final ds = sl<AdminPeopleDataSource>();
      if (_searchQuery.isNotEmpty) {
        final found = await ds.searchCustomers(
          _searchQuery,
          limit: 50,
        );
        _setLoaded(AdminPeopleDataSource.sortCustomerRows(found, _sort),
            isSearching: true);
        return;
      }
      // Phase 4 (4.4c): the unfiltered total, so the list can say
      // "Showing first N of M" (the CNIC filter has no
      // server-side count, so filtered lists report no total).
      final total =
          _cnicFilter == 'all' ? await ds.countCustomers() : null;
      final page = await ds.getCustomersPage(
        limit: _pageSize,
        cursor: reset ? null : _cursor,
        cnicFilter: _cnicFilter,
        sort: _sort,
      );
      _setLoaded(
        reset ? page.items : [..._rows, ...page.items],
        cursor: page.cursor,
        hasMore: page.hasMore,
        total: total,
      );
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
    List<AdminCustomerRow> rows, {
    Object? cursor,
    bool hasMore = false,
    bool isSearching = false,
    int? total,
  }) {
    if (!mounted) return;
    setState(() {
      _rows = rows;
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

  void _onCnicFilter(String filter) {
    if (filter == _cnicFilter) return;
    setState(() => _cnicFilter = filter);
    _load();
  }

  void _onSort(String sort) {
    if (sort == _sort) return;
    setState(() => _sort = sort);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AdminShell(
      activeRoute: RouteNames.adminCustomers,
      title: l10n?.admin2_navCustomers ?? 'Customers',
      subtitle: l10n?.admin2_customersSubtitle ?? 'Every customer on the platform',
      onRefresh: _load,
      child: Padding(
        // Mobile-first: 16dp on a phone, 24dp on desktop.
        padding: EdgeInsets.all(
            windowSizeClassOf(context) == WindowSizeClass.compact
                ? 16
                : 24),
        child: Column(
          children: [
            AdminCustomerListHeader(
              searchController: _searchController,
              onSearchChanged: _onSearchChanged,
              cnicFilter: _cnicFilter,
              onCnicFilter: _onCnicFilter,
              sort: _sort,
              onSort: _onSort,
            ),
            const SizedBox(height: 16),
            if (!_isLoading && !_hasError && _rows.isNotEmpty)
              _isSearching
                  ? Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          _rows.length >= 50
                              ? (l10n?.adminAuditFirstMatches(50) ??
                                  'First 50 matches')
                              : (l10n?.adminAuditMatching(_rows.length) ??
                                  '${_rows.length} matching entries'),
                          style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant),
                        ),
                      ),
                    )
                  : AdminCountLine(shown: _rows.length, total: _total),
            Expanded(
              child: _isLoading
                  ? const AppLoadingState()
                  : _hasError
                      ? AppErrorState(
                          message: l10n?.admin2_customersLoadFailed ?? 'Could not load the customers.',
                          onRetry: _load,
                        )
                      : _rows.isEmpty
                          ? AppEmptyState(
                              title: l10n?.admin2_customersEmptyTitle ??
                                  'No customers match',
                              message: l10n?.admin2_customersEmptyHint ??
                                  'The list reads the customers collection.',
                            )
                          : ListView.separated(
                          itemCount: _rows.length +
                              (_hasMore && !_isSearching ? 1 : 0),
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            if (i >= _rows.length) {
                              return AdminLoadMoreButton(
                                isLoadingMore: _isLoadingMore,
                                onPressed: () => _load(reset: false),
                              );
                            }
                            return AdminCustomerListTile(row: _rows[i]);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
