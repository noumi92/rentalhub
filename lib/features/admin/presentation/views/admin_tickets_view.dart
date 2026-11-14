import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/datasources/admin_support_data_source.dart';
import '../widgets/admin_load_more_button.dart';
import '../widgets/admin_shell.dart';
import '../widgets/admin_ticket_list_tile.dart';
import '../widgets/ticket_detail_sheet.dart';

/// Phase E (E1) — the support tickets inbox: every ticket the
/// customer form wrote, with its SLA countdown (High 1 h, Medium
/// 4 h, Low 24 h). Tap a ticket for the thread — replies, internal
/// notes, quick replies, Close / Escalate.
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
  String _searchQuery = '';
  Object? _cursor;
  bool _hasMore = false;

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
  }) {
    if (!mounted) return;
    setState(() {
      _tickets = tickets;
      _isSearching = isSearching;
      _cursor = cursor;
      _hasMore = hasMore;
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
            TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: l10n?.adminAuditSearchTicketsHint ??
                    'Search by message or customer ID…',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: Theme.of(context).dividerColor),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                children: [
                  for (final entry in {
                    'all': l10n?.filterAll ?? 'All',
                    'open': l10n?.admin2_open ?? 'Open',
                    'in_progress': l10n?.admin2_inProgress ?? 'In progress',
                    'escalated': l10n?.admin2_escalated ?? 'Escalated',
                    'closed': l10n?.admin2_closed ?? 'Closed',
                  }.entries)
                    ChoiceChip(
                      label: Text(entry.value),
                      selected: _filter == entry.key,
                      onSelected: (_) {
                        setState(() {
                          _filter = entry.key;
                          _isLoading = true;
                        });
                        _load();
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (!_isLoading && !_hasError && _tickets.isNotEmpty)
              AdminListCountLabel(
                label: _isSearching
                    ? (_tickets.length >= _pageSize
                        ? (l10n?.adminAuditFirstMatches(_pageSize) ??
                            'First $_pageSize matches')
                        : (l10n?.adminAuditMatching(_tickets.length) ??
                            '${_tickets.length} matching entries'))
                    : (l10n?.adminAuditShowing(_tickets.length) ??
                        'Showing ${_tickets.length}'),
              ),
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
                              onTap: () => showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                builder: (_) => TicketDetailSheet(
                                  ticket: t,
                                  onChanged: _load,
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
}
