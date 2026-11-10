import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/responsive.dart';
import '../../../discovery/data/models/shop_model.dart';
import '../../data/datasources/admin_shops_data_source.dart';
import '../widgets/admin_shell.dart';

/// Phase B (B2) — the shops list: every shop, searchable, filtered by
/// status. Tap a shop for the detail screen (plan, cars, bookings,
/// suspend, message owner).
class AdminShopsView extends StatefulWidget {
  const AdminShopsView({super.key});

  @override
  State<AdminShopsView> createState() => _AdminShopsViewState();
}

class _AdminShopsViewState extends State<AdminShopsView> {
  final _searchController = TextEditingController();
  List<ShopModel> _shops = [];
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
    final shops = await sl<AdminShopsDataSource>().getShops();
    if (mounted) {
      setState(() {
        _shops = shops;
        _isLoading = false;
      });
    }
  }

  List<ShopModel> get _visible {
    final query = _searchController.text.trim().toLowerCase();
    return _shops.where((s) {
      final matchesFilter = switch (_filter) {
        'suspended' => s.suspended,
        'pending' => s.verificationStatus == 'pending',
        'approved' =>
          s.verificationStatus == 'approved' && !s.suspended,
        _ => true,
      };
      final matchesQuery = query.isEmpty ||
          s.shopName.toLowerCase().contains(query) ||
          s.city.toLowerCase().contains(query) ||
          (s.ownerName ?? '').toLowerCase().contains(query);
      return matchesFilter && matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      activeRoute: RouteNames.adminShops,
      title: 'Shops',
      subtitle: 'Every showroom on the platform',
      onRefresh: _load,
      child: Padding(
        // Mobile-first: 16dp on a phone, 24dp on desktop.
        padding: EdgeInsets.all(
            windowSizeClassOf(context) == WindowSizeClass.compact
                ? 16
                : 24),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search by shop, city, or owner…',
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
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () =>
                      context.go(RouteNames.adminApprovals),
                  icon: const Icon(Icons.verified_user_rounded, size: 18),
                  label: const Text('Approvals'),
                  // 48dp touch target; the search field flexes, so a
                  // large text scale narrows the field, never overflows.
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                children: [
                  for (final entry in {
                    'all': 'All',
                    'approved': 'Approved',
                    'pending': 'Pending',
                    'suspended': 'Suspended',
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
                            'No shops match — the list reads the shops collection.',
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
                            final shop = _visible[i];
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
                                  child: const Icon(Icons.store_rounded,
                                      ),
                                ),
                                title: Text(shop.shopName,
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        )),
                                subtitle: Text(
                                  // Honesty flag (Worker 1): a number the
                                  // shop document never stored is hidden,
                                  // never shown with the display-only
                                  // fallback — same as shop_list_card.dart.
                                  '${shop.city} • Plan ${shop.plan}${shop.hasRealRating ? ' • Rating ${shop.rating.toStringAsFixed(1)}' : ''}',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                                ),
                                trailing: _statusChip(shop),
                                onTap: () => context.go(
                                  RouteNames.adminShopDetail
                                      .replaceFirst(':shopId', shop.shopId),
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

  Widget _statusChip(ShopModel shop) {
    final label = shop.suspended
        ? 'Suspended'
        : shop.verificationStatus == 'pending'
            ? 'Pending'
            : shop.verificationStatus == 'approved'
                ? 'Approved'
                : shop.verificationStatus;
    final color = shop.suspended
        ? Colors.red.shade700
        : shop.verificationStatus == 'pending'
            ? Colors.amber.shade800
            : Colors.green.shade700;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w800, color: color)),
    );
  }
}
