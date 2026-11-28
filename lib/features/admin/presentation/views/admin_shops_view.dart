import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../discovery/data/models/shop_model.dart';
import '../../data/datasources/admin_shops_data_source.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../l10n/app_localizations_en.dart';
import '../widgets/admin_count_line.dart';
import '../widgets/admin_load_more_button.dart';
import '../widgets/admin_section_tabs.dart';
import '../widgets/admin_sort_menu.dart';
import '../widgets/admin_shop_list_header.dart';
import '../widgets/admin_shell.dart';
import '../widgets/admin_shop_list_tile.dart';

/// Shops & Fleet directory with horizontal sub-tabs and pagination.
class AdminShopsView extends StatefulWidget {
  const AdminShopsView({super.key, this.initialFilter = 'all'});

  /// The status filter to start on ('all' | 'approved' | 'pending' |
  /// 'suspended'). The router passes the `?filter=` query parameter.
  final String initialFilter;

  @override
  State<AdminShopsView> createState() => _AdminShopsViewState();
}

class _AdminShopsViewState extends State<AdminShopsView> {
  static const _pageSize = 20;
  static const _filters = ['all', 'approved', 'pending', 'suspended'];

  final _searchController = TextEditingController();
  Timer? _searchTimer;
  List<ShopModel> _shops = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasError = false;
  bool _isSearching = false;
  late String _filter;
  String _sort = AdminListSort.nameAsc;
  String _searchQuery = '';
  Object? _cursor;
  bool _hasMore = false;
  int? _total;

  @override
  void initState() {
    super.initState();
    _filter =
        _filters.contains(widget.initialFilter) ? widget.initialFilter : 'all';
    _load();
  }

  @override
  void didUpdateWidget(covariant AdminShopsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialFilter != widget.initialFilter) {
      final next = _filters.contains(widget.initialFilter)
          ? widget.initialFilter
          : 'all';
      if (next != _filter) {
        setState(() => _filter = next);
        _load();
      }
    }
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
        _shops = [];
        _cursor = null;
        _hasMore = false;
        _total = null;
      });
    } else {
      setState(() => _isLoadingMore = true);
    }
    try {
      final ds = sl<AdminShopsDataSource>();
      if (_searchQuery.isNotEmpty) {
        final found = await ds.searchShops(_searchQuery, limit: 50);
        _setLoaded(AdminShopsDataSource.sortShops(found, _sort),
            isSearching: true);
        return;
      }
      final page = await ds.getShopsPage(
        limit: _pageSize,
        cursor: reset ? null : _cursor,
        statusFilter: _filter,
        sort: _sort,
      );
      _setLoaded(
        reset ? page.items : [..._shops, ...page.items],
        cursor: page.cursor,
        hasMore: page.hasMore,
        total: page.total,
      );
    } catch (_) {
      if (mounted) { setState(() { _hasError = true; _isLoading = false; _isLoadingMore = false; }); }
    }
  }

  void _setLoaded(List<ShopModel> shops, {Object? cursor, bool hasMore = false, int? total, bool isSearching = false}) {
    if (!mounted) return;
    setState(() {
      _shops = shops;
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
    final l10n = (AppLocalizations.of(context) ?? AppLocalizationsEn());
    return AdminShell(
      activeRoute: RouteNames.adminShops,
      title: l10n.adminNavShopsAndFleet,
      subtitle: l10n.admin2_shopsSubtitle,
      subTabs: AdminSectionTabs.shopsAndFleet(
        context,
        activeRoute: RouteNames.adminShops,
        activeFilter: _filter,
      ),
      onRefresh: _load,
      child: Padding(
        padding: EdgeInsets.all(
            windowSizeClassOf(context) == WindowSizeClass.compact ? 16 : 24),
        child: Column(
          children: [
            AdminShopListHeader(
              searchController: _searchController,
              onSearchChanged: _onSearchChanged,
              filter: _filter,
              onFilter: _onFilter,
              sort: _sort,
              onSort: _onSort,
            ),
            const SizedBox(height: 8),
            if (!_isLoading && !_hasError && _shops.isNotEmpty)
              _isSearching
                  ? Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          _shops.length >= 50
                              ? l10n.adminAuditFirstMatches(50)
                              : l10n.adminAuditMatching(_shops.length),
                          style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant),
                        ),
                      ),
                    )
                  : AdminCountLine(shown: _shops.length, total: _total),
            Expanded(
              child: _isLoading
                  ? const AppLoadingState()
                  : _hasError
                      ? AppErrorState(
                          message: l10n.admin2_shopsLoadFailed,
                          onRetry: _load,
                        )
                      : _shops.isEmpty
                          ? AppEmptyState(
                              title: l10n.admin2_shopsEmptyTitle,
                              message: l10n.admin2_shopsEmptyHint,
                            )
                          : ListView.separated(
                              itemCount: _shops.length +
                                  (_hasMore && !_isSearching ? 1 : 0),
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, i) {
                                if (i >= _shops.length) {
                                  return AdminLoadMoreButton(
                                    isLoadingMore: _isLoadingMore,
                                    onPressed: () => _load(reset: false),
                                  );
                                }
                                final shop = _shops[i];
                                return AdminShopListTile(
                                  shop: shop,
                                  onTap: () => context.go(
                                    RouteNames.adminShopDetail
                                        .replaceFirst(':shopId', shop.shopId),
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
