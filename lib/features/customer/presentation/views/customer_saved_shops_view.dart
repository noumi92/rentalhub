import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../customer/data/datasources/customer_remote_data_source.dart';
import '../../../customer/domain/entities/customer_entity.dart';
import '../../../discovery/data/models/shop_model.dart';
import '../../../discovery/domain/entities/shop_entity.dart';
import '../../../../l10n/app_localizations.dart';

// H5: saved showrooms now come from the signed-in customer's own
// record (`savedShopIds`, heart on the shop detail screen) and the
// shop docs are read from Firestore. The two hardcoded demo shops
// ('Al-Falah Rent a Car', 'Capital Wheels Islamabad') are gone.
// Unsaving removes the shop from the list immediately.
class CustomerSavedShopsView extends StatefulWidget {
  final ValueChanged<ShopEntity>? onSelectShop;
  final VoidCallback? onBack;

  const CustomerSavedShopsView({
    super.key,
    this.onSelectShop,
    this.onBack,
  });

  @override
  State<CustomerSavedShopsView> createState() => _CustomerSavedShopsViewState();
}

class _CustomerSavedShopsViewState extends State<CustomerSavedShopsView> {
  bool _loading = true;
  CustomerEntity? _customer;
  List<ShopEntity> _shops = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    CustomerEntity? customer;
    List<ShopEntity> shops = [];
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        customer = await sl<CustomerRemoteDataSource>().getCustomerById(uid);
        for (final shopId in customer?.savedShopIds ?? const <String>[]) {
          final doc = await FirebaseFirestore.instance
              .collection('shops')
              .doc(shopId)
              .get();
          final data = doc.data();
          if (data != null) {
            shops.add(ShopModel.fromMap(data, id: doc.id));
          }
        }
      }
    } catch (_) {}
    if (mounted) {
      setState(() {
        _customer = customer;
        _shops = shops;
        _loading = false;
      });
    }
  }

  Future<void> _unsave(ShopEntity shop) async {
    final l10n = AppLocalizations.of(context)!;
    final customer = _customer;
    if (customer == null) return;
    final ids = List<String>.from(customer.savedShopIds)..remove(shop.shopId);
    final updated = customer.copyWith(savedShopIds: ids);
    setState(() {
      _customer = updated;
      _shops = _shops.where((s) => s.shopId != shop.shopId).toList();
    });
    try {
      await sl<CustomerRemoteDataSource>().upsertCustomer(updated);
    } catch (_) {
      if (mounted) {
        AppFeedback.showError(context, l10n.savedShopsRemoveError);
        _load();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            MinimalAppBar(
              title: l10n.profileSavedShops,
              onBack: widget.onBack,
            ),
            Expanded(
              // CU-m2: the shared loading / empty states, not a bare
              // spinner and a hand-rolled empty column.
              child: _loading
                  ? const AppLoadingState()
                  : _shops.isEmpty
                      ? AppEmptyState(
                          title: l10n.savedShopsEmpty,
                          message: l10n.savedShopsEmptyHint,
                          icon: Icons.favorite_border_rounded,
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          itemCount: _shops.length,
                          itemBuilder: (context, index) {
                            final shop = _shops[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: InkWell(
                                onTap: () => widget.onSelectShop?.call(shop),
                                borderRadius: BorderRadius.circular(16),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: const Icon(
                                            Icons.storefront_rounded,
                                            color: AppColors.primary),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(shop.shopName,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleSmall
                                                    ?.copyWith(
                                                        fontWeight: FontWeight.w600)),
                                            const SizedBox(height: 2),
                                            Text(
                                                shop.city.isEmpty
                                                    ? shop.address
                                                    : '${shop.address}, ${shop.city}',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .labelSmall
                                                    ?.copyWith(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .onSurfaceVariant)),
                                            // Numbers the shop document never stored are hidden, never shown with the display-only fallback (4.9 / 8 cars).
                                            if (shop.hasRealRating ||
                                                shop.hasRealAvailableCount)
                                              const SizedBox(height: 4),
                                            if (shop.hasRealRating ||
                                                shop.hasRealAvailableCount)
                                              Row(
                                                children: [
                                                  if (shop.hasRealRating) ...[
                                                    const Icon(
                                                        Icons.star_rounded,
                                                        size: 14,
                                                        color: AppColors
                                                            .warning),
                                                    const SizedBox(width: 3),
                                                    Text('${shop.rating}',
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .labelSmall
                                                            ?.copyWith(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700)),
                                                    const SizedBox(width: 8),
                                                  ],
                                                  if (shop
                                                      .hasRealAvailableCount)
                                                    Text(
                                                        l10n.shopCarsReady(shop
                                                            .availableCount),
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .labelSmall
                                                            ?.copyWith(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                color: AppColors
                                                                    .successTextFor(Theme.of(context).brightness))),
                                                ],
                                              ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.favorite_rounded,
                                            size: 20,
                                            color: AppColors.secondary),
                                        tooltip: l10n.savedShopsRemove,
                                        onPressed: () => _unsave(shop),
                                      ),
                                    ],
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
}
