import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../../../../../core/constants/app_colors.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../data/datasources/customer_location_store.dart';
import '../../../domain/entities/shop_entity.dart';
import 'map_shop_preview_card.dart';
import 'radius_filter_pills.dart';
import 'shops_empty_banner.dart';
import 'shops_tab_data.dart';

/// Shared GPS fetch helper used by both [CustomerLocationPromptView] and
/// [CustomerHomeMapView]: checks location service, handles `denied` and
/// `deniedForever` (with an "Open settings" action), and resolves the
/// nearest known Pakistani city so saved locations never store
/// "My Live Location" as a city name.
Future<({ll.LatLng point, String? nearestCity})?> fetchCustomerGpsPoint(
  BuildContext context, {
  bool silent = false,
}) async {
  final l10n = AppLocalizations.of(context)!;
  try {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!silent && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.warning,
            content: Text(
              l10n.locationEnableGps,
              style: const TextStyle(
                color: AppColors.warningOnContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
            action: SnackBarAction(
              label: l10n.qrScanOpenSettings,
              textColor: AppColors.warningOnContainer,
              onPressed: () => Geolocator.openLocationSettings(),
            ),
          ),
        );
      }
      return null;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      if (!silent && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.errorDark,
            content: Text(l10n.locationPermissionDenied),
            action: SnackBarAction(
              label: l10n.qrScanOpenSettings,
              textColor: Colors.white,
              onPressed: () => Geolocator.openAppSettings(),
            ),
          ),
        );
      }
      return null;
    }
    if (permission != LocationPermission.whileInUse &&
        permission != LocationPermission.always) {
      if (!silent && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.errorDark,
            content: Text(l10n.locationPermissionDenied),
          ),
        );
      }
      return null;
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    final point = ll.LatLng(position.latitude, position.longitude);
    final nearestCity =
        ShopsTabData.nearestKnownCity(point.latitude, point.longitude);
    return (point: point, nearestCity: nearestCity);
  } catch (_) {
    return null;
  }
}

/// Persists a user-chosen or GPS-resolved point to [CustomerLocationStore].
Future<void> persistCustomerPoint(
  ll.LatLng point, {
  String? city,
  bool fromGps = false,
}) async {
  try {
    final resolvedCity = city ??
        ShopsTabData.nearestKnownCity(point.latitude, point.longitude) ??
        'Lahore';
    await CustomerLocationStore().save(
      CustomerLocation(
        latitude: point.latitude,
        longitude: point.longitude,
        city: resolvedCity,
        area:
            '${point.latitude.toStringAsFixed(4)}°N, ${point.longitude.toStringAsFixed(4)}°E',
        fromGps: fromGps,
      ),
    );
  } catch (_) {}
}

/// Shared 56dp GPS recenter button used on customer map screens.
class MapGpsFab extends StatelessWidget {
  const MapGpsFab({
    super.key,
    required this.heroTag,
    required this.locating,
    required this.onPressed,
    this.icon = Icons.gps_fixed_rounded,
  });

  final Object heroTag;
  final bool locating;
  final VoidCallback onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FloatingActionButton(
      heroTag: heroTag,
      tooltip: l10n.homeMyLiveLocation,
      backgroundColor: Theme.of(context).colorScheme.surface,
      foregroundColor: AppColors.secondary,
      elevation: 4,
      onPressed: locating ? null : onPressed,
      child: locating
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(AppColors.secondary),
              ),
            )
          : Icon(icon, size: 24),
    );
  }
}

/// Shared offline placeholder shown when map tiles cannot be loaded.
class MapOfflinePlaceholder extends StatelessWidget {
  const MapOfflinePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.map_outlined, size: 48),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              l10n.shops_mapOffline,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom-anchored overlay for [CustomerHomeMapView] stacking the radius
/// control cleanly above the empty banner or shop preview card (zero overlap).
class NearbyMapBottomOverlay extends StatelessWidget {
  const NearbyMapBottomOverlay({
    super.key,
    required this.loading,
    required this.hasShops,
    required this.selectedShop,
    required this.radiusKm,
    required this.radiusFilterActive,
    required this.onSelectRadius,
    required this.onClearRadius,
    required this.onClosePreview,
    required this.onOpenShop,
  });

  final bool loading;
  final bool hasShops;
  final ShopEntity? selectedShop;
  final double radiusKm;
  final bool radiusFilterActive;
  final ValueChanged<double> onSelectRadius;
  final VoidCallback onClearRadius;
  final VoidCallback onClosePreview;
  final ValueChanged<ShopEntity> onOpenShop;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Positioned(
      left: 16,
      right: 16,
      bottom: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingRadiusControl(
            selectedRadiusKm: radiusKm,
            filterActive: radiusFilterActive,
            onRadiusSelected: onSelectRadius,
            onClearRadius: onClearRadius,
          ),
          if (!loading && !hasShops) ...[
            const SizedBox(height: 10),
            ShopsEmptyBanner(text: l10n.shops_emptyTitle),
          ] else if (selectedShop != null) ...[
            const SizedBox(height: 10),
            MapShopPreviewCard(
              shop: selectedShop!,
              positioned: false,
              onClose: onClosePreview,
              onViewShowroom: () => onOpenShop(selectedShop!),
            ),
          ],
        ],
      ),
    );
  }
}
