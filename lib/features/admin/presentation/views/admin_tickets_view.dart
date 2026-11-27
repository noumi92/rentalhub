import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/datasources/admin_support_data_source.dart';
import '../widgets/admin_count_line.dart';
import '../widgets/admin_load_more_button.dart';
import '../widgets/admin_shell.dart';
import '../widgets/admin_ticket_list_header.dart';
import '../widgets/admin_ticket_list_tile.dart';

/// Phase E (E1) — the support tickets inbox: every ticket the
/// customer form wrote, with its SLA countdown (High 1 h, Medium
/// 4 h, Low 24 h). Tap a ticket for its detail route — the thread,
/// replies, internal notes, quick replies, Close / Escalate.
class AdminTicketsView extends StatefulWidget {
  const AdminTicketsView({super.key});

  @override
  State<AdminTicketsView> createState() => _AdminTicketsViewState();
}

class _AdminTicketsViewState extends State<AdminTicketsView> {
  static const _pageSize = 50;

  final _searchController = TextEditingController();
  Timer? _searchTimer;
  List<SupportTicket> _tickets = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasError = false;
  bool _isSearching = false;
  String _filter = 'all';
  String _sort = 'dateNewest';
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

  // F-m2: the inbox pages (50 at a time) instead of stopping at a
  // silent 100-row cap, and search covers the whole inbox through
  // the data source instead of only the loaded page.
  Future<void> _load({bool reset = true}) async {
    if (reset) {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _tickets = [];
        _cursor = null;
        _hasMore = false;
      });
    } else {
      setState(() => _isLoadingMore = true);
    }
    try {
      final ds = sl<AdminSupportDataSource>();
      if (_searchQuery.isNotEmpty) {
        final found = await ds.searchTickets(
          _searchQuery,
          status: _filter,
          limit: _pageSize,
        );
        _setLoaded(found, isSearching: true);
        return;
      }
      final page = await ds.getTicketsPage(
        status: _filter,
        limit: _pageSize,
        cursor: reset ? null : _cursor,
      );
      _setLoaded(
        reset ? page.items : [..._tickets, ...page.items],
        cursor: page.cursor,
        hasMore: page.hasMore,
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
    List<SupportTicket> tickets, {
    Object? cursor,
    bool hasMore = false,
    bool isSearching = false,
    int? total,
  }) {
    if (!mounted) return;
    setState(() {
      _tickets = tickets;
      _isSearching = isSearching;
      _cursor = cursor;
      _hasMore = hasMore;
      _total = total;
      _isLoading = false;
      _isLoadingMore = false;
    });
  }

  void _onFilter(String filter) {
    if (filter == _filter) return;
    setState(() {
      _filter = filter;
      _isLoading = true;
    });
    _load();
  }

  void _onSort(String sort) {
    if (sort == _sort) return;
    setState(() => _sort = sort);
    _load();
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

  @override
  Widget build(BuildContext context) {
    final compact =
        windowSizeClassOf(context) == WindowSizeClass.compact;
    final l10n = AppLocalizations.of(context);
    return AdminShell(
      activeRoute: RouteNames.adminTickets,
      title: l10n?.admin2_ticketsTitle ?? 'Support tickets',
      subtitle: l10n?.admin2_ticketsSubtitle ?? 'The inbox the customer plan promised',
      onRefresh: _load,
      child: Padding(
        padding: EdgeInsets.all(compact ? 16 : 24),
        child: Column(
          children: [
            AdminTicketListHeader(
              searchController: _searchController,
              onSearchChanged: _onSearchChanged,
              filter: _filter,
              onFilter: _onFilter,
              sort: _sort,
              onSort: _onSort,
            ),
            const SizedBox(height: 16),
            if (!_isLoading && !_hasError && _tickets.isNotEmpty)
              _isSearching
                  ? AdminListCountLabel(
                      label: _tickets.length >= _pageSize
                          ? (l10n?.adminAuditFirstMatches(_pageSize) ??
                              'First $_pageSize matches')
                          : (l10n?.adminAuditMatching(_tickets.length) ??
                              '${_tickets.length} matching entries'),
                    )
                  : AdminCountLine(shown: _tickets.length, total: _total),
            Expanded(
              child: _isLoading
                  ? const AppLoadingState()
                  : _hasError
                      ? AppErrorState(
                          message: l10n?.admin2_ticketsLoadFailed ??
                              'Could not load the tickets.',
                          onRetry: _load,
                        )
                      : _tickets.isEmpty
                          ? AppEmptyState(
                              title: l10n?.admin2_ticketsEmptyTitle ??
                                  'No tickets',
                              message: l10n?.admin2_ticketsEmptyHint ??
                                  'The inbox reads the support_tickets collection.',
                            )
                          : ListView.separated(
                          itemCount: _tickets.length +
                              (_hasMore && !_isSearching ? 1 : 0),
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            if (i >= _tickets.length) {
                              return AdminLoadMoreButton(
                                isLoadingMore: _isLoadingMore,
                                onPressed: () => _load(reset: false),
                              );
                            }
                            final t = _tickets[i];
                            return AdminTicketListTile(
                              ticket: t,
                              // Phase 2 (2.4): a ticket navigates to
                              // its detail route — the thread sheet
                              // now lives inside that route, not over
                              // the inbox.
                              onTap: () => context.go(
                                  RouteNames.adminTicketDetail
                                      .replaceFirst(':ticketId', t.id)),
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
