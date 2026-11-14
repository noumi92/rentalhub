import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/di/injection_container.dart';
import '../../../../../core/network/connectivity_service.dart';
import '../../../../../core/network/firestore_service.dart';
import '../../../../../l10n/app_localizations.dart';

/// 010b boundary map header card (deck p.4): the shop inside its
/// dashed home-city radius circle.
///
/// Self-contained: it loads the shop's coordinates itself and shows
/// the REAL map only when coordinates exist AND the device is online.
/// Otherwise it shows the deck-style fallback illustration (dashed
/// circle + house icon + city/radius text) — never a broken map,
/// never a blank card, never a crash without network/Firestore.
///
/// The circle follows [radiusKm] on every build: the radius is read
/// from the widget field (never cached in state), and the [FlutterMap]
/// carries a radius key so a boundary edit refits the camera.
/// Coordinates ARE cached in state (one Firestore read per card),
/// but only the coordinates — city/radius always come from the
/// constructor, so the card updates the moment the parent edits the
/// boundary.
class BoundaryMapCard extends StatefulWidget {
  const BoundaryMapCard({
    super.key,
    required this.shopId,
    required this.homeCity,
    required this.radiusKm,
    this.initialCenter,
    this.locationLoader,
    this.isOnlineOverride,
    this.height = 180,
    this.onEdit,
  });

  /// Shop document id (`shops/{shopId}`; the owner's uid). The
  /// document's `latitude`/`longitude` fields are the shop pin.
  final String shopId;

  /// Home-city label, e.g. 'Lahore'. Shown on the card as text.
  final String homeCity;

  /// Boundary radius in km. Drives the circle AND the label text.
  final int radiusKm;

  /// Test seam: inject coordinates and skip the Firestore load.
  final ll.LatLng? initialCenter;

  /// Test seam: override the shop-location fetch entirely.
  final Future<ll.LatLng?> Function(String shopId)? locationLoader;

  /// Test seam: force the online/offline decision.
  final bool? isOnlineOverride;

  /// Card height (the deck header is ~180 px).
  final double height;

  /// Optional edit action: when provided, an Edit button appears in
  /// the label chip (the 010b screen passes its boundary editor, so
  /// the map card IS the boundary section — the text is shown once,
  /// here, not repeated in a separate row below).
  final VoidCallback? onEdit;

  @override
  State<BoundaryMapCard> createState() => _BoundaryMapCardState();
}

