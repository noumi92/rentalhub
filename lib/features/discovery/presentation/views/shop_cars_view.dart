import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../fleet/data/datasources/fleet_remote_data_source.dart';
import '../../../fleet/domain/entities/vehicle_entity.dart';
import 'widgets/customer_vehicle_card.dart';
import '../../../../l10n/app_localizations.dart';

/// B3: the shop's fleet screen, converted from MockVehicle to the real
/// [VehicleEntity]. Without a [vehicles] list it loads the shop's real
/// fleet from Firestore — the old version fell back to the mock database.
class ShopCarsView extends StatefulWidget {
  final String shopId;
  final String shopName;
  final List<VehicleEntity>? vehicles;
  final ValueChanged<VehicleEntity>? onCarSelected;
  final VoidCallback? onBack;

  const ShopCarsView({
    super.key,
    required this.shopId,
    required this.shopName,
    this.vehicles,
    this.onCarSelected,
    this.onBack,
  });

  @override
  State<ShopCarsView> createState() => _ShopCarsViewState();
}

class _ShopCarsViewState extends State<ShopCarsView> {
  String _selectedCategory = 'All';
  final List<String> _categories = ['All', 'Sedan', 'SUV', 'Hiace', 'Luxury'];
  List<VehicleEntity> _loaded = const [];
  bool _loading = false;
  // E2: a load failure used to clear the spinner silently; it now
  // renders an error state with retry.
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    if (widget.vehicles == null) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _hasError = false;
    });
    try {
      final vehicles =
          await sl<FleetRemoteDataSource>().getShopVehicles(widget.shopId);
      if (mounted) {
        setState(() {
          _loaded = vehicles;
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

  /// The stored filter value stays English (it is compared against the
  /// vehicle's `category`); only the chip label is localized.
  String _categoryLabel(AppLocalizations l10n, String category) {
    switch (category) {
      case 'Sedan':
        return l10n.shopCategorySedan;
      case 'SUV':
        return l10n.shopCategorySuv;
      case 'Hiace':
        return l10n.shopCategoryHiace;
      case 'Luxury':
        return l10n.shopCategoryLuxury;
      default:
        return l10n.filterAll;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final list = widget.vehicles ?? _loaded;
    final filtered = _selectedCategory == 'All'
        ? list
        : list
            .where((v) =>
                v.category.toLowerCase() == _selectedCategory.toLowerCase())
            .toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            MinimalAppBar(
              title: l10n.shopCarsTitle,
              subtitle: widget.shopName,
              onBack: widget.onBack,
            ),
            // E3: 48dp chip + 8dp vertical padding each side — the
            // old 52dp row squeezed the category chips to 36dp.
            Container(
              height: 64,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final cat = _categories[i];
                  final isSelected = cat == _selectedCategory;
                  return ChoiceChip(
                    materialTapTargetSize: MaterialTapTargetSize.padded,
                    label: Text(_categoryLabel(l10n, cat)),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedCategory = cat),
                    selectedColor: AppColors.primary,
                    labelStyle: Theme.of(context)
                        .textTheme
                        .labelMedium
                        ?.copyWith(
                            fontWeight:
                                isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : Theme.of(context).colorScheme.onSurface),
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.primary
                          : Theme.of(context).dividerColor,
                    ),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  );
                },
              ),
            ),
            Expanded(
              child: _loading
                  // E2: shared loading / error / empty states.
                  ?  AppLoadingState(
                      message: l10n.shopCarsLoading,
                    )
                  : _hasError
                      ? AppErrorState(
                          message:
                              l10n.shopCarsLoadError,
                          onRetry: _load,
                        )
                      : filtered.isEmpty
                          ? AppEmptyState(
                              title:
                                  l10n.shopCarsNoneInCategory(_categoryLabel(l10n, _selectedCategory)),
                              message:
                                  l10n.shopCarsTryOther,
                              icon: Icons.directions_car_outlined,
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final car = filtered[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: CustomerVehicleCard(
                                    vehicle: car,
                                    onTap: () =>
                                        widget.onCarSelected?.call(car),
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
