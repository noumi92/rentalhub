import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/minimal_app_bar.dart';
import '../../../../core/widgets/pakistani_plate_widget.dart';
import '../../../../features/fleet/domain/entities/vehicle_entity.dart';
import 'widgets/vehicle_detail_action_bar.dart';
import 'widgets/vehicle_detail_packages.dart';
import 'widgets/vehicle_hero_card.dart';
import 'widgets/vehicle_image_asset.dart';
import 'widgets/vehicle_spec_box.dart';
import '../../../../l10n/app_localizations.dart';

/// Phase A (A1): the car detail screen now takes a real [VehicleEntity]
/// (loaded by the route) instead of a [MockVehicle]. The showroom name and
/// phone come from the `shops` document, so the WhatsApp button opens a
/// real chat with the shop.
class VehicleDetailView extends StatefulWidget {
  final VehicleEntity vehicle;
  final String shopName;
  final String shopPhone;

  /// The shop document's `owner_id` ('' when unknown). The action bar
  /// uses it to recognise the owner's own car: new cars carry the shop
  /// DOCUMENT id, not the owner UID, so the vehicle's `shopId` alone no
  /// longer identifies its owner.
  final String shopOwnerId;
  final VoidCallback? onBookNow;
  final VoidCallback? onBack;

  const VehicleDetailView({
    super.key,
    required this.vehicle,
    required this.shopName,
    required this.shopPhone,
    this.shopOwnerId = '',
    this.onBookNow,
    this.onBack,
  });

  @override
  State<VehicleDetailView> createState() => _VehicleDetailViewState();
}

class _VehicleDetailViewState extends State<VehicleDetailView> {
  bool _withDriver = false;

  // CU-M9: the make/model → asset mapping is the shared
  // [vehicleImageAsset] helper — this view used to carry its own
  // copy that showed a Sportage as a red Civic.
  String _getCarImage(VehicleEntity v) =>
      vehicleImageAsset(v.make, v.model);

  String _statusLabel(String status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case 'rented':
        return l10n.rentedOut;
      case 'maintenance':
        return l10n.inMaintenance;
      default:
        return l10n.availableNow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
                    MinimalAppBar(
                      title: '${v.make} ${v.model} (${v.year})',
                      subtitle: '${widget.shopName} • ${v.category}',
                      onBack: widget.onBack,
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
                                    Text(v.displayName, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 4),
                                    Text(l10n.vehicleShowroom(widget.shopName), style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurfaceVariant)),
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
                                child: Text(_statusLabel(v.status), style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w500, color: AppColors.successTextFor(Theme.of(context).brightness))),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(child: VehicleSpecBox(icon: Icons.settings_rounded, label: l10n.vehicleTransmission, value: v.transmission)),
                              const SizedBox(width: 8),
                              Expanded(child: VehicleSpecBox(icon: Icons.local_gas_station_rounded, label: l10n.vehicleFuelType, value: v.fuelType)),
                              const SizedBox(width: 8),
                              Expanded(child: VehicleSpecBox(icon: Icons.airline_seat_recline_normal_rounded, label: l10n.vehicleCapacity, value: '${v.seats} Seats')),
                              const SizedBox(width: 8),
                              Expanded(child: VehicleSpecBox(icon: Icons.speed_rounded, label: l10n.vehicleMileage, value: v.mileageKm != null ? '${v.mileageKm} km' : '—')),
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
              shopOwnerId: widget.shopOwnerId,
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
          Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
