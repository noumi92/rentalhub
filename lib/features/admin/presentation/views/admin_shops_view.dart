import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../discovery/data/models/shop_model.dart';
import '../../data/datasources/admin_shops_data_source.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../l10n/app_localizations_en.dart';
import '../widgets/admin_shell.dart';
import '../widgets/admin_status_chip.dart';

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
  bool _hasError = false;
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
    if (!_isLoading) setState(() => _hasError = false);
    try {
      final shops = await sl<AdminShopsDataSource>().getShops();
      if (mounted) {
        setState(() {
          _shops = shops;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _hasError = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
    final l10n = (AppLocalizations.of(context) ?? AppLocalizationsEn());
    return AdminShell(
      activeRoute: RouteNames.adminShops,
      title: l10n.admin2_navShops,
      subtitle: l10n.admin2_shopsSubtitle,
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
                      hintText: l10n.admin2_shopsSearchHint,
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
                  label: Text(l10n.admin2_navApprovals),
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
                    'all': l10n.filterAll,
                    'approved': l10n.statusApproved,
                    'pending': l10n.pending,
                    'suspended': l10n.admin2_suspended,
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
                  ? const AppLoadingState()
                  : _hasError
                      ? AppErrorState(
                          message: l10n.admin2_shopsLoadFailed,
                          onRetry: _load,
                        )
                      : _visible.isEmpty
                          ? AppEmptyState(
                              title: l10n.admin2_shopsEmptyTitle,
                              message: l10n.admin2_shopsEmptyHint,
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
                                        )),
                                subtitle: Text(
                                  // Honesty flag (Worker 1): a number the
                                  // shop document never stored is hidden,
                                  // never shown with the display-only
                                  // fallback — same as shop_list_card.dart.
                                  '${shop.city} • ${l10n.admin2_shopsPlanLine(shop.plan)}${shop.hasRealRating ? ' • ${l10n.admin2_shopRating(shop.rating.toStringAsFixed(1))}' : ''}',
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
    final l10n = (AppLocalizations.of(context) ?? AppLocalizationsEn());
    final label = shop.suspended
        ? l10n.admin2_suspended
        : shop.verificationStatus == 'pending'
            ? l10n.pending
            : shop.verificationStatus == 'approved'
                ? l10n.statusApproved
                : humanizeStatus(shop.verificationStatus, l10n);
    final tone = shop.suspended
        ? AdminStatusTone.danger
        : shop.verificationStatus == 'pending'
            ? AdminStatusTone.warning
            : shop.verificationStatus == 'approved'
                ? AdminStatusTone.success
                : AdminStatusTone.neutral;
    return AdminStatusChip(label: label, tone: tone);
  }
}
