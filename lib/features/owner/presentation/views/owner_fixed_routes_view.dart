import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/current_shop.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/custom_curved_header.dart';
import '../../../fleet/domain/entities/fixed_route_entity.dart';
import '../../../fleet/domain/usecases/delete_fixed_route_usecase.dart';
import '../../../fleet/domain/usecases/get_shop_fixed_routes_usecase.dart';
import '../../../fleet/domain/usecases/save_fixed_route_usecase.dart';
import '../widgets/fixed_route_form.dart';

/// Phase B (B3): the shop's fixed out-of-city routes — one fixed price
/// per destination (Lahore → Islamabad, Murree, Karachi, …). Customers
/// see the enabled routes when they book an out-of-city trip.
class OwnerFixedRoutesView extends StatefulWidget {
  final String? shopId;
  final VoidCallback? onBack;

  const OwnerFixedRoutesView({super.key, this.shopId, this.onBack});

  @override
  State<OwnerFixedRoutesView> createState() => _OwnerFixedRoutesViewState();
}

class _OwnerFixedRoutesViewState extends State<OwnerFixedRoutesView> {
  static const _destinations = [
    'Islamabad',
    'Rawalpindi',
    'Murree',
    'Faisalabad',
    'Multan',
    'Karachi',
  ];

  List<FixedRouteEntity> _routes = [];
  bool _loading = true;
  String? _error;
  String _destination = 'Islamabad';
  final _distanceController = TextEditingController(text: '300');
  final _priceController = TextEditingController();
  late final TextEditingController _originController;

  String get _shopId => widget.shopId ?? currentShopId();

  @override
  void initState() {
    super.initState();
    _originController = TextEditingController(text: 'Lahore');
    _load();
  }

  @override
  void dispose() {
    _distanceController.dispose();
    _priceController.dispose();
    _originController.dispose();
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
    final price = int.tryParse(_priceController.text.trim());
    if (price == null || price <= 0) {
      AppFeedback.showError(context, 'Enter a fixed price above zero.');
      return;
    }
    final distance = int.tryParse(_distanceController.text.trim()) ?? 0;
    await _save(FixedRouteEntity(
      routeId: 'route-${DateTime.now().millisecondsSinceEpoch}',
      shopId: _shopId,
      originCity: _originController.text.trim(),
      destinationCity: _destination,
      distanceKm: distance,
      fixedPricePkr: price,
    ));
    _priceController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            CustomCurvedHeader(
              height: 100,
              leadingWidget: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 20),
                onPressed: widget.onBack ?? () => context.pop(),
              ),
              titleWidget: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Fixed Out-of-City Routes',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900)),
                  Text('One fixed price per destination',
                      style: TextStyle(
                          color: AppColors.textLavender, fontSize: 12)),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text(_error!))
                      : ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            ..._routes.map((r) => Card(
                                  margin:
                                      const EdgeInsets.only(bottom: 10),
                                  child: ListTile(
                                    leading: const Icon(
                                        Icons.route_rounded,
                                        color: AppColors.royalNavy),
                                    title: Text(r.displayName,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w800)),
                                    subtitle: Text(
                                        '${r.distanceKm} km • Rs. ${r.fixedPricePkr} fixed'),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Switch(
                                          value: r.enabled,
                                          onChanged: (v) => _save(
                                              r.copyWith(enabled: v)),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                              Icons.delete_outline_rounded,
                                              color: Colors.redAccent),
                                          onPressed: () async {
                                            await sl<
                                                    DeleteFixedRouteUseCase>()(
                                                r.routeId);
                                            await _load();
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                )),
                            if (_routes.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 24),
                                child: Text(
                                  'No fixed routes yet — add your first destination below.',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            const SizedBox(height: 8),
                            FixedRouteForm(
                              originController: _originController,
                              destination: _destination,
                              destinations: _destinations,
                              distanceController: _distanceController,
                              priceController: _priceController,
                              onDestinationChanged: (d) => setState(
                                  () => _destination = d),
                              onAdd: _addRoute,
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
