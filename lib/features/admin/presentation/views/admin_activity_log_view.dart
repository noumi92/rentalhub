import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/datasources/admin_remote_data_source.dart';
import '../widgets/admin_activity_log_filters.dart';
import '../widgets/admin_audit_log_list.dart';
import '../widgets/admin_shell.dart';

/// Phase A (A5) — the activity log: every admin action, newest first,
/// with a text filter and a CSV export. The `audit_logs` collection is
/// immutable in Firestore rules (read admin, create authenticated,
/// update/delete never), so nothing here can edit or delete an entry.
class AdminActivityLogView extends StatefulWidget {
  const AdminActivityLogView({super.key});

  @override
  State<AdminActivityLogView> createState() => _AdminActivityLogViewState();
}

class _AdminActivityLogViewState extends State<AdminActivityLogView> {
  static const _pageSize = 50;

  final _searchController = TextEditingController();
  final _actorController = TextEditingController();
  Timer? _actorTimer;
  List<AuditLogEntry> _entries = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasError = false;
  String? _actionPrefix;
  String _actorQuery = '';
  DateTime? _from;
  DateTime? _to;
  int _totalMatching = 0;
  Object? _cursor;
  bool _hasMore = false;

  bool get _hasServerFilter =>
      _actionPrefix != null ||
      _actorQuery.isNotEmpty ||
      _from != null ||
      _to != null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _actorController.dispose();
    _actorTimer?.cancel();
    super.dispose();
  }

  // F-m2 + F-m3: the log pages (50 at a time) instead of stopping
  // at a silent 200-row cap, and the action/actor/date filters run
  // server-side — the old text search only ever covered the loaded
  // page, and now covers the loaded (filtered) entries.
  Future<void> _load({bool reset = true}) async {
    if (reset) {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _entries = [];
        _cursor = null;
        _hasMore = false;
        _totalMatching = 0;
      });
    } else {
      setState(() => _isLoadingMore = true);
    }
    try {
      final ds = sl<AdminRemoteDataSource>();
      if (_hasServerFilter) {
        // The To bound is the end of the picked day, not midnight
        // at its start — otherwise the whole To day is dropped
        // from the filtered log (same class as F-M17).
        final filterTo = _to == null
            ? null
            : DateTime(_to!.year, _to!.month, _to!.day, 23, 59, 59);
        final entries = await ds.getAuditLogsFiltered(
          actionPrefix: _actionPrefix,
          actorEmail: _actorQuery.isEmpty ? null : _actorQuery,
          from: _from,
          to: filterTo,
        );
        final total = await ds.countAuditLogsFiltered(
          actionPrefix: _actionPrefix,
          actorEmail: _actorQuery.isEmpty ? null : _actorQuery,
          from: _from,
          to: filterTo,
        );
        _setLoaded(entries, total: total);
        return;
      }
      final page = await ds.getAuditLogsPage(
        limit: _pageSize,
        cursor: reset ? null : _cursor,
      );
      _setLoaded(
        reset ? page.items : [..._entries, ...page.items],
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
    List<AuditLogEntry> entries, {
    int total = 0,
    Object? cursor,
    bool hasMore = false,
  }) {
    if (!mounted) return;
    setState(() {
      _entries = entries;
      _totalMatching = total;
      _cursor = cursor;
      _hasMore = hasMore;
      _isLoading = false;
      _isLoadingMore = false;
    });
  }

  void _onActorChanged(String value) {
    _actorTimer?.cancel();
    _actorTimer = Timer(const Duration(milliseconds: 400), () {
      final query = value.trim();
      if (query == _actorQuery) return;
      setState(() => _actorQuery = query);
      _load();
    });
  }

  void _clearFilters() {
    _actorController.clear();
    setState(() {
      _actionPrefix = null;
      _actorQuery = '';
      _from = null;
      _to = null;
    });
    _load();
  }

  List<AuditLogEntry> get _visible {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _entries;
    return _entries.where((e) {
      return e.action.toLowerCase().contains(query) ||
          e.actorEmail.toLowerCase().contains(query) ||
          e.targetType.toLowerCase().contains(query) ||
          e.detail.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final compact =
        windowSizeClassOf(context) == WindowSizeClass.compact;
    final l10n = AppLocalizations.of(context);
    final searching = _searchController.text.trim().isNotEmpty;
    final countLabel = _entries.isEmpty || _isLoading || _hasError
        ? null
        : searching
            ? (l10n?.adminAuditShowing(_visible.length) ??
                'Showing ${_visible.length}')
            : _hasServerFilter
                ? (l10n?.adminAuditMatching(_totalMatching) ??
                    '$_totalMatching matching entries')
                : (l10n?.adminAuditShowing(_entries.length) ??
                    'Showing ${_entries.length}');
    return AdminShell(
      activeRoute: RouteNames.adminActivity,
      title: l10n?.admin2_navActivityLog ?? 'Activity Log',
      subtitle: l10n?.admin2_activitySubtitle ??
          'Every admin action, newest first — immutable',
      onRefresh: _load,
      child: Padding(
        padding: EdgeInsets.all(compact ? 16 : 24),
        child: Column(
          children: [
            AdminActivityLogFilters(
              searchController: _searchController,
              onSearchChanged: (_) => setState(() {}),
              actionPrefix: _actionPrefix,
              onActionChanged: (value) {
                setState(() => _actionPrefix = value);
                _load();
              },
              actorController: _actorController,
              onActorChanged: _onActorChanged,
              from: _from,
              to: _to,
              onDatesChanged: (from, to) {
                setState(() {
                  _from = from;
                  _to = to;
                });
                _load();
              },
              onClearFilters: _clearFilters,
              exportEntries: _visible,
              compact: compact,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: AdminAuditLogList(
                isLoading: _isLoading,
                hasError: _hasError,
                onRetry: _load,
                entries: _visible,
                countLabel: countLabel,
                compact: compact,
                hasMore: _hasMore && !_hasServerFilter,
                isLoadingMore: _isLoadingMore,
                onLoadMore: () => _load(reset: false),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
