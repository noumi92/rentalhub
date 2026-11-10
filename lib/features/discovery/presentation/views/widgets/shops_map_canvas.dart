import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../../../../../core/constants/app_colors.dart';
import '../../../domain/entities/shop_entity.dart';
import '../../../../../l10n/app_localizations.dart';
import 'shops_filter_logic.dart';

/// The Shops tab map canvas: one OpenStreetMap canvas, no API key,
/// initial viewport the whole of Pakistan. Pins only for shops with a
/// real stored location ([ShopEntity.hasRealLocation]) — shops without
/// one appear in the list, never at an invented coordinate. Verified
/// pins are orange, unverified pins amber, and every pin carries its
/// verification status as text — a shop's status must be readable on
/// the map, not only on the list card.
///
/// The "you are here" pin is DRAGGABLE: dragging it calls
/// [onUserPointChanged] live (the map re-sorts nearby shops from the
/// new point) and [onUserPointChangeEnd] once on release. Shop pins
/// stay FIXED — they are tap-only and never move.
///
/// The drag wins the gesture arena with an [EagerGestureRecognizer]:
/// flutter_map's own scale recogniser is an ancestor of the markers
/// and claims a plain pan first, so a [GestureDetector] on the pin
/// never sees the drag. The eager recogniser claims on pointer down,
/// the map never pans, and a [Listener] tracks the raw moves.
/// Offline the canvas says so honestly instead of broken tiles.
class ShopsMapCanvas extends StatefulWidget {
  const ShopsMapCanvas({
    super.key,
    required this.mapController,
    required this.shops,
    required this.isOnline,
    required this.onShopSelected,
    this.initialCenter = pakistanCenter,
    this.initialZoom = pakistanZoom,
    this.userPoint,
    this.onUserPointChanged,
    this.onUserPointChangeEnd,
  });

  /// Whole-Pakistan viewport: bounds roughly lat 23.5–37.5,
  /// lng 61–75.5, centre (30.5, 68.25).
  static const pakistanCenter = ll.LatLng(30.5, 68.25);
  static const pakistanZoom = 5.0;

  final MapController mapController;

  /// Already city/verification-filtered shops; only the ones with a
  /// real stored location get a pin.
  final List<ShopEntity> shops;
  final bool isOnline;
  final ValueChanged<ShopEntity> onShopSelected;
  final ll.LatLng initialCenter;
  final double initialZoom;

  /// The draggable "you are here" pin, or null for no pin.
  final ll.LatLng? userPoint;

  /// Live position while the user pin is dragged.
  final ValueChanged<ll.LatLng>? onUserPointChanged;

  /// Once, when the user pin drag ends.
  final ValueChanged<ll.LatLng>? onUserPointChangeEnd;

  @override
  State<ShopsMapCanvas> createState() => _ShopsMapCanvasState();
}

class _ShopsMapCanvasState extends State<ShopsMapCanvas> {
  bool _draggingPin = false;

  /// The pin's live position mid-drag, so successive moves
  /// accumulate even before the parent rebuilds with the new point.
  ll.LatLng? _dragPoint;

  void _endDrag() {
    if (!_draggingPin) return;
    final point = _dragPoint ?? widget.userPoint;
    setState(() {
      _draggingPin = false;
      _dragPoint = null;
    });
    if (point != null) widget.onUserPointChangeEnd?.call(point);
  }

  /// The dragged point for a finger move: the pin's current screen
  /// offset plus the move delta, back to coordinates. Delta-based,
  /// so no RenderBox/GlobalKey is needed.
  ll.LatLng _draggedPoint(Offset delta) {
    final camera = widget.mapController.camera;
    final current = _dragPoint ?? widget.userPoint!;
    return camera.screenOffsetToLatLng(
      camera.latLngToScreenOffset(current) + delta,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (!widget.isOnline) {
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
    final pinnable =
        widget.shops.where((s) => s.hasRealLocation).toList();
    final userPoint = _dragPoint ?? widget.userPoint;
    return FlutterMap(
      mapController: widget.mapController,
      options: MapOptions(
        initialCenter: widget.initialCenter,
        initialZoom: widget.initialZoom,
        minZoom: 4.0,
        maxZoom: 18.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'pk.rentalhub.rentalhub',
        ),
        MarkerLayer(
          markers: [
            if (userPoint != null)
              Marker(
                point: userPoint,
                width: 38,
                height: 38,
                child: Semantics(
                  button: true,
                  label: l10n.homeMyLiveLocation,
                  child: RawGestureDetector(
                    gestures: <Type, GestureRecognizerFactory>{
                      EagerGestureRecognizer:
                          GestureRecognizerFactoryWithHandlers<
                              EagerGestureRecognizer>(
                        () => EagerGestureRecognizer(),
                        (EagerGestureRecognizer instance) {},
                      ),
                    },
                    child: Listener(
                      onPointerDown: (_) {
                        if (widget.onUserPointChanged == null) return;
                        _draggingPin = true;
                      },
                      onPointerMove: (event) {
                        if (!_draggingPin) return;
                        final next = _draggedPoint(event.delta);
                        setState(() => _dragPoint = next);
                        widget.onUserPointChanged!(next);
                      },
                      onPointerUp: (_) => _endDrag(),
                      onPointerCancel: (_) => _endDrag(),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                          border:
                              Border.all(color: Colors.white, width: 2),
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
                  ),
                ),
              ),
            ...pinnable.map((shop) {
              final verified = isShopVerified(shop);
              final pos = ll.LatLng(
                shop.geoLocation.latitude,
                shop.geoLocation.longitude,
              );
              return Marker(
                point: pos,
                width: 140,
                height: 76,
                alignment: Alignment.bottomCenter,
                child: Semantics(
                  button: true,
                  label: l10n.mapShowShop(shop.shopName),
                  child: GestureDetector(
                    onTap: () => widget.onShopSelected(shop),
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
                              color: verified
                                  ? AppColors.secondary
                                  : AppColors.warning,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  shop.shopName,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white),
                                ),
                                Text(
                                  verified
                                      ? l10n.verified
                                      : l10n.shops_unverified,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.location_on_rounded,
                            size: 28,
                            color: verified
                                ? AppColors.secondary
                                : AppColors.warning,
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
