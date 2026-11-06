import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/custom_curved_header.dart';
import '../../data/datasources/customer_location_store.dart';
import 'widgets/city_selector_bar.dart';
import 'widgets/location_confirm_card.dart';

class CustomerLocationPromptView extends StatefulWidget {
  const CustomerLocationPromptView({super.key});

  @override
  State<CustomerLocationPromptView> createState() => _CustomerLocationPromptViewState();
}

class _CustomerLocationPromptViewState extends State<CustomerLocationPromptView> {
  final MapController _mapController = MapController();

  final List<Map<String, dynamic>> _majorCities = [
    {'name': 'Lahore', 'lat': 31.5204, 'lng': 74.3587, 'area': 'Gulberg III, Lahore'},
    {'name': 'Karachi', 'lat': 24.8607, 'lng': 67.0011, 'area': 'Clifton / DHA, Karachi'},
    {'name': 'Islamabad', 'lat': 33.6844, 'lng': 73.0479, 'area': 'Blue Area, Islamabad'},
    {'name': 'Rawalpindi', 'lat': 33.5651, 'lng': 73.0169, 'area': 'Saddar Cantt, Rawalpindi'},
    {'name': 'Faisalabad', 'lat': 31.4504, 'lng': 73.1350, 'area': 'D Ground, Faisalabad'},
    {'name': 'Multan', 'lat': 30.1575, 'lng': 71.5249, 'area': 'Cantonment, Multan'},
    {'name': 'Peshawar', 'lat': 34.0151, 'lng': 71.5249, 'area': 'University Town, Peshawar'},
  ];

  late String _selectedCity;
  late LatLng _currentCenter;
  late String _addressLabel;
  bool _isLocating = false;
  // B1: true only while the centre is the live GPS fix — a city pick or
  // a manual map drag makes it a chosen location, not a GPS one.
  bool _fromGps = false;

  @override
  void initState() {
    super.initState();
    final initial = _majorCities.first;
    _selectedCity = initial['name'] as String;
    _currentCenter = LatLng(initial['lat'] as double, initial['lng'] as double);
    _addressLabel = initial['area'] as String;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchCurrentGpsLocation(silent: true);
    });
  }

  Future<void> _fetchCurrentGpsLocation({bool silent = false}) async {
    setState(() => _isLocating = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!silent && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enable GPS / Location Services on your device.'), backgroundColor: AppColors.warning),
          );
        }
        setState(() => _isLocating = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!silent && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permission denied. Tap a city to explore.'), backgroundColor: AppColors.error),
            );
          }
          setState(() => _isLocating = false);
          return;
        }
      }

      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
        );
        final userLatLng = LatLng(position.latitude, position.longitude);

        setState(() {
          _currentCenter = userLatLng;
          _selectedCity = 'My Live Location';
          _addressLabel = '${userLatLng.latitude.toStringAsFixed(4)}°N, ${userLatLng.longitude.toStringAsFixed(4)}°E';
          _fromGps = true;
        });

        _mapController.move(userLatLng, 14.5);
      }
    } catch (e) {
      debugPrint('Error getting GPS: $e');
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  void _selectCity(Map<String, dynamic> city) {
    final lat = city['lat'] as double;
    final lng = city['lng'] as double;
    final target = LatLng(lat, lng);

    setState(() {
      _selectedCity = city['name'] as String;
      _addressLabel = city['area'] as String;
      _currentCenter = target;
      _fromGps = false;
    });

    _mapController.move(target, 13.5);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            CustomCurvedHeader(
              height: 56,
              leadingWidget: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go(RouteNames.onboardingRole);
                  }
                },
              ),
              titleWidget: const Text(
                'Set Rental Location',
                style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800),
              ),
            ),
            CitySelectorBar(
              majorCities: _majorCities,
              selectedCity: _selectedCity,
              onSelectCity: _selectCity,
            ),
            Expanded(
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _currentCenter,
                      initialZoom: 13.5,
                      minZoom: 4.0,
                      maxZoom: 18.0,
                      onPositionChanged: (camera, hasGesture) {
                        if (hasGesture) {
                          setState(() {
                            _currentCenter = camera.center;
                            _addressLabel = '${_currentCenter.latitude.toStringAsFixed(4)}°N, ${_currentCenter.longitude.toStringAsFixed(4)}°E';
                            _fromGps = false;
                          });
                        }
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'pk.rentalhub.rentalhub',
                      ),
                    ],
                  ),
                  IgnorePointer(
                    child: Center(
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.sunsetOrange.withValues(alpha: 0.10),
                          border: Border.all(color: AppColors.sunsetOrange.withValues(alpha: 0.45), width: 1.5),
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: FractionalTranslation(
                      translation: const Offset(0.0, -0.5),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: AppColors.midnightNavy, borderRadius: BorderRadius.circular(12)),
                            child: const Text('Center Location Pin', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                          ),
                          const SizedBox(height: 2),
                          const Icon(Icons.location_on_rounded, size: 46, color: AppColors.sunsetOrange),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 14,
                    right: 14,
                    child: FloatingActionButton.small(
                      heroTag: 'gps_map_fetch_btn',
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.sunsetOrange,
                      elevation: 4,
                      onPressed: _isLocating ? null : () => _fetchCurrentGpsLocation(silent: false),
                      child: _isLocating
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(AppColors.sunsetOrange)))
                          : const Icon(Icons.my_location_rounded, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            LocationConfirmCard(
              selectedCity: _selectedCity,
              addressLabel: _addressLabel,
              onConfirm: () async {
                await CustomerLocationStore().save(
                  CustomerLocation(
                    latitude: _currentCenter.latitude,
                    longitude: _currentCenter.longitude,
                    city: _selectedCity,
                    area: _addressLabel,
                    fromGps: _fromGps,
                  ),
                );
                if (context.mounted) {
                  context.go(RouteNames.customerHome);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
