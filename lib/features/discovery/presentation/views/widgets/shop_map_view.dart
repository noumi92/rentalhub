import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../../../../../core/constants/app_colors.dart';
import '../../../domain/entities/shop_entity.dart';
import '../../../../../l10n/app_localizations.dart';

/// B2: the inline map on the customer home list — a real OpenStreetMap
/// canvas with the customer's position and one marker per verified shop.
/// The old version was a static "radar" drawing with the shops placed at
/// fixed offsets, so it showed the same picture whatever the real
/// locations were.
class ShopMapView extends StatelessWidget {
  final List<ShopEntity> shops;
  final double radiusKm;
  final ll.LatLng userLocation;
  final ValueChanged<ShopEntity> onShopSelected;

  const ShopMapView({
    super.key,
    required this.shops,
    required this.radiusKm,
    required this.userLocation,
    required this.onShopSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      height: 280,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: userLocation,
              initialZoom: 13.0,
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
                    point: userLocation,
                    radius: radiusKm * 1000,
                    useRadiusInMeter: true,
                    color: AppColors.secondary.withValues(alpha: 0.08),
                    borderColor: AppColors.secondary,
                    borderStrokeWidth: 1.5,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: userLocation,
                    width: 30,
                    height: 30,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.my_location_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                  ...shops.map((shop) {
                    final pos = ll.LatLng(
                      shop.geoLocation.latitude,
                      shop.geoLocation.longitude,
                    );
                    return Marker(
                      point: pos,
                      width: 130,
                      height: 60,
                      alignment: Alignment.bottomCenter,
                      // E3: the map marker is a labelled button for screen
                      // readers; the tap behaviour is unchanged.
                      child: Semantics(
                        button: true,
                        label: l10n.mapShowShop(shop.shopName),
                        child: GestureDetector(
                          onTap: () => onShopSelected(shop),
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
                                    color: AppColors.secondary,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            Colors.black.withValues(alpha: 0.3),
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
                                const Icon(
                                  Icons.location_on_rounded,
                                  size: 26,
                                  color: AppColors.secondary,
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
          ),
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                l10n.mapGpsRadar(radiusKm.toInt(), shops.length),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
