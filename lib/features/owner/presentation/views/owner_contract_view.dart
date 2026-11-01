import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/custom_curved_header.dart';
import '../../../../core/widgets/debounced_button.dart';
import '../../../bookings/domain/entities/booking_entity.dart';
import 'owner_return_settlement_view.dart';

class OwnerContractView extends StatelessWidget {
  final BookingEntity booking;
  final int odometer;
  final String fuelLevel;
  final VoidCallback? onBack;

  const OwnerContractView({
    super.key,
    required this.booking,
    this.odometer = 45200,
    this.fuelLevel = '4/4 (Full)',
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            CustomCurvedHeader(
              height: 100,
              leadingWidget: onBack != null
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                      onPressed: onBack,
                    )
                  : null,
              titleWidget: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Digital Rental Contract', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                  Text('Legal Agreement Ref: #${booking.bookingId}', style: const TextStyle(color: AppColors.textLavender, fontSize: 11.5)),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.share_rounded, color: Colors.white),
                  tooltip: 'Share on WhatsApp',
                  onPressed: () => AppFeedback.showSuccess(context, 'Contract PDF link dispatched to customer on WhatsApp!'),
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(
                  children: [
                    _contractPaperSheet(context),
                    const SizedBox(height: 20),
                    DebouncedButton(
                      text: 'Proceed to Return & Settlement',
                      icon: Icons.assignment_return_rounded,
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => OwnerReturnSettlementView(
                              booking: booking,
                              initialOdometer: odometer,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _contractPaperSheet(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x12000000), blurRadius: 10, offset: Offset(0, 4)),
        ],
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                Text(
                  booking.shopName?.toUpperCase() ?? 'AL-FALAH RENT A CAR LAHORE',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.midnightNavy, letterSpacing: 0.5),
                ),
                const SizedBox(height: 2),
                const Text('Govt. Registered Commercial Motor Car Rental Agency', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.midnightNavy, borderRadius: BorderRadius.circular(4)),
                  child: const Text('CERTIFIED DIGITAL RENTAL CONTRACT', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),
          const Divider(height: 24, thickness: 1.5),
          _fieldRow('Agreement No:', '#${booking.bookingId}'),
          _fieldRow('Hirer / Customer:', booking.customerName ?? 'Walk-in Customer'),
          _fieldRow('Customer Contact:', booking.customerPhone ?? '0300-1122334'),
          _fieldRow('CNIC Verification:', 'Verified Clean (NADRA / Tribunal)'),
          const Divider(height: 20),
          _fieldRow('Rented Vehicle:', booking.vehicleName ?? 'Honda Civic RS Turbo (2023)'),
          _fieldRow('Package Tier:', '${booking.packageType} (${booking.isWithDriver ? "Chauffeur" : "Self-Drive"})'),
          _fieldRow('Departure Odometer:', '$odometer KM'),
          _fieldRow('Handover Fuel Gauge:', fuelLevel),
          _fieldRow('Total Rental Paid:', 'Rs. ${booking.totalAmount}'),
          _fieldRow('Security Deposit:', 'Rs. 15,000 (Refundable upon inspection)'),
          const Divider(height: 20),
          const Text(
            'Legal Terms & Conditions (Pakistan Jurisdiction):',
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.midnightNavy),
          ),
          const SizedBox(height: 4),
          const Text(
            '1. Vehicle shall not be driven across unauthorized provincial checkpoints without NOC.\n'
            '2. Traffic challans, e-tickets and fuel consumed are sole liability of the hirer.\n'
            '3. Any default will result in immediate non-bailable FIR and National Tribunal Blacklist listing.',
            style: TextStyle(fontSize: 10.5, color: AppColors.textSecondary, height: 1.4),
          ),
          const Divider(height: 24),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.verified_rounded, color: AppColors.emeraldGreen, size: 24),
                  SizedBox(height: 2),
                  Text('Hirer Signature', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                  Text('Signed via OTP/Touch', style: TextStyle(fontSize: 9.5, color: AppColors.textSecondary)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Icon(Icons.verified_rounded, color: AppColors.emeraldGreen, size: 24),
                  SizedBox(height: 2),
                  Text('Host Seal & Signature', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                  Text('Authorized Agency Manager', style: TextStyle(fontSize: 9.5, color: AppColors.textSecondary)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _fieldRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.midnightNavy)),
        ],
      ),
    );
  }
}
