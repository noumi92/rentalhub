import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../domain/entities/shop_entity.dart';
import '../cubit/shops_filter_state.dart';
import 'widgets/city_selector_bar.dart';
import 'widgets/shop_list_card.dart';
import 'widgets/shops_filter_bar.dart';
import 'widgets/shops_location_note.dart';
import 'widgets/shops_tab_data.dart';
import '../../../../l10n/app_localizations.dart';

/// Shops tab — the DEFAULT view is the LISTING: shop list cards
/// (Verified/Unverified badge + fleet count) with the city and
/// verification filters. The map is not embedded here: the map
/// button in the app bar opens the full-screen Nearby showrooms map
/// ([CustomerHomeMapView]) at `/customer/shops/map`, and its back
/// arrow returns here. Both views read the same [ShopsFilterState],
/// so switching views never resets the filters.
///
/// Default filter is all shops — unverified shops are shown, never
/// silently hidden. When `platform_settings/global`
/// `displayUnverifiedShops` is OFF they are hidden in both views.
/// Bookings from unverified shops are NOT blocked here (testing):
/// their status is shown honestly, it is not a gate.
class CustomerShopsView extends StatefulWidget {
  const CustomerShopsView({
    super.key,
    this.shopsLoader,
    this.displayUnverifiedLoader,
    this.filterState,
    this.onShopSelected,
  });

  /// Test seam: override the Firestore shop read.
  final Future<List<ShopEntity>> Function()? shopsLoader;

  /// Test seam: override the `displayUnverifiedShops` setting read.
  final Future<bool> Function()? displayUnverifiedLoader;

  /// Test seam: the shared filter state (default [ShopsFilterState.shared]).
  final ShopsFilterState? filterState;

  /// Test seam: override the shop-page navigation.
  final ValueChanged<ShopEntity>? onShopSelected;

  @override
  State<CustomerShopsView> createState() => _CustomerShopsViewState();
}

class _CustomerShopsViewState extends State<CustomerShopsView> {
  late final ShopsFilterState _filters;
  List<ShopEntity> _shops = const [];
  bool _loading = true;

  /// null until the permission check answers; false means no GPS
  /// permission, so the city menu below is the manual entry.
  bool? _locationAvailable;

  @override
  void initState() {
    super.initState();
    _filters = widget.filterState ?? ShopsFilterState.shared;
    _loadShops();
    _checkLocation();
  }

  Future<void> _loadShops() async {
    final shops = await ShopsTabData.loadShops(
      filters: _filters,
      shopsLoader: widget.shopsLoader,
      displayUnverifiedLoader: widget.displayUnverifiedLoader,
    );
    if (!mounted) return;
    setState(() {
      _shops = shops;
      _loading = false;
    });
  }

  Future<void> _checkLocation() async {
    final available = await ShopsTabData.locationAvailable();
    if (!mounted) return;
    setState(() => _locationAvailable = available);
  }

  void _selectCity(Map<String, dynamic> city) {
    _filters.setCity(
        city['all'] == true ? null : city['name'] as String);
  }

  void _openShop(ShopEntity shop) {
    if (widget.onShopSelected != null) {
      widget.onShopSelected!.call(shop);
    } else {
      context.push(
        RouteNames.customerShopDetail.replaceFirst(':shopId', shop.shopId),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListenableBuilder(
      listenable: _filters,
      builder: (context, _) {
        final shops = _filters.apply(_shops);
        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                MinimalAppBar(
                  title: l10n.shops_title,
                  actions: [
                    IconButton(
                      tooltip: l10n.shops_showMap,
                      onPressed: () =>
                          context.push(RouteNames.customerShopsMap),
                      icon: const Icon(Icons.map_outlined,
                          color: Colors.white, size: 24),
                    ),
                  ],
                ),
                CitySelectorBar(
                  majorCities: shopsCityMenuEntries(l10n),
                  selectedCity: _filters.city ?? l10n.shops_allCities,
                  onSelectCity: _selectCity,
                ),
                ShopsFilterBar(
                  verification: _filters.verification,
                  onVerificationChanged: _filters.setVerification,
                  showUnverifiedFilter: _filters.displayUnverifiedShops,
                ),
                if (_locationAvailable == false)
                  ShopsLocationNote(text: l10n.shops_chooseCity),
                Expanded(
                  child: _loading
                      ? AppLoadingState(message: l10n.homeFindingShops)
                      : shops.isEmpty
                          // CU-m2: the shared empty state, not a
                          // hand-rolled icon + two Texts.
                          ? AppEmptyState(
                              title: l10n.shops_emptyTitle,
                              message: l10n.shops_emptySubtitle,
                              icon: Icons.storefront_rounded,
                            )
                          : SingleChildScrollView(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 4, 16, 16),
                              child: HomeShopList(
                                shops: shops,
                                onShopSelected: _openShop,
                              ),
                            ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Phase D (D3): the shop list section of the Shops tab, moved here
/// from the customer Home view (Worker C) — the Home screen itself no
/// longer renders it. Compact shows the single-column list exactly as
/// before; medium+ shows two columns of shop cards via
/// [twoColumnLayout]. The immersion tests pump it directly.
class HomeShopList extends StatelessWidget {
  final List<ShopEntity> shops;
  final ValueChanged<ShopEntity> onShopSelected;

  const HomeShopList({
    super.key,
    required this.shops,
    required this.onShopSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (!isMediumOrLarger(context)) {
      return Column(
        children: shops
            .map((shop) => ShopListCard(
                  shop: shop,
                  onTap: () => onShopSelected(shop),
                ))
            .toList(),
      );
    }
    return twoColumnLayout(
      key: const Key('home-shop-two-columns'),
      items: shops,
      itemSpacing: 0, // ShopListCard already has a 16 bottom margin.
      itemBuilder: (shop) => ShopListCard(
        shop: shop,
        onTap: () => onShopSelected(shop),
      ),
    );
  }
}
