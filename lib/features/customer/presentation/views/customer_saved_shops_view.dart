import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/custom_curved_header.dart';
import '../../../customer/data/datasources/customer_remote_data_source.dart';
import '../../../customer/domain/entities/customer_entity.dart';
import '../../../discovery/data/models/shop_model.dart';
import '../../../discovery/domain/entities/shop_entity.dart';

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
  State<CustomerSavedShopsView> createState() =>
      _CustomerSavedShopsViewState();
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
        customer =
            await sl<CustomerRemoteDataSource>().getCustomerById(uid);
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
    final customer = _customer;
    if (customer == null) return;
    final ids = List<String>.from(customer.savedShopIds)
      ..remove(shop.shopId);
    final updated = customer.copyWith(savedShopIds: ids);
    setState(() {
      _customer = updated;
      _shops = _shops.where((s) => s.shopId != shop.shopId).toList();
    });
    try {
      await sl<CustomerRemoteDataSource>().upsertCustomer(updated);
    } catch (_) {
      if (mounted) {
        AppFeedback.showError(context, 'Could not remove this showroom.');
        _load();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            CustomCurvedHeader(
              height: 100,
              leadingWidget: widget.onBack != null
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 20),
                      onPressed: widget.onBack,
                    )
                  : null,
              titleWidget: const Text(
                'Saved Showrooms',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _shops.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.favorite_border_rounded,
                                  size: 46, color: AppColors.textSecondary),
                              SizedBox(height: 8),
                              Text('No saved showrooms yet.',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary)),
                              SizedBox(height: 4),
                              Text(
                                  'Tap the heart on any showroom to save it here.',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          itemCount: _shops.length,
                          itemBuilder: (context, index) {
                            final shop = _shops[index];
                            return Card(
                              elevation: 0,
                              margin: const EdgeInsets.only(bottom: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: const BorderSide(
                                    color: AppColors.border),
                              ),
                              child: InkWell(
                                onTap: () =>
                                    widget.onSelectShop?.call(shop),
                                borderRadius: BorderRadius.circular(16),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: AppColors.lavenderMist,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: const Icon(
                                            Icons.storefront_rounded,
                                            color: AppColors.royalNavy),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(shop.shopName,
                                                style: const TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w800,
                                                    color: AppColors
                                                        .midnightNavy)),
                                            const SizedBox(height: 2),
                                            Text(
                                                '${shop.address}, ${shop.city}',
                                                style: const TextStyle(
                                                    fontSize: 11.5,
                                                    color: AppColors
                                                        .textSecondary)),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                const Icon(
                                                    Icons.star_rounded,
                                                    size: 14,
                                                    color: AppColors.amberGold),
                                                const SizedBox(width: 3),
                                                Text('${shop.rating}',
                                                    style: const TextStyle(
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w700)),
                                                const SizedBox(width: 8),
                                                Text(
                                                    '• ${shop.availableCount} Cars Ready',
                                                    style: const TextStyle(
                                                        fontSize: 11,
                                                        color: AppColors
                                                            .emeraldGreen,
                                                        fontWeight:
                                                            FontWeight.w600)),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                            Icons.favorite_rounded,
                                            size: 20,
                                            color: AppColors.sunsetOrange),
                                        tooltip: 'Remove from saved',
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
