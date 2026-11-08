import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
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
class CustomerVehicleRouteLoader extends StatelessWidget {
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
  ) builder;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<VehicleWithShop?>(
      future: _load(vehicleId, l10n),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final loaded = snapshot.data;
        if (loaded == null) {
          return RouteNotFoundScreen(
            message: l10n.vehicleNotFound(vehicleId),
          );
        }
        return builder(
          context,
          loaded.vehicle,
          loaded.shopName,
          loaded.shopPhone,
        );
      },
    );
  }

  static Future<VehicleWithShop?> _load(String vehicleId, AppLocalizations l10n) async {
    final vehicle =
        await sl<FleetRemoteDataSource>().getVehicleById(vehicleId);
    if (vehicle == null) return null;
    var shopName = l10n.rentalShowroom;
    var shopPhone = '';
    try {
      final doc = await FirebaseFirestore.instance
          .collection('shops')
          .doc(vehicle.shopId)
          .get();
      if (doc.exists && doc.data() != null) {
        final shop = ShopModel.fromMap(doc.data()!, id: doc.id);
        shopName = shop.shopName;
        shopPhone = shop.phoneNumber;
      }
    } catch (_) {}
    return VehicleWithShop(
      vehicle: vehicle,
      shopName: shopName,
      shopPhone: shopPhone,
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
  });

  final VehicleEntity vehicle;
  final String shopName;
  final String shopPhone;
}

/// Phase A (A1): the customer shop route. Loads the shop document from
/// `shops` by id.
class ShopRouteLoader extends StatelessWidget {
  const ShopRouteLoader({
    super.key,
    required this.shopId,
    required this.builder,
  });

  final String shopId;
  final Widget Function(BuildContext context, ShopEntity shop) builder;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<ShopEntity?>(
      future: _loadShop(shopId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final shop = snapshot.data;
        if (shop == null) {
          return RouteNotFoundScreen(
            message: l10n.shopNotFound(shopId),
          );
        }
        return builder(context, shop);
      },
    );
  }

  static Future<ShopEntity?> _loadShop(String shopId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('shops')
          .doc(shopId)
          .get();
      if (doc.exists && doc.data() != null) {
        return ShopModel.fromMap(doc.data()!, id: doc.id);
      }
    } catch (_) {}
    return null;
  }
}