class _BoundaryMapCardState extends State<BoundaryMapCard> {
  ll.LatLng? _center;
  bool _loaded = false;
  bool _online = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialCenter != null) {
      // Test seam: coordinates injected, nothing to load.
      _center = widget.initialCenter;
      _online = widget.isOnlineOverride ?? true;
      _loaded = true;
    } else {
      _load();
    }
  }

  Future<void> _load() async {
    var online = true;
    ll.LatLng? center;
    try {
      if (widget.isOnlineOverride != null) {
        online = widget.isOnlineOverride!;
      } else {
        try {
          final connectivity = sl<ConnectivityService>();
          await connectivity.start();
          online = connectivity.isOnline;
        } catch (_) {
          // No connectivity service (or no platform plugin): assume
          // online, like the service itself degrades — a failed tile
          // load still leaves the card usable, never blank.
          online = true;
        }
      }
      if (widget.locationLoader != null) {
        center = await widget.locationLoader!(widget.shopId);
      } else {
        center = await _loadShopCenter(widget.shopId);
      }
    } catch (_) {
      center = null;
    }
    if (!mounted) return;
    setState(() {
      _online = online;
      _center = center;
      _loaded = true;
    });
  }

  /// Reads the raw shop document and returns its pin, or null when
  /// the shop has no location set. The raw document (not getShop) is
  /// deliberate: ShopModel.fromMap defaults missing lat/lng to
  /// Lahore, so it cannot tell "not set" from "set to Lahore".
  static Future<ll.LatLng?> _loadShopCenter(String shopId) async {
    try {
      final data = await sl<FirestoreService>().getDocument('shops', shopId);
      if (data == null) return null;
      final lat = (data['latitude'] as num?)?.toDouble();
      final lng = (data['longitude'] as num?)?.toDouble();
      if (lat == null || lng == null || lat.isNaN || lng.isNaN) return null;
      if (lat < -90 || lat > 90 || lng < -180 || lng > 180) return null;
      return ll.LatLng(lat, lng);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final label = '${widget.homeCity} · ${widget.radiusKm} km';
    final showMap = _loaded && _online && _center != null;
    // Before the load finishes there is no note yet — the
    // illustration holds the space so the card is never blank.
    final String? note = !_loaded
        ? null
        : !_online
            ? l10n.outCityMapOffline
            : _center == null
                ? l10n.outCityMapNoLocation
                : null;
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (showMap) _buildMap(_center!) else _buildIllustration(theme),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(label,
                              style: theme.textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600)),
                        ),
                        if (widget.onEdit != null)
                          TextButton.icon(
                            onPressed: widget.onEdit,
                            icon: const Icon(Icons.edit_rounded, size: 18),
                            label: Text(l10n.vehicleDetailEdit),
                          ),
                      ],
                    ),
                    if (note != null) ...[
                      const SizedBox(height: 2),
                      Text(note, style: theme.textTheme.labelSmall),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Real map, fitted so the WHOLE circle is visible in the card:
  /// CameraFit.bounds on the circle's bounds (centre ± radius).
  /// Verified arithmetic: a 40 km radius is an 80 km span; at
  /// Lahore's latitude (~31.5°) that is ~zoom 9 on a ~330 px-wide
  /// card, well inside the 3–18 range. The radius key rebuilds the
  /// map (and refits) whenever the boundary is edited — the fit is
  /// only applied on first build, so a key change is required.
  /// Non-interactive: a header illustration, not a navigation map.
  /// No geolocator, no permission prompts.
  Widget _buildMap(ll.LatLng center) {
    final radiusM = widget.radiusKm * 1000.0;
    const distance = ll.Distance();
    final north = distance.offset(center, radiusM, 0);
    final south = distance.offset(center, radiusM, 180);
    final east = distance.offset(center, radiusM, 90);
    final west = distance.offset(center, radiusM, 270);
    final bounds = LatLngBounds(
      ll.LatLng(south.latitude, west.longitude),
      ll.LatLng(north.latitude, east.longitude),
    );
    return FlutterMap(
      key: ValueKey('boundary-map-${widget.radiusKm}'),
      options: MapOptions(
        initialCenter: center,
        initialZoom: 10,
        minZoom: 3,
        maxZoom: 18,
        interactionOptions:
            const InteractionOptions(flags: InteractiveFlag.none),
        initialCameraFit: CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(16),
          maxZoom: 13,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'pk.rentalhub.rentalhub',
        ),
        CircleLayer(
          circles: [
            CircleMarker(
              point: center,
              radius: radiusM,
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
              point: center,
              width: 36,
              height: 36,
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
                  Icons.home_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Deck-style fallback: dashed circle + house icon, on a tinted
  /// surface. Used offline, with no shop location, and while the
  /// coordinates are still loading.
  Widget _buildIllustration(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(painter: _DashedCirclePainter(theme)),
          Center(
            child: Container(
              padding: const EdgeInsets.all(10),
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
                Icons.home_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dashed circle (deck 010b: house inside a dashed 40 km radius
/// circle), drawn as arc segments so it needs no image asset.
class _DashedCirclePainter extends CustomPainter {
  _DashedCirclePainter(this.theme);

  final ThemeData theme;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.secondary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 10;
    const dash = 8.0;
    const gap = 6.0;
    final circumference = 2 * math.pi * radius;
    var drawn = 0.0;
    while (drawn < circumference) {
      final sweep = math.min(dash, circumference - drawn) / radius;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        drawn / radius - math.pi / 2,
        sweep,
        false,
        paint,
      );
      drawn += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
