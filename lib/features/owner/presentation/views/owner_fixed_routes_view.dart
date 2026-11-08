import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/current_shop.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../fleet/domain/entities/fixed_route_entity.dart';
import '../../../fleet/domain/usecases/delete_fixed_route_usecase.dart';
import '../../../fleet/domain/usecases/get_shop_fixed_routes_usecase.dart';
import '../../../fleet/domain/usecases/save_fixed_route_usecase.dart';
import '../widgets/fixed_route_form.dart';
import '../../../../core/utils/money_format.dart';

/// Phase B (B3): the shop's fixed out-of-city routes — one fixed price
/// per destination (Lahore → Islamabad, Murree, Karachi, …). Customers
/// see the enabled routes when they book an out-of-city trip.
/// Audit §8: destinations are free text (no hardcoded English city
/// list), the origin is not hardcoded (it starts empty; a shop-city
/// default needs a shop-profile read that is not wired here), deletes
/// confirm first, and load failures render a shared error state.
/// The O10b city-boundary / radius rules screen is deliberately NOT
/// built here — it is the tracked spec gap F-OWN-8.
class OwnerFixedRoutesView extends StatefulWidget {
  final String? shopId;
  final VoidCallback? onBack;

  const OwnerFixedRoutesView({super.key, this.shopId, this.onBack});

  @override
  State<OwnerFixedRoutesView> createState() => _OwnerFixedRoutesViewState();
}

class _OwnerFixedRoutesViewState extends State<OwnerFixedRoutesView> {
  List<FixedRouteEntity> _routes = [];
  bool _loading = true;
  String? _error;
  final _distanceController = TextEditingController(text: '300');
  final _priceController = TextEditingController();
  final _originController = TextEditingController();
  final _destinationController = TextEditingController();

  String get _shopId => widget.shopId ?? currentShopId();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _distanceController.dispose();
    _priceController.dispose();
    _originController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final routes = await sl<GetShopFixedRoutesUseCase>()(_shopId);
      if (!mounted) return;
      setState(() {
        _routes = routes;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _save(FixedRouteEntity route) async {
    try {
      await sl<SaveFixedRouteUseCase>()(route);
      await _load();
    } catch (e) {
      if (!mounted) return;
      AppFeedback.showError(context, e.toString());
    }
  }

  Future<void> _addRoute() async {
    final l10n = AppLocalizations.of(context)!;
    final origin = _originController.text.trim();
    final destination = _destinationController.text.trim();
    if (origin.isEmpty) {
      AppFeedback.showError(context, l10n.fixedRouteFromCity);
      return;
    }
    if (destination.isEmpty) {
      AppFeedback.showError(context, l10n.fixedRouteToCity);
      return;
    }
    // Audit §8: block an existing origin → destination pair.
    final duplicate = _routes.any((r) =>
        r.originCity.trim().toLowerCase() == origin.toLowerCase() &&
        r.destinationCity.trim().toLowerCase() == destination.toLowerCase());
    if (duplicate) {
      AppFeedback.showError(context, l10n.fixedRouteDuplicate);
      return;
    }
    final price = int.tryParse(_priceController.text.trim());
    if (price == null || price <= 0) {
      AppFeedback.showError(context, l10n.fixedRoutesPriceRequired);
      return;
    }
    final distance = int.tryParse(_distanceController.text.trim()) ?? 0;
    await _save(FixedRouteEntity(
      routeId: 'route-${DateTime.now().millisecondsSinceEpoch}',
      shopId: _shopId,
      originCity: origin,
      destinationCity: destination,
      distanceKm: distance,
      fixedPricePkr: price,
    ));
    _priceController.clear();
    _destinationController.clear();
  }

  /// Audit §8 (C10): deleting a route confirms first.
  Future<void> _deleteRoute(FixedRouteEntity route) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.fixedRoutesDeleteTooltip),
        content: Text(route.displayName),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(l10n.commonConfirm)),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await sl<DeleteFixedRouteUseCase>()(route.routeId);
      await _load();
    } catch (e) {
      if (!mounted) return;
      AppFeedback.showError(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        // C1: MinimalAppBar owns the top inset.
        top: false,
        child: Column(
          children: [
            MinimalAppBar(
              title: l10n.fixedRoutesTitle,
              subtitle: l10n.fixedRoutesSubtitle,
              onBack: widget.onBack ?? () => context.pop(),
            ),
            Expanded(
              child: _loading
                  ? const AppLoadingState()
                  : _error != null
                      ? AppErrorState(
                          // Audit §8: a localised message with retry,
                          // never the raw exception text.
                          message: l10n.fixedRoutesLoadError,
                          onRetry: _load,
                        )
                      : ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            // Audit §8: the form sits above the list so
                            // it is never below the fold.
                            FixedRouteForm(
                              originController: _originController,
                              destinationController: _destinationController,
                              distanceController: _distanceController,
                              priceController: _priceController,
                              onAdd: _addRoute,
                            ),
                            const SizedBox(height: 16),
                            ..._routes.map((r) => Card(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  child: ListTile(
                                    leading: const Icon(Icons.route_rounded),
                                    title: Text(r.displayName,
                                        style: const TextStyle(fontWeight: FontWeight.w800)),
                                    subtitle: Text(l10n.fixedRouteSummary(r.distanceKm, formatRs(r.fixedPricePkr))),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Switch(
                                          value: r.enabled,
                                          onChanged: (v) => _save(r.copyWith(enabled: v)),
                                        ),
                                        IconButton(
                                          tooltip: l10n.fixedRoutesDeleteTooltip,
                                          icon: Icon(Icons.delete_outline_rounded, color: AppColors.accentDanger),
                                          onPressed: () => _deleteRoute(r),
                                        ),
                                      ],
                                    ),
                                  ),
                                )),
                            if (_routes.isEmpty)
                              AppEmptyState(
                                title: l10n.fixedRoutesEmpty,
                                icon: Icons.route_rounded,
                              ),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
