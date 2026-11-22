import 'package:flutter/material.dart';
import '../../../../../l10n/app_localizations.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/app_map_tile_layer.dart';

class ShopLocationStepWidget extends StatelessWidget {
  final MapController mapController;
  final ll.LatLng shopPin;
  final ValueChanged<ll.LatLng> onPinChanged;
  final TextEditingController addressController;
  final String selectedCity;
  final ValueChanged<String> onCityChanged;
  final List<Map<String, dynamic>> majorCities;
  final bool isLocating;
  final VoidCallback onFetchGps;

  const ShopLocationStepWidget({
    super.key,
    required this.mapController,
    required this.shopPin,
    required this.onPinChanged,
    required this.addressController,
    required this.selectedCity,
    required this.onCityChanged,
    required this.majorCities,
    required this.isLocating,
    required this.onFetchGps,
  });

  @override
  Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.onboardingSelectCity,
          style: Theme.of(context)
              .textTheme
              .labelMedium
              ?.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 6),
        // Audit §5 finish (P2-3): city is a dropdown, not chips.
        // `initialValue` (not the deprecated `value`) keeps the
        // selection without a second analyze info finding.
        DropdownButtonFormField<String>(
          // Audit §5: DropdownButtonFormField's `initialValue` is
          // the non-deprecated API; do not switch it to `value`.
          initialValue: majorCities.any((c) => c['name'] == selectedCity)
              ? selectedCity
              : (majorCities.first['name'] as String),
          isExpanded: true,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.location_city_rounded,
                color: AppColors.secondary, size: 20),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Theme.of(context).dividerColor)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Theme.of(context).dividerColor)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.secondary, width: 1.5)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          items: majorCities
              .map((city) => DropdownMenuItem<String>(
                    value: city['name'] as String,
                    child: Text(city['name'] as String,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ),
                  ))
              .toList(),
          onChanged: (name) {
            if (name == null) return;
            onCityChanged(name);
            final coords = majorCities
                .firstWhere((c) => c['name'] == name)['coords'] as ll.LatLng;
            onPinChanged(coords);
            mapController.move(coords, 13.0);
          },
        ),
        const SizedBox(height: 14),

        // Interactive Map with Pin Placement (Requirement 5: Map is connected)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.onboardingPinOnMap,
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(fontWeight: FontWeight.w500),
            ),
            TextButton.icon(
              onPressed: isLocating ? null : onFetchGps,
              icon: isLocating
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  // Audit §1/C3: small orange text uses the
                  // brightness-aware token, not AppColors.secondary.
                  : Icon(Icons.my_location_rounded,
                      size: 16, color: AppColors.orangeTextFor(Theme.of(context).brightness)),
              label: Text(
                isLocating ? l10n.onboardingLocating : l10n.onboardingUseGps,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w400, color: AppColors.orangeTextFor(Theme.of(context).brightness)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 220,
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              children: [
                FlutterMap(
                  mapController: mapController,
                  options: MapOptions(
                    initialCenter: shopPin,
                    initialZoom: 14.0,
                    onTap: (tapPosition, point) {
                      onPinChanged(point);
                    },
                  ),
                  children: [
                    const AppMapTileLayer(),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: shopPin,
                          width: 44,
                          height: 44,
                          alignment: Alignment.bottomCenter,
                          child: const Icon(
                            Icons.location_on_rounded,
                            size: 40,
                            color: AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                    const AppOsmAttribution(alignment: Alignment.topLeft),
                  ],
                ),
                // Audit §1: the 220px map sits inside a scroll view, so
                // vertical drags scroll the page instead of panning.
                // flutter_map has no eager-gesture option, so the map
                // expands to a full-screen dialog on tap.
                Positioned(
                  top: 8,
                  right: 8,
                  child: Material(
                    color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(10),
                    child: IconButton(
                      tooltip: l10n.onboardingPinOnMap,
                      onPressed: () => _expandMap(context),
                      constraints:
                          const BoxConstraints(minWidth: 48, minHeight: 48),
                      icon: Icon(
                        Icons.fullscreen_rounded,
                        size: 22,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  left: 8,
                  right: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      // Audit §1: hardcoded white + theme onSurface text
                      // was ~1:1 in dark mode — theme surface + explicit
                      // onSurface text instead.
                      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 4)
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.touch_app_rounded,
                            size: 14, color: AppColors.secondary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            l10n.onboardingTapToPin(shopPin.latitude.toStringAsFixed(4), shopPin.longitude.toStringAsFixed(4)),
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Physical Street Address Input
        Text(
          l10n.onboardingShopAddress,
          style: Theme.of(context)
              .textTheme
              .labelMedium
              ?.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: addressController,
          maxLines: 2,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: l10n.onboardingAddressHint,
            prefixIcon: const Padding(
              padding: EdgeInsets.only(bottom: 24),
              child: Icon(Icons.place_rounded,
                  color: AppColors.secondary, size: 20),
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Theme.of(context).dividerColor)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Theme.of(context).dividerColor)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.secondary, width: 1.5)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }

  /// Audit §1: full-screen map — the inline 220px map cannot be
  /// panned inside the scrolling form, so tapping the expand icon
  /// opens this dialog where drags belong to the map. Taps move the
  /// pin (via [onPinChanged], which also recentres the inline map);
  /// Done closes the dialog.
  Future<void> _expandMap(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final dialogController = MapController();
    var pin = shopPin;
    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => Dialog(
          insetPadding: const EdgeInsets.all(12),
          child: SizedBox(
            height: MediaQuery.of(dialogContext).size.height * 0.75,
            child: Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(12)),
                    child: StatefulBuilder(
                      builder: (stateContext, setDialogState) => FlutterMap(
                        mapController: dialogController,
                        options: MapOptions(
                          initialCenter: pin,
                          initialZoom: 15.0,
                          onTap: (_, point) {
                            setDialogState(() => pin = point);
                            onPinChanged(point);
                          },
                        ),
                        children: [
                          const AppMapTileLayer(),
                          MarkerLayer(markers: [
                            Marker(
                              point: pin,
                              width: 44,
                              height: 44,
                              alignment: Alignment.bottomCenter,
                              child: const Icon(
                                Icons.location_on_rounded,
                                size: 40,
                                color: AppColors.secondary,
                              ),
                            ),
                          ]),
                          const AppOsmAttribution(alignment: Alignment.topLeft),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: Text(l10n.commonConfirm),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } finally {
      dialogController.dispose();
    }
  }
}
