import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/money_format.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../fleet/domain/entities/vehicle_entity.dart';
import '../../data/datasources/admin_shops_data_source.dart';
import '../widgets/admin_count_line.dart';
import '../widgets/admin_list_card.dart';
import '../widgets/admin_scoped_list_banner.dart';
import '../widgets/admin_section_tabs.dart';
import '../widgets/admin_sort_menu.dart';
import '../widgets/admin_shell.dart';
import '../widgets/admin_status_chip.dart';
import '../widgets/car_review_detail_sheet.dart';

/// Platform fleet vehicles list with review status.
class AdminCarsView extends StatefulWidget {
  const AdminCarsView({super.key, this.shopId});

  final String? shopId; // Step 2 — when set, shows only this shop's cars.
  @override
  State<AdminCarsView> createState() => _AdminCarsViewState();
}

class _AdminCarsViewState extends State<AdminCarsView> {
  final _searchController = TextEditingController();
  List<VehicleEntity> _cars = [];
  Map<String, CarReview> _reviews = {};
  bool _isLoading = true;
  bool _hasError = false;
  String _filter = 'all';
  String _sort = AdminListSort.nameAsc;
  int? _total;

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
      final ds = sl<AdminShopsDataSource>();
      final cars = await ds.getCars();
      final reviews = await ds.getCarReviews();
      final total = await ds.countCars();
      if (mounted) {
        setState(() {
          _cars = scopedCars(cars, widget.shopId);
          _reviews = reviews;
          _total = widget.shopId == null ? total : _cars.length;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _hasError = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<VehicleEntity> get _visible {
    final query = _searchController.text.trim().toLowerCase();
    final visible = _cars.where((v) {
      final review = _reviews[v.vehicleId]?.status ?? 'pending';
      final matchesFilter = _filter == 'all' || review == _filter;
      final matchesQuery = query.isEmpty ||
          '${v.make} ${v.model}'.toLowerCase().contains(query) ||
          v.plateNumber.toLowerCase().contains(query);
      return matchesFilter && matchesQuery;
    }).toList();
    // Phase 4 (4.3) — client-side sort (the list is client-side:
    // [AdminShopsDataSource.getCars] caps at 200). Name orders by
    // make + model, date by model year, status by review state.
    String name(VehicleEntity v) => '${v.make} ${v.model}';
    String reviewOf(VehicleEntity v) => _reviews[v.vehicleId]?.status ?? 'pending';
    switch (_sort) {
      case AdminListSort.nameDesc:
        visible.sort((a, b) => name(b).compareTo(name(a)));
      case AdminListSort.dateNewest:
        visible.sort((a, b) => b.year.compareTo(a.year));
      case AdminListSort.dateOldest:
        visible.sort((a, b) => a.year.compareTo(b.year));
      case AdminListSort.statusAsc:
        visible.sort((a, b) => reviewOf(a).compareTo(reviewOf(b)));
      default:
        visible.sort((a, b) => name(a).compareTo(name(b)));
    }
    return visible;
  }

  void _onSort(String sort) {
    if (sort == _sort) return;
    setState(() => _sort = sort);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AdminShell(
      activeRoute: RouteNames.adminCars,
      title: l10n.admin2_navCars,
      subtitle: l10n.admin2_carsSubtitle,
      subTabs: widget.shopId == null
          ? AdminSectionTabs.shopsAndFleet(context, activeRoute: RouteNames.adminCars)
          : const [],
      onRefresh: _load,
      onBack: backToShopDetail(context, widget.shopId),
      child: Padding(
        padding: EdgeInsets.all(
            windowSizeClassOf(context) == WindowSizeClass.compact ? 16 : 24),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: l10n.admin2_carsSearchHint,
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
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final entry in {
                    'all': l10n.filterAll,
                    'pending': l10n.pending,
                    'approved': l10n.statusApproved,
                    'hidden': l10n.admin2_hidden,
                    'rejected': l10n.statusRejected,
                  }.entries)
                    ChoiceChip(
                      label: Text(entry.value),
                      selected: _filter == entry.key,
                      onSelected: (_) =>
                          setState(() => _filter = entry.key),
                    ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AdminSortMenu(
                  options: [
                    AdminSortOption(
                        id: AdminListSort.nameAsc,
                        label: l10n.adminSortNameAsc),
                    AdminSortOption(
                        id: AdminListSort.nameDesc,
                        label: l10n.adminSortNameDesc),
                    AdminSortOption(
                        id: AdminListSort.dateNewest,
                        label: l10n.adminSortDateNewest),
                    AdminSortOption(
                        id: AdminListSort.dateOldest,
                        label: l10n.adminSortDateOldest),
                    AdminSortOption(
                        id: AdminListSort.statusAsc,
                        label: l10n.adminSortStatus),
                  ],
                  selectedId: _sort,
                  onSelected: _onSort,
                ),
              ],
            ),
            SizedBox(height: 16),
            if (widget.shopId != null) const AdminScopedListBanner(),
            if (!_isLoading && !_hasError && _visible.isNotEmpty)
              AdminCountLine(shown: _visible.length, total: _total),
            Expanded(
              child: _isLoading
                  ? const AppLoadingState()
                  : _hasError
                      ? AppErrorState(
                          message: l10n.admin2_carsLoadFailed,
                          onRetry: _load,
                        )
                      : _visible.isEmpty
                          ? AppEmptyState(
                              title: l10n.admin2_carsEmptyTitle,
                              message: l10n.admin2_carsEmptyHint,
                            )
                          : ListView.separated(
                          itemCount: _visible.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            final car = _visible[i];
                            final review =
                                _reviews[car.vehicleId]?.status ?? 'pending';
                            // Phase 4 (4.1) — the shared [AdminListCard]
                            // shell; the chip is
                            // [AdminStatusChip.carReviewStatus].
                            return AdminListCard(
                              icon: Icons.directions_car_rounded,
                              title:
                                  '${car.make} ${car.model} (${car.year})',
                              subtitle:
                                  '${car.plateNumber} • ${l10n.fleetDailyRate(formatRs(car.rates.daily24))} • ${humanizeStatus(car.status, l10n)}',
                              trailing: AdminStatusChip.carReviewStatus(
                                  review, AppLocalizations.of(context)),
                              onTap: () => showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                // Phase 1 (1.5): drag handle on the sheet.
                                showDragHandle: true,
                                builder: (_) => CarReviewDetailSheet(
                                  vehicle: car,
                                  review: _reviews[car.vehicleId],
                                  onDecided: _load,
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
