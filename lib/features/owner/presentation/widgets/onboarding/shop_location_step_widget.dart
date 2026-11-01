import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import '../../../../../core/constants/app_colors.dart';

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Your City',
          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.midnightNavy),
        ),
        const SizedBox(height: 6),
        // Requirement 4: Single horizontal row for major cities BEFORE map view
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: majorCities.map((city) {
              final isSelected = selectedCity == city['name'];
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(city['name'] as String),
                  selected: isSelected,
                  selectedColor: AppColors.sunsetOrange,
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.midnightNavy,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                  onSelected: (_) {
                    onCityChanged(city['name'] as String);
                    final coords = city['coords'] as ll.LatLng;
                    onPinChanged(coords);
                    mapController.move(coords, 13.0);
                  },
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 14),

        // Interactive Map with Pin Placement (Requirement 5: Map is connected)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Pin Showroom On Map',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.midnightNavy),
            ),
            TextButton.icon(
              onPressed: isLocating ? null : onFetchGps,
              icon: isLocating
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.my_location_rounded, size: 16, color: AppColors.sunsetOrange),
              label: Text(
                isLocating ? 'Locating...' : 'Use Current GPS',
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.sunsetOrange),
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
              border: Border.all(color: AppColors.border),
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
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.rentalhub.pk',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: shopPin,
                          width: 44,
                          height: 44,
                          child: const Icon(
                            Icons.location_on_rounded,
                            size: 40,
                            color: AppColors.sunsetOrange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Positioned(
                  bottom: 8,
                  left: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.touch_app_rounded, size: 14, color: AppColors.sunsetOrange),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Tap anywhere on map to pin showroom (${shopPin.latitude.toStringAsFixed(4)}, ${shopPin.longitude.toStringAsFixed(4)})',
                            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.midnightNavy),
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
        const Text(
          'Physical Showroom Address',
          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.midnightNavy),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: addressController,
          maxLines: 2,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
          decoration: InputDecoration(
            hintText: 'Shop number, plaza, street, sector / commercial area',
            prefixIcon: const Padding(
              padding: EdgeInsets.only(bottom: 24),
              child: Icon(Icons.place_rounded, color: AppColors.sunsetOrange, size: 20),
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.sunsetOrange, width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }
}

