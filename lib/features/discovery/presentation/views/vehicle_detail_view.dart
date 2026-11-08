import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_curved_header.dart';
import '../../../../core/widgets/pakistani_plate_widget.dart';
import '../../../../features/fleet/domain/entities/vehicle_entity.dart';
import 'widgets/vehicle_detail_action_bar.dart';
import 'widgets/vehicle_detail_packages.dart';
import 'widgets/vehicle_hero_card.dart';
import 'widgets/vehicle_spec_box.dart';

/// Phase A (A1): the car detail screen now takes a real [VehicleEntity]
/// (loaded by the route) instead of a [MockVehicle]. The showroom name and
/// phone come from the `shops` document, so the WhatsApp button opens a
/// real chat with the shop.
class VehicleDetailView extends StatefulWidget {
  final VehicleEntity vehicle;
  final String shopName;
  final String shopPhone;
  final VoidCallback? onBookNow;
  final VoidCallback? onBack;

  const VehicleDetailView({
    super.key,
    required this.vehicle,
    required this.shopName,
    required this.shopPhone,
    this.onBookNow,
    this.onBack,
  });

  @override
  State<VehicleDetailView> createState() => _VehicleDetailViewState();
}

class _VehicleDetailViewState extends State<VehicleDetailView> {
  bool _withDriver = false;

  String _getCarImage(VehicleEntity v) {
    final nameLower = '${v.make} ${v.model}'.toLowerCase();
    if (nameLower.contains('civic')) {
      return 'assets/images/honda_civic_hero.png';
    } else if (nameLower.contains('corolla') || nameLower.contains('yaris')) {
      return 'assets/images/toyota_corolla.png';
    } else if (nameLower.contains('sportage') || nameLower.contains('br-v')) {
      return 'assets/images/red_civic.png';
    }
    return 'assets/images/white_sedan_hero.png';
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'rented':
        return 'Rented Out';
      case 'maintenance':
        return 'In Maintenance';
      default:
        return 'Available Now';
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.vehicle;
    final int selfDriveRate = v.rates.daily24;
    final int withDriverRate =
        v.rates.daily24 + (v.withDriverSurchargePkr ?? 0);
    final int selectedRate = _withDriver ? withDriverRate : selfDriveRate;
    final carAsset = _getCarImage(v);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CustomCurvedHeader(
                      height: 100,
                      leadingWidget: widget.onBack != null
                          ? IconButton(
                              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                              onPressed: widget.onBack,
                            )
                          : null,
                      titleWidget: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${v.make} ${v.model} (${v.year})', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: Colors.white)),
                          const SizedBox(height: 2),
                          Text('${widget.shopName} • ${v.category}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.primaryContainer)),
                        ],
                      ),
                      actions: [PakistaniPlateWidget(plateNumber: v.plateNumber, isCompact: true)],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          VehicleHeroCard(
                            vehicle: v,
                            carAsset: carAsset,
                            imageUrl: v.imageUrl,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(v.displayName, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                                    const SizedBox(height: 4),
                                    Text('Showroom: ${widget.shopName}', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: AppColors.accentSuccess.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.accentSuccess.withValues(alpha: 0.3)),
                                ),
                                child: Text(_statusLabel(v.status), style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800, color: AppColors.successTextFor(Theme.of(context).brightness))),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(child: VehicleSpecBox(icon: Icons.settings_rounded, label: 'Transmission', value: v.transmission)),
                              const SizedBox(width: 8),
                              Expanded(child: VehicleSpecBox(icon: Icons.local_gas_station_rounded, label: 'Fuel Type', value: v.fuelType)),
                              const SizedBox(width: 8),
                              Expanded(child: VehicleSpecBox(icon: Icons.airline_seat_recline_normal_rounded, label: 'Capacity', value: '${v.seats} Seats')),
                              const SizedBox(width: 8),
                              Expanded(child: VehicleSpecBox(icon: Icons.speed_rounded, label: 'Mileage', value: v.mileageKm != null ? '${v.mileageKm} km' : '—')),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: v.features.map(_featureChip).toList(),
                          ),
                          const SizedBox(height: 20),
                          VehicleDetailPackages(
                            vehicle: v,
                            withDriver: _withDriver,
                            onDriveModeChanged: (val) =>
                                setState(() => _withDriver = val),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            VehicleDetailActionBar(
              vehicle: v,
              shopName: widget.shopName,
              shopPhone: widget.shopPhone,
              selectedRate: selectedRate,
              withDriver: _withDriver,
              onBookNow: widget.onBookNow,
            ),
          ],
        ),
      ),
    );
  }

  Widget _featureChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(10), border: Border.all(color: Theme.of(context).dividerColor)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_rounded, size: 13, color: AppColors.secondary),
          const SizedBox(width: 4),
          Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
