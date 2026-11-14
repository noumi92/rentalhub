import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../discovery/data/models/shop_model.dart';
import '../../../discovery/domain/entities/shop_entity.dart';
import '../../../fleet/data/datasources/fleet_remote_data_source.dart';
import '../../../fleet/domain/entities/vehicle_entity.dart';
import '../../../owner/presentation/widgets/owner_route_loaders.dart';
import '../../../../l10n/app_localizations.dart';

/// Phase A (A1): the customer vehicle route. The customer does not know
/// the shop up front, so the vehicle is fetched directly by id (see
/// [FleetRemoteDataSource.getVehicleById]) and the shop's name + phone are
/// read from the `shops` document, so the detail screen can show the
/// showroom and offer a real WhatsApp chat.
///
/// CU-M6: a load failure is NOT "not found". While waiting the shared
/// [AppLoadingState] shows; a failed load shows [AppErrorState] with
/// retry; only a confirmed absent document lands on
/// [RouteNotFoundScreen]. (An offline user tapping a shop used to be
/// told the shop does not exist, with no way back.)
class CustomerVehicleRouteLoader extends StatefulWidget {
  const CustomerVehicleRouteLoader({
    super.key,
    required this.vehicleId,
    required this.builder,
  });

  final String vehicleId;
  final Widget Function(
    BuildContext context,
    VehicleEntity vehicle,
    String shopName,
    String shopPhone,
    String shopOwnerId,
  ) builder;

  @override
  State<CustomerVehicleRouteLoader> createState() =>
      _CustomerVehicleRouteLoaderState();

  static Future<VehicleWithShop?> _load(String vehicleId, AppLocalizations? l10n) async {
    // F-M2 (admin audit 2026-11-14): a car the admin hid/rejected
    // is not openable from a deep link or saved car either.
    final vehicle =
        await sl<FleetRemoteDataSource>().getCustomerVehicleById(vehicleId);
    if (vehicle == null) return null;
    var shopName = l10n?.rentalShowroom ?? 'Rental Showroom';
    var shopPhone = '';
    var shopOwnerId = '';
    try {
      final doc = await FirebaseFirestore.instance
          .collection('shops')
          .doc(vehicle.shopId)
          .get();
      if (doc.exists && doc.data() != null) {
        final shop = ShopModel.fromMap(doc.data()!, id: doc.id);
        shopName = shop.shopName;
        shopPhone = shop.phoneNumber;
        shopOwnerId = shop.ownerId;
      }
    } catch (_) {}
    return VehicleWithShop(
      vehicle: vehicle,
      shopName: shopName,
      shopPhone: shopPhone,
      shopOwnerId: shopOwnerId,
    );
  }
}

class _CustomerVehicleRouteLoaderState
    extends State<CustomerVehicleRouteLoader> {
  late Future<VehicleWithShop?> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadFuture();
  }

  Future<VehicleWithShop?> _loadFuture() =>
      CustomerVehicleRouteLoader._load(
        widget.vehicleId,
        AppLocalizations.of(context),
      );

  void _retry() {
    setState(() {
      _future = _loadFuture();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FutureBuilder<VehicleWithShop?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: AppLoadingState(
              message: l10n?.requestsLoading ?? 'Loading vehicle…',
            ),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: AppErrorState(
              message:
                  l10n?.vehicleLoadFailed ?? 'Could not load this vehicle.',
              onRetry: _retry,
            ),
          );
        }
        final loaded = snapshot.data;
        if (loaded == null) {
          return RouteNotFoundScreen(
            message: l10n?.vehicleNotFound(widget.vehicleId) ??
                'Vehicle ${widget.vehicleId} was not found.',
          );
        }
        return widget.builder(
          context,
          loaded.vehicle,
          loaded.shopName,
          loaded.shopPhone,
          loaded.shopOwnerId,
        );
      },
    );
  }
}

/// A vehicle plus the showroom it belongs to, as loaded by
/// [CustomerVehicleRouteLoader].
class VehicleWithShop {
  const VehicleWithShop({
    required this.vehicle,
    required this.shopName,
    required this.shopPhone,
    required this.shopOwnerId,
  });

  final VehicleEntity vehicle;
  final String shopName;
  final String shopPhone;

  /// The shop document's `owner_id` ('' when the shop has none, e.g. the
  /// legacy record). The detail screen uses it to recognise the owner's
  /// own car: new cars carry the shop DOCUMENT id, not the owner UID.
  final String shopOwnerId;
}

/// Phase A (A1): the customer shop route. Loads the shop document from
/// `shops` by id. CU-M6: same failure contract as the vehicle loader —
/// error state with retry on a failed load, not-found only for a
/// confirmed absent document.
class ShopRouteLoader extends StatefulWidget {
  const ShopRouteLoader({
    super.key,
    required this.shopId,
    required this.builder,
  });

  final String shopId;
  final Widget Function(BuildContext context, ShopEntity shop) builder;

  @override
  State<ShopRouteLoader> createState() => _ShopRouteLoaderState();

  static Future<ShopEntity?> _loadShop(String shopId) async {
    FirebaseFirestore? fs;
    try {
      fs = FirebaseFirestore.instance;
    } catch (_) {
      // No Firebase app (widget tests): behave as before — no data
      // source, so the document is treated as absent.
      return null;
    }
    final doc = await fs.collection('shops').doc(shopId).get();
    if (doc.exists && doc.data() != null) {
      return ShopModel.fromMap(doc.data()!, id: doc.id);
    }
    return null;
  }
}

class _ShopRouteLoaderState extends State<ShopRouteLoader> {
  late Future<ShopEntity?> _future;

  @override
  void initState() {
    super.initState();
    _future = ShopRouteLoader._loadShop(widget.shopId);
  }

  void _retry() {
    setState(() {
      _future = ShopRouteLoader._loadShop(widget.shopId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FutureBuilder<ShopEntity?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: AppLoadingState(
              message: l10n?.requestsLoading ?? 'Loading showroom…',
            ),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: AppErrorState(
              message: l10n?.shopLoadFailed ?? 'Could not load this showroom.',
              onRetry: _retry,
            ),
          );
        }
        final shop = snapshot.data;
        if (shop == null) {
          return RouteNotFoundScreen(
            message: l10n?.shopNotFound(widget.shopId) ??
                'Showroom ${widget.shopId} was not found.',
          );
        }
        return widget.builder(context, shop);
      },
    );
  }
}
