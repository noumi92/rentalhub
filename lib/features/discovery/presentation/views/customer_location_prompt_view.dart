import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/app_map_tile_layer.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/datasources/customer_location_store.dart';
import 'widgets/city_selector_bar.dart';
import 'widgets/location_center_pin.dart';
import 'widgets/location_confirm_card.dart';
import 'widgets/map_gps_helper.dart';
import 'widgets/shops_tab_data.dart';

class CustomerLocationPromptView extends StatefulWidget {
  const CustomerLocationPromptView({super.key});

  @override
  State<CustomerLocationPromptView> createState() =>
      _CustomerLocationPromptViewState();
}

class _CustomerLocationPromptViewState
    extends State<CustomerLocationPromptView> {
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
  bool _fromGps = false;
  bool _online = true;

  @override
  void initState() {
    super.initState();
    final initial = _majorCities.first;
    _selectedCity = initial['name'] as String;
    _currentCenter =
        LatLng(initial['lat'] as double, initial['lng'] as double);
    _addressLabel = initial['area'] as String;
    _checkOnline();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fetchCurrentGpsLocation(silent: true);
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _checkOnline() async {
    final online = await ShopsTabData.onlineStatus();
    if (mounted) setState(() => _online = online);
  }

  Future<void> _fetchCurrentGpsLocation({bool silent = false}) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isLocating = true);
    final res = await fetchCustomerGpsPoint(context, silent: silent);
    if (!mounted) return;
    setState(() => _isLocating = false);
    if (res == null) return;
    final pt = res.point;
    setState(() {
      _currentCenter = pt;
      _selectedCity = res.nearestCity ?? l10n.homeMyLiveLocation;
      _addressLabel =
          '${pt.latitude.toStringAsFixed(4)}°N, ${pt.longitude.toStringAsFixed(4)}°E';
      _fromGps = true;
    });
    _mapController.move(pt, 14.5);
  }

  void _selectCity(Map<String, dynamic> city) {
    final target = LatLng(city['lat'] as double, city['lng'] as double);
    setState(() {
      _selectedCity = city['name'] as String;
      _addressLabel = city['area'] as String;
      _currentCenter = target;
      _fromGps = false;
    });
    if (_online) _mapController.move(target, 13.5);
  }

  void _onPinDrag(DragUpdateDetails details) {
    if (!_online) return;
    final camera = _mapController.camera;
    final next = camera.screenOffsetToLatLng(
      camera.latLngToScreenOffset(_currentCenter) + details.delta,
    );
    final nearest =
        ShopsTabData.nearestKnownCity(next.latitude, next.longitude);
    setState(() {
      _currentCenter = next;
      if (nearest != null) _selectedCity = nearest;
      _addressLabel =
          '${next.latitude.toStringAsFixed(4)}°N, ${next.longitude.toStringAsFixed(4)}°E';
      _fromGps = false;
    });
    _mapController.move(next, camera.zoom);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            MinimalAppBar(
              title: l10n.locationSetTitle,
              onBack: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(RouteNames.onboardingRole);
                }
              },
            ),
            CitySelectorBar(
              majorCities: _majorCities,
              selectedCity: _selectedCity,
              onSelectCity: _selectCity,
            ),
            Expanded(
              child: !_online
                  ? const MapOfflinePlaceholder()
                  : Stack(
                      children: [
                        FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: _currentCenter,
                            initialZoom: 13.5,
                            minZoom: 4.0,
                            maxZoom: 18.0,
                            onPositionChanged: (camera, hasGesture) {
                              if (!hasGesture) return;
                              final nearest = ShopsTabData.nearestKnownCity(
                                camera.center.latitude,
                                camera.center.longitude,
                              );
                              setState(() {
                                _currentCenter = camera.center;
                                if (nearest != null) _selectedCity = nearest;
                                _addressLabel =
                                    '${_currentCenter.latitude.toStringAsFixed(4)}°N, ${_currentCenter.longitude.toStringAsFixed(4)}°E';
                                _fromGps = false;
                              });
                            },
                          ),
                          children: const [
                            AppMapTileLayer(),
                            AppOsmAttribution(alignment: Alignment.topLeft),
                          ],
                        ),
                        LocationCenterPin(
                          label: l10n.locationCenterPin,
                          onDrag: _onPinDrag,
                        ),
                        Positioned(
                          top: 14,
                          right: 14,
                          child: MapGpsFab(
                            heroTag: 'gps_map_fetch_btn',
                            locating: _isLocating,
                            icon: Icons.my_location_rounded,
                            onPressed: () =>
                                _fetchCurrentGpsLocation(silent: false),
                          ),
                        ),
                      ],
                    ),
            ),
            LocationConfirmCard(
              selectedCity: _selectedCity,
              addressLabel: _addressLabel,
              onConfirm: () async {
                final resolvedCity = ShopsTabData.isKnownCity(_selectedCity)
                    ? _selectedCity
                    : (ShopsTabData.nearestKnownCity(_currentCenter.latitude,
                            _currentCenter.longitude) ??
                        _selectedCity);
                await CustomerLocationStore().save(
                  CustomerLocation(
                    latitude: _currentCenter.latitude,
                    longitude: _currentCenter.longitude,
                    city: resolvedCity,
                    area: _addressLabel,
                    fromGps: _fromGps,
                  ),
                );
                if (context.mounted) context.go(RouteNames.customerHome);
              },
            ),
          ],
        ),
      ),
    );
  }
}
