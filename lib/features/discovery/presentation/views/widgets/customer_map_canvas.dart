import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../../../../../core/constants/app_colors.dart';
import '../../../domain/entities/shop_entity.dart';
import '../../../../../l10n/app_localizations.dart';

/// B2: the real map canvas for the customer map screen, extracted so the
/// view stays under the 250-line cap. OpenStreetMap tiles, the customer's
/// position with a radius circle, and one marker per verified shop.
class CustomerMapCanvas extends StatelessWidget {
  const CustomerMapCanvas({
    super.key,
    required this.mapController,
    required this.userPoint,
    required this.radiusKm,
    required this.shops,
    required this.selectedShop,
    required this.onShopSelected,
  });

  final MapController mapController;
  final ll.LatLng userPoint;
  final double radiusKm;
  final List<ShopEntity> shops;
  final ShopEntity? selectedShop;
  final ValueChanged<ShopEntity> onShopSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final selected = selectedShop;
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: userPoint,
        initialZoom: 13.5,
        minZoom: 5.0,
        maxZoom: 18.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'pk.rentalhub.rentalhub',
        ),
        CircleLayer(
          circles: [
            CircleMarker(
              point: userPoint,
              radius: radiusKm * 1000,
              useRadiusInMeter: true,
              color: AppColors.secondary.withValues(alpha: 0.10),
              borderColor: AppColors.secondary,
              borderStrokeWidth: 1.5,
            ),
          ],
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: userPoint,
              width: 38,
              height: 38,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.my_location_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            ...shops.map((shop) {
              final isSelected = selected?.shopId == shop.shopId;
              final pos = ll.LatLng(
                shop.geoLocation.latitude,
                shop.geoLocation.longitude,
              );
              return Marker(
                point: pos,
                width: 150,
                height: 72,
                alignment: Alignment.bottomCenter,
                // E3: the map marker is a labelled button for screen
                // readers; the tap behaviour is unchanged.
                child: Semantics(
                  button: true,
                  label: l10n.mapShowShop(shop.shopName),
                  child: GestureDetector(
                    onTap: () {
                      onShopSelected(shop);
                      mapController.move(pos, 14.0);
                    },
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.bottomCenter,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.secondary
                                  : AppColors.primary,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: Text(
                              '${shop.shopName.split(' ').first} • ${shop.distanceKm.toStringAsFixed(1)}km',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white),
                            ),
                          ),
                          Icon(
                            Icons.location_on_rounded,
                            size: isSelected ? 32 : 26,
                            color: isSelected
                                ? AppColors.secondary
                                : AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ],
    );
  }
}
