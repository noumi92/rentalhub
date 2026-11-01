import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_curved_header.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../../../../core/widgets/pakistani_plate_widget.dart';
import '../widgets/driver_mode_toggle.dart';
import '../widgets/duration_calendar_picker.dart';
import '../widgets/package_tier_card.dart';

class RentPackagePickerView extends StatefulWidget {
  final String carId;
  final String carName;
  final String plateNumber;
  final String shopId;
  final String shopName;
  final int dailySelfDriveRate;
  final int dailyWithDriverRate;
  final int? hourlyRate;
  final Function(Map<String, dynamic> bookingDraft)? onProceedToReview;
  final VoidCallback? onBack;

  const RentPackagePickerView({
    super.key,
    required this.carId,
    required this.carName,
    required this.plateNumber,
    required this.shopId,
    required this.shopName,
    required this.dailySelfDriveRate,
    required this.dailyWithDriverRate,
    this.hourlyRate,
    this.onProceedToReview,
    this.onBack,
  });

  @override
  State<RentPackagePickerView> createState() => _RentPackagePickerViewState();
}

class _RentPackagePickerViewState extends State<RentPackagePickerView> {
  bool _isWithDriver = false;
  String _selectedPackage = '24h';
  DateTime _pickupDate = DateTime.now().add(const Duration(hours: 2));
  TimeOfDay _pickupTime = TimeOfDay.now();
  int _durationDays = 1;

  int get _calculatedRate {
    final baseDaily = _isWithDriver
        ? widget.dailyWithDriverRate
        : widget.dailySelfDriveRate;
    switch (_selectedPackage) {
      case '1h':
        return widget.hourlyRate ?? (baseDaily * 0.15).round();
      case '3h':
        return ((widget.hourlyRate ?? (baseDaily * 0.15).round()) * 2.5).round();
      case '6h':
        return ((widget.hourlyRate ?? (baseDaily * 0.15).round()) * 4.5).round();
      case '24h':
      default:
        return baseDaily * _durationDays;
    }
  }

  int get _advanceRequired {
    return (_calculatedRate * 0.25).round().clamp(1000, 10000);
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
                  const Text('Select Rental Package',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900)),
                  Text('${widget.carName} • ${widget.shopName}',
                      style: const TextStyle(
                          color: AppColors.textLavender, fontSize: 12)),
                ],
              ),
              actions: [
                PakistaniPlateWidget(
                    plateNumber: widget.plateNumber, isCompact: true)
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DriverModeToggle(
                      isWithDriver: _isWithDriver,
                      onChanged: (val) => setState(() => _isWithDriver = val),
                    ),
                    const SizedBox(height: 16),
                    const Text('Available Duration Tiers',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.midnightNavy)),
                    const SizedBox(height: 10),
                    PackageTierCard(
                      title: 'Daily 24-Hours',
                      subtitle: 'Full day flexibility with grace return period',
                      price: _isWithDriver
                          ? widget.dailyWithDriverRate
                          : widget.dailySelfDriveRate,
                      kmIncluded: '250 km/day',
                      isSelected: _selectedPackage == '24h',
                      onTap: () => setState(() => _selectedPackage = '24h'),
                    ),
                    const SizedBox(height: 10),
                    PackageTierCard(
                      title: '6-Hour Express',
                      subtitle: 'Ideal for city errands, weddings & meetings',
                      price: ((widget.hourlyRate ??
                                  (widget.dailySelfDriveRate * 0.15).round()) *
                              4.5)
                          .round(),
                      kmIncluded: '80 km',
                      isSelected: _selectedPackage == '6h',
                      onTap: () => setState(() => _selectedPackage = '6h'),
                    ),
                    const SizedBox(height: 10),
                    PackageTierCard(
                      title: '3-Hour Quick Trip',
                      subtitle: 'Airport drop/pickup & short commutes',
                      price: ((widget.hourlyRate ??
                                  (widget.dailySelfDriveRate * 0.15).round()) *
                              2.5)
                          .round(),
                      kmIncluded: '40 km',
                      isSelected: _selectedPackage == '3h',
                      onTap: () => setState(() => _selectedPackage = '3h'),
                    ),
                    const SizedBox(height: 16),
                    DurationCalendarPicker(
                      pickupDate: _pickupDate,
                      pickupTime: _pickupTime,
                      durationDays: _durationDays,
                      onDateChanged: (d) => setState(() => _pickupDate = d),
                      onTimeChanged: (t) => setState(() => _pickupTime = t),
                      onDurationChanged: (days) =>
                          setState(() => _durationDays = days),
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
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Total: Rs. $_calculatedRate',
                            style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: AppColors.midnightNavy)),
                        Text('Advance Due: Rs. $_advanceRequired',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.sunsetOrange)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 140,
                    child: DebouncedButton(
                      text: 'Continue',
                      icon: Icons.arrow_forward_rounded,
                      onPressed: () async {
                        final pickupDateTime = DateTime(
                          _pickupDate.year,
                          _pickupDate.month,
                          _pickupDate.day,
                          _pickupTime.hour,
                          _pickupTime.minute,
                        );
                        final returnDateTime = _selectedPackage == '24h'
                            ? pickupDateTime.add(Duration(days: _durationDays))
                            : pickupDateTime.add(
                                Duration(hours: int.parse(_selectedPackage.replaceAll('h', ''))));

                        widget.onProceedToReview?.call({
                          'carId': widget.carId,
                          'carName': widget.carName,
                          'plateNumber': widget.plateNumber,
                          'shopId': widget.shopId,
                          'shopName': widget.shopName,
                          'isWithDriver': _isWithDriver,
                          'packageType': _selectedPackage,
                          'pickupTime': pickupDateTime,
                          'returnTime': returnDateTime,
                          'totalAmount': _calculatedRate,
                          'advanceRequired': _advanceRequired,
                        });
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
}
