import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/routing/route_names.dart';
import '../../../discovery/data/models/shop_model.dart';
import '../../data/datasources/admin_shops_data_source.dart';
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final pending = await sl<AdminShopsDataSource>().getPendingShops();
    if (mounted) {
      setState(() {
        _pending = pending;
        _isLoading = false;
      });
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
    return AdminShell(
      activeRoute: RouteNames.adminApprovals,
      title: 'Shop Approvals',
      subtitle: 'Applications waiting for a decision',
      onRefresh: _load,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pending.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'No pending applications — every shop has been decided.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMuted),
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(24),
                  itemCount: _pending.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final shop = _pending[i];
                    final checklist =
                        ShopApplicationChecklist.fromShop(shop);
                    return Card(
                      margin: EdgeInsets.zero,
                      elevation: 0,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: AppColors.border),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.royalNavy
                              .withValues(alpha: 0.12),
                          child: const Icon(Icons.store_rounded,
                              color: AppColors.royalNavy),
                        ),
                        title: Text(shop.shopName,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppColors.midnightNavy)),
                        subtitle: Text(
                          '${shop.city} • ${shop.ownerName ?? 'Owner not listed'} • Checklist ${checklist.doneCount}/6',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textMuted),
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
