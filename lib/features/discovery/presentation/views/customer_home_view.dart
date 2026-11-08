import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/custom_curved_header.dart';
import '../../data/datasources/customer_location_store.dart';
import '../../data/datasources/discovery_remote_data_source.dart';
import '../../data/repositories/discovery_repository_impl.dart';
import '../../domain/entities/shop_entity.dart';
import '../../domain/usecases/get_nearby_shops_usecase.dart';
import '../cubit/discovery_cubit.dart';
import 'widgets/empty_radar_state.dart';
import 'widgets/home_quick_actions.dart';
import 'widgets/radius_filter_pills.dart';
import 'widgets/shop_list_card.dart';
import 'widgets/shop_map_view.dart';
import '../../../../l10n/app_localizations.dart';

class CustomerHomeView extends StatelessWidget {
  final ValueChanged<ShopEntity>? onShopSelected;

  const CustomerHomeView({super.key, this.onShopSelected});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DiscoveryCubit(
        getNearbyShopsUseCase: GetNearbyShopsUseCase(
          DiscoveryRepositoryImpl(
            remoteDataSource: DiscoveryRemoteDataSource(),
          ),
        ),
      )..fetchNearbyShops(radiusKm: 3.0),
      child: _CustomerHomeBody(onShopSelected: onShopSelected),
    );
  }
}

class _CustomerHomeBody extends StatefulWidget {
  final ValueChanged<ShopEntity>? onShopSelected;

  const _CustomerHomeBody({this.onShopSelected});

  @override
  State<_CustomerHomeBody> createState() => _CustomerHomeBodyState();
}

class _CustomerHomeBodyState extends State<_CustomerHomeBody> {
  @override
  void initState() {
    super.initState();
    // B1: the location prompt saved the customer's pick; search from it
    // instead of the Lahore default the cubit starts with.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final stored = await CustomerLocationStore().load();
      if (!mounted || stored == null) return;
      final cubit = context.read<DiscoveryCubit>();
      final current = cubit.currentLocation;
      if (stored.latitude != current.latitude ||
          stored.longitude != current.longitude) {
        cubit.setLocation(stored);
      }
    });
  }

  /// Phase A (A1): a shop tap opens the real shop route. The
  /// [onShopSelected] override is kept for embedded use (tests / widgets
  /// that host the home view); the app itself always uses the route.
  void _openShop(BuildContext context, ShopEntity shop) {
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
    return Scaffold(
      // Phase D (D2): the only tab root that lacked a SafeArea — the
      // header and content now clear the status bar like the other
      // nine tab roots do.
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: BlocBuilder<DiscoveryCubit, DiscoveryState>(
                builder: (context, state) {
                  final cubit = context.read<DiscoveryCubit>();
                  double radiusKm = 3.0;
                  bool isMap = false;
                  List<ShopEntity> shops = const [];

                  if (state is DiscoveryLoaded) {
                    radiusKm = state.currentRadiusKm;
                    isMap = state.isMapView;
                    shops = state.shops;
                  } else if (state is DiscoveryEmpty) {
                    radiusKm = state.currentRadiusKm;
                  }

                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomCurvedHeader(
                          variant: CustomCurvedHeaderVariant.hero,
                          showProfileGreeting: true,
                          titleWidget: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.homeTitle,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, color: Colors.white),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                cubit.currentLocation.fromGps
                                    ? l10n.homeGpsActive(cubit.currentLocation.area)
                                    : cubit.currentLocation.area,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.primaryContainer),
                              ),
                            ],
                          ),
                          actions: [
                            IconButton(
                              tooltip: l10n.homeSwitchToMap,
                              onPressed: () => context.push(RouteNames.customerHomeMap),
                              icon: const Icon(Icons.map_rounded, color: AppColors.secondary),
                            ),
                          ],
                        ),
                        HeaderOverlapContainer(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: RadiusFilterPills(
                                      selectedRadiusKm: radiusKm,
                                      onRadiusSelected: (km) =>
                                          cubit.fetchNearbyShops(radiusKm: km),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // E1: quick actions sit between the radius
                                // filter and the shop list / map, in every
                                // state (loading, empty, loaded).
                                const CustomerHomeQuickActions(),
                                const SizedBox(height: 12),
                                if (state is DiscoveryLoading)
                                  // E2: shared loading state; the empty
                                  // state below stays the domain-specific
                                  // EmptyRadarState (expand-radius action).
                                   AppLoadingState(message: l10n.homeFindingShops)
                                else if (state is DiscoveryEmpty)
                                  EmptyRadarState(
                                    currentRadiusKm: radiusKm,
                                    onExpandRadius: () =>
                                        cubit.fetchNearbyShops(radiusKm: 5.0),
                                  )
                                else if (isMap)
                                  ShopMapView(
                                    shops: shops,
                                    radiusKm: radiusKm,
                                    userLocation: ll.LatLng(
                                      cubit.currentLocation.latitude,
                                      cubit.currentLocation.longitude,
                                    ),
                                    onShopSelected: (shop) =>
                                        _openShop(context, shop),
                                  )
                                else
                                  HomeShopList(
                                    shops: shops,
                                    onShopSelected: (shop) =>
                                        _openShop(context, shop),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
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

/// Phase D (D3): the shop list section of the customer home. Compact
/// shows the single-column list exactly as before; medium+ shows two
/// columns of shop cards via [twoColumnLayout]. The map view is
/// untouched — it stays full-width.
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
