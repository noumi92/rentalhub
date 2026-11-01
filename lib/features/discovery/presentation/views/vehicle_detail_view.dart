import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/mock_data.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/custom_curved_header.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../../../../core/widgets/pakistani_plate_widget.dart';
import 'widgets/vehicle_hero_card.dart';
import 'widgets/vehicle_package_card.dart';
import 'widgets/vehicle_spec_box.dart';

class VehicleDetailView extends StatefulWidget {
  final MockVehicle vehicle;
  final VoidCallback? onBookNow;
  final VoidCallback? onBack;

  const VehicleDetailView({
    super.key,
    required this.vehicle,
    this.onBookNow,
    this.onBack,
  });

  @override
  State<VehicleDetailView> createState() => _VehicleDetailViewState();
}

class _VehicleDetailViewState extends State<VehicleDetailView> {
  bool _withDriver = false;

  String _getCarImage(MockVehicle v) {
    final nameLower = v.name.toLowerCase();
    if (nameLower.contains('civic')) {
      return 'assets/images/honda_civic_hero.png';
    } else if (nameLower.contains('corolla') || nameLower.contains('yaris')) {
      return 'assets/images/toyota_corolla.png';
    } else if (nameLower.contains('sportage') || nameLower.contains('br-v')) {
      return 'assets/images/red_civic.png';
    }
    return 'assets/images/white_sedan_hero.png';
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.vehicle;
    final int selectedRate = _withDriver ? v.withDriverDailyRate : v.selfDriveDailyRate;
    final carAsset = _getCarImage(v);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
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
                          Text('${v.name} (${v.modelYear})', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 2),
                          Text('${v.shopName} • ${v.category}', style: const TextStyle(color: AppColors.textLavender, fontSize: 12)),
                        ],
                      ),
                      actions: [PakistaniPlateWidget(plateNumber: v.plateNumber, isCompact: true)],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          VehicleHeroCard(vehicle: v, carAsset: carAsset),
                          const SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${v.name} ${v.modelYear}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.midnightNavy)),
                                    const SizedBox(height: 4),
                                    Text('Showroom: ${v.shopName}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: AppColors.emeraldGreen.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.emeraldGreen.withValues(alpha: 0.3)),
                                ),
                                child: const Text('Ready Now', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.emeraldGreen)),
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
                              Expanded(child: VehicleSpecBox(icon: Icons.ac_unit_rounded, label: 'Air Conditioning', value: v.hasAC ? 'Full AC' : 'Non-AC')),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: v.features.map(_featureChip).toList(),
                          ),
                          const SizedBox(height: 20),
                          const Text('Choose Rental Package', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.midnightNavy)),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: VehiclePackageCard(
                                  title: 'Self Drive',
                                  urdu: 'سیلف ڈرائیو',
                                  price: v.selfDriveDailyRate,
                                  isSelected: !_withDriver,
                                  icon: Icons.drive_eta_rounded,
                                  onTap: () => setState(() => _withDriver = false),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: VehiclePackageCard(
                                  title: 'With Driver',
                                  urdu: 'ڈرائیور کے ساتھ',
                                  price: v.withDriverDailyRate,
                                  isSelected: _withDriver,
                                  icon: Icons.person_pin_rounded,
                                  onTap: () => setState(() => _withDriver = true),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _withDriver ? AppColors.emeraldGreen.withValues(alpha: 0.08) : AppColors.amberGold.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _withDriver ? AppColors.emeraldGreen.withValues(alpha: 0.25) : AppColors.amberGold.withValues(alpha: 0.35)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(_withDriver ? Icons.verified_user_rounded : Icons.security_rounded, size: 18, color: _withDriver ? AppColors.emeraldGreen : AppColors.midnightNavy),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _withDriver
                                        ? 'Verified chauffeur included • Overtime: Rs. ${v.overtimeHourlyRate}/hr • Outstation: +Rs. ${v.outstationAllowance}/day'
                                        : 'Security Deposit: Rs. ${v.securityDeposit} + Original NADRA CNIC guarantee required at pickup',
                                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.midnightNavy, height: 1.3),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, -3))],
              ),
              child: Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Opening WhatsApp with ${v.shopName} for ${v.name}...'), backgroundColor: AppColors.emeraldGreen, duration: const Duration(seconds: 2)),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.emeraldGreen,
                      side: const BorderSide(color: Color(0xFF86EFAC)),
                      backgroundColor: const Color(0xFFF0FDF4),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: AppColors.emeraldGreen),
                    label: const Text('WhatsApp', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DebouncedButton(
                      text: 'Book Now (Rs. $selectedRate)',
                      icon: Icons.check_circle_outline_rounded,
                      onPressed: () async {
                        if (widget.onBookNow != null) {
                          widget.onBookNow!.call();
                        } else {
                          AppFeedback.showInfo(
                            context,
                            'Selected: ${_withDriver ? "With Chauffeur" : "Self-Drive"}. Advance deposit required.',
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _featureChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: AppColors.backgroundLight, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_rounded, size: 13, color: AppColors.sunsetOrange),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.midnightNavy)),
        ],
      ),
    );
  }
}
