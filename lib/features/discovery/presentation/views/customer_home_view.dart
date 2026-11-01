import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/custom_curved_header.dart';
import '../../data/datasources/discovery_remote_data_source.dart';
import '../../data/repositories/discovery_repository_impl.dart';
import '../../domain/entities/shop_entity.dart';
import '../../domain/usecases/get_nearby_shops_usecase.dart';
import '../cubit/discovery_cubit.dart';
import 'shop_detail_view.dart';
import 'vehicle_detail_view.dart';
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

class _CustomerHomeBody extends StatelessWidget {
  final ValueChanged<ShopEntity>? onShopSelected;

  const _CustomerHomeBody({this.onShopSelected});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
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
                  titleWidget: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Find Verified Rental Shops',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Gulberg III, Lahore • GPS Active',
                        style: TextStyle(
                          color: AppColors.textLavender,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    IconButton(
                      tooltip: 'Switch to Interactive Map',
                      onPressed: () => context.go(RouteNames.customerHomeMap),
                      icon: const Icon(
                        Icons.map_rounded,
                        color: AppColors.sunsetOrange,
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
                            onShopSelected: (shop) =>
                                onShopSelected?.call(shop),
                          )
                        else
                          ...shops.map(
                            (shop) => ShopListCard(
                              shop: shop,
                              onTap: () {
                                if (onShopSelected != null) {
                                  onShopSelected?.call(shop);
                                } else {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => ShopDetailView(
                                        shop: shop,
                                        onBack: () =>
                                            Navigator.of(context).pop(),
                                        onVehicleSelected: (vehicle) {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) => VehicleDetailView(
                                                vehicle: vehicle,
                                                onBack: () =>
                                                    Navigator.of(context).pop(),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                }
                              },
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

