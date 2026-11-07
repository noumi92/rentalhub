import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/custom_curved_header.dart';
import '../../data/datasources/customer_location_store.dart';
import '../../data/datasources/discovery_remote_data_source.dart';
import '../../data/repositories/discovery_repository_impl.dart';
import '../../domain/entities/shop_entity.dart';
import '../../domain/usecases/get_nearby_shops_usecase.dart';
import '../cubit/discovery_cubit.dart';
import '../../../customer/presentation/widgets/customer_bottom_nav.dart';
import 'widgets/empty_radar_state.dart';
import 'widgets/radius_filter_pills.dart';
import 'widgets/shop_list_card.dart';
import 'widgets/shop_map_view.dart';

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
    return Scaffold(
      bottomNavigationBar: const CustomerBottomNav(currentIndex: 0),
      body: BlocBuilder<DiscoveryCubit, DiscoveryState>(
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
                  height: 195,
                  showProfileGreeting: true,
                  titleWidget: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Find Verified Rental Shops',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        cubit.currentLocation.fromGps
                            ? '${cubit.currentLocation.area} • GPS Active'
                            : cubit.currentLocation.area,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.primaryContainer),
                      ),
                    ],
                  ),
                  actions: [
                    IconButton(
                      tooltip: 'Switch to Interactive Map',
                      onPressed: () => context.go(RouteNames.customerHomeMap),
                      icon: const Icon(
                        Icons.map_rounded,
                        color: AppColors.secondary,
                      ),
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
                        if (state is DiscoveryLoading)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(28),
                              child: CircularProgressIndicator(),
                            ),
                          )
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
                          ...shops.map(
                            (shop) => ShopListCard(
                              shop: shop,
                              onTap: () => _openShop(context, shop),
                            ),
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
    );
  }
}

