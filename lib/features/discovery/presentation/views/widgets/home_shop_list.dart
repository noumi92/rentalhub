import 'package:flutter/material.dart';

import '../../../../../core/utils/responsive.dart';
import '../../../domain/entities/shop_entity.dart';
import 'shop_list_card.dart';

/// The shop list section of the Shops tab (Phase D, D3). Compact
/// shows the single-column list; medium+ shows two columns of shop
/// cards. The immersion tests pump it directly.
///
/// BP-13: spacing lives BETWEEN items only (16 dp separators) — the
/// cards carry no bottom margin, so the last item sits at the scroll
/// padding (16 dp), not margin + padding (32 dp).
class HomeShopList extends StatelessWidget {
  final List<ShopEntity> shops;
  final ValueChanged<ShopEntity> onShopSelected;

  /// PW-4: cheapest available daily rate per shop id.
  final Map<String, int> minDailyRates;

  const HomeShopList({
    super.key,
    required this.shops,
    required this.onShopSelected,
    this.minDailyRates = const {},
  });

  Widget _card(ShopEntity shop) => ShopListCard(
        shop: shop,
        minDailyRate: minDailyRates[shop.shopId],
        onTap: () => onShopSelected(shop),
      );

  List<Widget> _separated(List<ShopEntity> items) => [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: 16),
          _card(items[i]),
        ],
      ];

  @override
  Widget build(BuildContext context) {
    if (!isMediumOrLarger(context)) {
      return Column(children: _separated(shops));
    }
    final columns = <List<ShopEntity>>[[], []];
    for (var i = 0; i < shops.length; i++) {
      columns[i % 2].add(shops[i]);
    }
    return Row(
      key: const Key('home-shop-two-columns'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Column(children: _separated(columns[0]))),
        const SizedBox(width: 14),
        Expanded(child: Column(children: _separated(columns[1]))),
      ],
    );
  }
}
