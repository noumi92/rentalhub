import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../../core/widgets/verified_badge.dart';
import 'widgets/shop_detail_header.dart';
import 'widgets/shop_vehicle_card.dart';
import '../../../customer/data/datasources/customer_remote_data_source.dart';
import '../../../customer/domain/entities/customer_entity.dart';
import '../../../fleet/data/datasources/fleet_remote_data_source.dart';
import '../../../fleet/domain/entities/vehicle_entity.dart';
import '../../domain/entities/shop_entity.dart';
import '../../../../l10n/app_localizations.dart';

/// Phase A (A1): the shop detail screen now loads the shop's real fleet
/// from Firestore instead of the mock database. A shop with no cars shows
/// an honest empty state instead of every mock car in the app.
class ShopDetailView extends StatefulWidget {
  final ShopEntity shop;
  final ValueChanged<VehicleEntity>? onVehicleSelected;
  final VoidCallback? onViewAllCars;
  final VoidCallback? onBack;

  const ShopDetailView({
    super.key,
    required this.shop,
    this.onVehicleSelected,
    this.onViewAllCars,
    this.onBack,
  });

  @override
  State<ShopDetailView> createState() => _ShopDetailViewState();
}

class _ShopDetailViewState extends State<ShopDetailView> {
  List<VehicleEntity>? _vehicles;
  bool _loading = true;
  // E2: a load failure used to throw out of [_loadVehicles] unhandled;
  // it now renders an error state with retry.
  bool _hasError = false;

  // H5: whether this showroom is saved by the signed-in customer.
  CustomerEntity? _customer;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final customer =
          await sl<CustomerRemoteDataSource>().getCustomerById(uid);
      if (mounted && customer != null) {
        setState(() {
          _customer = customer;
          _saved = customer.savedShopIds.contains(widget.shop.shopId);
        });
      }
    } catch (_) {}
  }

  Future<void> _toggleSaved() async {
    final l10n = AppLocalizations.of(context)!;
    final customer = _customer;
    if (customer == null) {
      AppFeedback.showInfo(context, l10n.shopSaveSignIn);
      return;
    }
    final ids = List<String>.from(customer.savedShopIds);
    final nowSaved = !ids.contains(widget.shop.shopId);
    if (nowSaved) {
      ids.add(widget.shop.shopId);
    } else {
      ids.remove(widget.shop.shopId);
    }
    final updated = customer.copyWith(savedShopIds: ids);
    setState(() {
      _customer = updated;
      _saved = nowSaved;
    });
    try {
      await sl<CustomerRemoteDataSource>().upsertCustomer(updated);
    } catch (_) {
      if (mounted) {
        setState(() {
          _customer = customer;
          _saved = !nowSaved;
        });
        AppFeedback.showError(context, l10n.shopSaveError);
      }
    }
  }

  Future<void> _loadVehicles() async {
    if (mounted) setState(() => _hasError = false);
    try {
      final list = await sl<FleetRemoteDataSource>()
          .getCustomerShopVehicles(widget.shop.shopId);
      if (mounted) {
        setState(() {
          _vehicles = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _loading = false;
        });
      }
    }
  }

  /// Customer pass (2026-11-16): pull-to-refresh reloads the fleet
  /// and the saved state together.
  Future<void> _reload() async =>
      Future.wait([_loadVehicles(), _loadSaved()]);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final shop = widget.shop;
    final vehicles = _vehicles ?? const <VehicleEntity>[];

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _reload,
          child: SingleChildScrollView(
            // AlwaysScrollable: pull-to-refresh must work even when
            // the fleet is shorter than the viewport.
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MinimalAppBar(
                title: shop.shopName,
                subtitle: [
                  shop.address,
                  if (shop.city.isNotEmpty) shop.city,
                  // Admin-integration audit (2026-11-10): the
                  // distance is shown only when real — never the
                  // 1.2 km display-only fallback.
                  if (shop.hasRealDistance)
                    '(${shop.distanceKm.toStringAsFixed(1)} km)',
                ].join(', '),
                onBack: widget.onBack,
                actions: [
                  IconButton(
                    icon: Icon(
                      _saved
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: AppColors.surfaceLight,
                      size: 22,
                    ),
                    tooltip: _saved ? l10n.shopSaved : l10n.shopSave,
                    onPressed: _toggleSaved,
                  ),
                ],
              ),
              // PW-7 (UI/UX audit 2026-11-15): the real photo (when
              // one exists), the real rating, and Call / WhatsApp —
              // the trust signals the list card has but the detail
              // screen lost.
              ShopDetailHeader(shop: shop),
              Padding(
                // Directional padding: the badge aligns with the
                // 16dp content padding in both LTR and RTL (Urdu);
                // the old left: 20 was asymmetric and RTL-wrong.
                padding: const EdgeInsetsDirectional.only(start: 16, top: 12),
                child: VerifiedBadge(isVerified: shop.isVerified),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_loading)
                      
                       AppLoadingState(
                        message: l10n.shopLoadingCars,
                      )
                    else if (_hasError)
                      AppErrorState(
                        message:
                            l10n.shopCarsLoadError,
                        onRetry: _loadVehicles,
                      )
                    else if (vehicles.isEmpty)
                       AppEmptyState(
                        title: l10n.shopNoCars,
                        message:
                            l10n.shopCheckLater,
                        icon: Icons.directions_car_outlined,
                      )
                    else ...[
                      ...vehicles.map(
                        (vehicle) => ShopVehicleCard(
                          vehicle: vehicle,
                          onTap: () =>
                              widget.onVehicleSelected?.call(vehicle),
                        ),
                      ),
                      if (widget.onViewAllCars != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Center(
                            child: TextButton.icon(
                              onPressed: widget.onViewAllCars,
                              style: TextButton.styleFrom(
                                // 48dp minimum touch target.
                                minimumSize: const Size(0, 48),
                              ),
                              icon: const Icon(
                                Icons.directions_car_rounded,
                                size: 18,
                              ),
                              label: Text(
                                l10n.shopViewAllCars,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}
