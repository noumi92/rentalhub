import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../domain/entities/shop_entity.dart';
import '../cubit/shops_filter_state.dart';
import 'widgets/home_shop_list.dart';
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
    this.minDailyRateLoader,
    this.filterState,
    this.onShopSelected,
  });

  /// Test seam: override the Firestore shop read.
  final Future<List<ShopEntity>> Function()? shopsLoader;

  /// Test seam: override the `displayUnverifiedShops` setting read.
  final Future<bool> Function()? displayUnverifiedLoader;

  /// Test seam: override the per-shop cheapest-rate read (PW-4).
  final Future<int?> Function(String shopId)? minDailyRateLoader;

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

  /// FG-5: true when the shops fetch itself failed (not an empty
  /// result) — the view renders the error state with retry.
  bool _loadFailed = false;

  /// PW-4: cheapest available daily rate per shop id.
  Map<String, int> _minDailyRates = const {};

  /// PW-5: the city pre-select runs once per view instance.
  bool _preselectedCity = false;

  /// null until the permission check answers; false means no GPS
  /// permission, so the city menu below is the manual entry.
  bool? _locationAvailable;

  @override
  void initState() {
    super.initState();
    _filters = widget.filterState ?? ShopsFilterState.shared;
    _loadShops();
    _checkLocation();
    _preselectCity();
  }

  Future<void> _loadShops() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _loadFailed = false;
      });
    }
    final result = await ShopsTabData.loadShops(
      filters: _filters,
      shopsLoader: widget.shopsLoader,
      displayUnverifiedLoader: widget.displayUnverifiedLoader,
    );
    if (!mounted) return;
    setState(() {
      _shops = result.shops;
      _loadFailed = result.loadFailed;
      _loading = false;
    });
    if (!result.loadFailed) _loadMinRates();
  }

  /// PW-4: cheapest rates fill in after the list; a failure here
  /// never hides the shops.
  Future<void> _loadMinRates() async {
    final rates = await ShopsTabData.loadMinDailyRates(
      shops: _shops,
      minDailyRateLoader: widget.minDailyRateLoader,
    );
    if (!mounted) return;
    setState(() => _minDailyRates = rates);
  }

  /// PW-5: nearest known city by GPS, else the saved city — only
  /// when the user has not picked one yet.
  Future<void> _preselectCity() async {
    if (_preselectedCity) return;
    _preselectedCity = true;
    await ShopsTabData.preselectCity(_filters);
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
          // Audit 2026-11-15 DS-14: top: false — the shell strips
          // the top inset; a bare SafeArea double-insets outside it.
          body: SafeArea(
            top: false,
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
                // F-R1: ONE 60px scrollable filter row (city button
                // + verification chips). Chrome above the first card
                // is now app bar (56) + this row (60) = ~116px.
                ShopsFilterBar(
                  majorCities: shopsCityMenuEntries(l10n),
                  selectedCity: _filters.city ?? l10n.shops_allCities,
                  onSelectCity: _selectCity,
                  verification: _filters.verification,
                  onVerificationChanged: _filters.setVerification,
                  showUnverifiedFilter: _filters.displayUnverifiedShops,
                ),
                if (_locationAvailable == false)
                  ShopsLocationNote(text: l10n.shops_chooseCity),
                Expanded(
                  child: _loading
                      ? AppLoadingState(message: l10n.homeFindingShops)
                      : _loadFailed
                          // FG-5: a failed load is an error with
                          // retry, not an empty state.
                          ? AppErrorState(
                              message: l10n.shops_loadFailed,
                              onRetry: _loadShops,
                            )
                          : shops.isEmpty
                              // CU-m2: the shared empty state, not a
                              // hand-rolled icon + two Texts.
                              ? AppEmptyState(
                                  title: l10n.shops_emptyTitle,
                                  message: l10n.shops_emptySubtitle,
                                  icon: Icons.storefront_rounded,
                                )
                              : SingleChildScrollView(
                                  padding: const EdgeInsets.fromLTRB(
                                      16, 4, 16, 16),
                                  child: HomeShopList(
                                    shops: shops,
                                    minDailyRates: _minDailyRates,
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
