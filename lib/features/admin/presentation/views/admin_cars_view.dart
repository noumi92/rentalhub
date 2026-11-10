import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/money_format.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../fleet/domain/entities/vehicle_entity.dart';
import '../../data/datasources/admin_shops_data_source.dart';
import '../widgets/admin_shell.dart';
import '../widgets/car_review_detail_sheet.dart';

/// Phase B (B3) — the cars list: every vehicle on the platform, with
/// its admin review state. Tap a car for the review sheet
/// (Approve / Hide / Reject).
class AdminCarsView extends StatefulWidget {
  const AdminCarsView({super.key});

  @override
  State<AdminCarsView> createState() => _AdminCarsViewState();
}

class _AdminCarsViewState extends State<AdminCarsView> {
  final _searchController = TextEditingController();
  List<VehicleEntity> _cars = [];
  Map<String, CarReview> _reviews = {};
  bool _isLoading = true;
  String _filter = 'all';

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
    final ds = sl<AdminShopsDataSource>();
    final cars = await ds.getCars();
    final reviews = await ds.getCarReviews();
    if (mounted) {
      setState(() {
        _cars = cars;
        _reviews = reviews;
        _isLoading = false;
      });
    }
  }

  List<VehicleEntity> get _visible {
    final query = _searchController.text.trim().toLowerCase();
    return _cars.where((v) {
      final review = _reviews[v.vehicleId]?.status ?? 'pending';
      final matchesFilter = _filter == 'all' || review == _filter;
      final matchesQuery = query.isEmpty ||
          '${v.make} ${v.model}'.toLowerCase().contains(query) ||
          v.plateNumber.toLowerCase().contains(query);
      return matchesFilter && matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AdminShell(
      activeRoute: RouteNames.adminCars,
      title: 'Cars',
      subtitle: 'Every vehicle listing, with its review state',
      onRefresh: _load,
      child: Padding(
        // Mobile-first: 16dp on a phone, 24dp on desktop (same rule
        // as the other admin lists).
        padding: EdgeInsets.all(
            windowSizeClassOf(context) == WindowSizeClass.compact
                ? 16
                : 24),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search by car or plate number…',
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
                children: [
                  for (final entry in {
                    'all': 'All',
                    'pending': 'Pending',
                    'approved': 'Approved',
                    'hidden': 'Hidden',
                    'rejected': 'Rejected',
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
            SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _visible.isEmpty
                      ? Center(
                          child: Text(
                            'No cars match — the list reads the vehicles collection.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                        )
                      : ListView.separated(
                          itemCount: _visible.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            final car = _visible[i];
                            final review =
                                _reviews[car.vehicleId]?.status ?? 'pending';
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
                                  child: const Icon(
                                      Icons.directions_car_rounded,
                                      ),
                                ),
                                title: Text(
                                    '${car.make} ${car.model} (${car.year})',
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        )),
                                subtitle: Text(
                                  '${car.plateNumber} • ${l10n.fleetDailyRate(formatRs(car.rates.daily24))} • ${car.status}',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                                ),
                                trailing: _reviewChip(context, review),
                                onTap: () => showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  builder: (_) => CarReviewDetailSheet(
                                    vehicle: car,
                                    review: _reviews[car.vehicleId],
                                    onDecided: _load,
                                  ),
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

  Widget _reviewChip(BuildContext context, String review) {
    final brightness = Theme.of(context).brightness;
    final color = switch (review) {
      'approved' => AppColors.successTextFor(brightness),
      'hidden' => AppColors.warningTextFor(brightness),
      'rejected' => AppColors.dangerTextFor(brightness),
      _ => Theme.of(context).colorScheme.onSurfaceVariant,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(review,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w800, color: color)),
    );
  }
}
