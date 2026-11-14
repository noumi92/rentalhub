import 'package:flutter/material.dart';

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
import '../widgets/shop_application_detail_sheet.dart';

/// Phase B (B1) — the shop approvals queue: every shop whose
/// application is still pending, with the review sheet that decides it.
/// A shop's application is its `shops` document; there is no separate
/// applications collection.
class AdminShopApprovalsView extends StatefulWidget {
  const AdminShopApprovalsView({super.key});

  @override
  State<AdminShopApprovalsView> createState() =>
      _AdminShopApprovalsViewState();
}

class _AdminShopApprovalsViewState extends State<AdminShopApprovalsView> {
  List<ShopModel> _pending = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!_isLoading) setState(() => _hasError = false);
    try {
      final pending = await sl<AdminShopsDataSource>().getPendingShops();
      if (mounted) {
        setState(() {
          _pending = pending;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _hasError = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openReview(ShopModel shop) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => ShopApplicationDetailSheet(
        shop: shop,
        onDecided: _load,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = (AppLocalizations.of(context) ?? AppLocalizationsEn());
    return AdminShell(
      activeRoute: RouteNames.adminApprovals,
      title: l10n.admin2_approvalsTitle,
      subtitle: l10n.admin2_approvalsSubtitle,
      onRefresh: _load,
      child: _isLoading
          ? const AppLoadingState()
          : _hasError
              ? AppErrorState(
                  message: l10n.admin2_approvalsLoadFailed,
                  onRetry: _load,
                )
              : _pending.isEmpty
                  ? AppEmptyState(
                      title: l10n.admin2_approvalsEmptyTitle,
                      message: l10n.admin2_approvalsEmptyHint,
                    )
                  : ListView.separated(
                  // Mobile-first: 16dp on a phone, 24dp on desktop.
                  padding: EdgeInsets.all(
                      windowSizeClassOf(context) ==
                              WindowSizeClass.compact
                          ? 16
                          : 24),
                  itemCount: _pending.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final shop = _pending[i];
                    final checklist =
                        ShopApplicationChecklist.fromShop(shop, l10n);
                    return Card(
                      margin: EdgeInsets.zero,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Theme.of(context).dividerColor),
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
                          '${shop.city} • ${shop.ownerName ?? l10n.admin2_ownerNotListed} • ${l10n.admin2_approvalsChecklist(checklist.doneCount)}',
                          style: TextStyle(
                              fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                        trailing: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16),
                        onTap: () => _openReview(shop),
                      ),
                    );
                  },
                ),
    );
  }
}
