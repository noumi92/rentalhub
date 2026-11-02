import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/custom_curved_header.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../../../../core/widgets/pakistani_plate_widget.dart';
import '../../../fleet/data/datasources/fleet_remote_data_source.dart';
import '../../../fleet/domain/entities/vehicle_entity.dart';
import '../widgets/fleet/rate_matrix_field_widget.dart';

class OwnerRateMatrixView extends StatefulWidget {
  final VehicleEntity vehicle;
  final VoidCallback? onRatesSaved;
  final VoidCallback? onBack;

  const OwnerRateMatrixView({
    super.key,
    required this.vehicle,
    this.onRatesSaved,
    this.onBack,
  });

  @override
  State<OwnerRateMatrixView> createState() => _OwnerRateMatrixViewState();
}

class _OwnerRateMatrixViewState extends State<OwnerRateMatrixView> {
  late TextEditingController _hourly1Controller;
  late TextEditingController _hourly3Controller;
  late TextEditingController _hourly6Controller;
  late TextEditingController _daily24Controller;
  late TextEditingController _outOfCityController;

  late bool _isSelfDrive;
  late bool _isWithDriver;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final r = widget.vehicle.rates;
    _hourly1Controller =
        TextEditingController(text: (r.hourly1 ?? 1500).toString());
    _hourly3Controller =
        TextEditingController(text: (r.hourly3 ?? 3500).toString());
    _hourly6Controller =
        TextEditingController(text: (r.hourly6 ?? 6000).toString());
    _daily24Controller =
        TextEditingController(text: r.daily24.toString());
    _outOfCityController = TextEditingController(
        text: (r.outOfCityDaily ?? (r.daily24 * 1.3).round()).toString());

    _isSelfDrive = widget.vehicle.isSelfDriveAvailable;
    _isWithDriver = widget.vehicle.isWithDriverAvailable;
  }

  @override
  void dispose() {
    _hourly1Controller.dispose();
    _hourly3Controller.dispose();
    _hourly6Controller.dispose();
    _daily24Controller.dispose();
    _outOfCityController.dispose();
    super.dispose();
  }

  Future<void> _saveRates() async {
    setState(() => _isSaving = true);
    try {
      final updatedRates = VehicleRatesEntity(
        hourly1: int.tryParse(_hourly1Controller.text.trim()) ?? 1500,
        hourly3: int.tryParse(_hourly3Controller.text.trim()) ?? 3500,
        hourly6: int.tryParse(_hourly6Controller.text.trim()) ?? 6000,
        daily24: int.tryParse(_daily24Controller.text.trim()) ?? 8000,
        outOfCityDaily:
            int.tryParse(_outOfCityController.text.trim()) ?? 10500,
      );

      final ds = sl<FleetRemoteDataSource>();
      await ds.updateVehicleRates(
        vehicleId: widget.vehicle.vehicleId,
        rates: updatedRates,
      );

      if (mounted) {
        AppFeedback.showSuccess(context, 'Pricing matrix updated in showroom!');
        widget.onRatesSaved?.call();
      }
    } catch (e) {
      if (mounted) AppFeedback.showError(context, 'Failed to update rates: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.vehicle;
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            CustomCurvedHeader(
              height: 100,
              leadingWidget: widget.onBack != null
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 20),
                      onPressed: widget.onBack,
                    )
                  : null,
              titleWidget: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Vehicle Pricing Matrix',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900)),
                  Text('${v.make} ${v.model} (${v.year})',
                      style: const TextStyle(
                          color: AppColors.textLavender, fontSize: 12)),
                ],
              ),
              actions: [
                PakistaniPlateWidget(
                    plateNumber: v.plateNumber, isCompact: true)
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Drive Mode Availability',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.midnightNavy)),
                    const SizedBox(height: 8),
                    Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            SwitchListTile(
                              activeThumbColor: AppColors.sunsetOrange,
                              title: const Text('Self-Drive Allowed',
                                  style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700)),
                              subtitle: const Text(
                                  'Requires original NADRA CNIC + security deposit',
                                  style: TextStyle(fontSize: 11)),
                              value: _isSelfDrive,
                              onChanged: (val) =>
                                  setState(() => _isSelfDrive = val),
                            ),
                            const Divider(height: 1),
                            SwitchListTile(
                              activeThumbColor: AppColors.sunsetOrange,
                              title: const Text('Chauffeur Service Allowed',
                                  style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700)),
                              subtitle: const Text(
                                  'Showroom driver assigned to booking',
                                  style: TextStyle(fontSize: 11)),
                              value: _isWithDriver,
                              onChanged: (val) =>
                                  setState(() => _isWithDriver = val),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text('Daily Rental Tiers',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.midnightNavy)),
                    const SizedBox(height: 8),
                    RateMatrixFieldWidget(
                      controller: _daily24Controller,
                      label: 'In-City Daily (24h)',
                      hint: 'Rs. 8,000 / day',
                      kmCap: '250 km included',
                    ),
                    const SizedBox(height: 10),
                    RateMatrixFieldWidget(
                      controller: _outOfCityController,
                      label: 'Out-of-City Daily (24h)',
                      hint: 'Rs. 10,500 / day',
                      kmCap: '350 km included + tracker cleared',
                    ),
                    const SizedBox(height: 18),
                    const Text('Hourly Express Tiers',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.midnightNavy)),
                    const SizedBox(height: 8),
                    RateMatrixFieldWidget(
                      controller: _hourly6Controller,
                      label: '6-Hour Express Rate',
                      hint: 'Rs. 6,000',
                      kmCap: '80 km included',
                    ),
                    const SizedBox(height: 10),
                    RateMatrixFieldWidget(
                      controller: _hourly3Controller,
                      label: '3-Hour Airport / Quick Trip',
                      hint: 'Rs. 3,500',
                      kmCap: '40 km included',
                    ),
                    const SizedBox(height: 10),
                    RateMatrixFieldWidget(
                      controller: _hourly1Controller,
                      label: '1-Hour City Commute',
                      hint: 'Rs. 1,500',
                      kmCap: '15 km included',
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 10,
                      offset: Offset(0, -3))
                ],
              ),
              child: DebouncedButton(
                text: _isSaving ? 'Saving Matrix...' : 'Save Pricing Matrix',
                icon: Icons.check_circle_rounded,
                isLoading: _isSaving,
                onPressed: _saveRates,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
