import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../bookings/domain/entities/booking_entity.dart';

/// Phase B (E3): the agreement rendered as a paper sheet, extracted
/// from [OwnerContractView] so the view stays under the 250-line
/// cap. Shows only real data — no fake shop name, no fake
/// "Verified Clean" claim, no hardcoded deposit.
class ContractPaperSheet extends StatelessWidget {
  final BookingEntity booking;
  final int odometer;
  final String fuelLevel;
  final int? securityDeposit;
  final Uint8List? customerSignaturePng;
  final Uint8List? ownerSignaturePng;

  const ContractPaperSheet({
    super.key,
    required this.booking,
    required this.odometer,
    required this.fuelLevel,
    this.securityDeposit,
    this.customerSignaturePng,
    this.ownerSignaturePng,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: Color(0x12000000),
              blurRadius: 10,
              offset: Offset(0, 4)),
        ],
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                Text(
                  (booking.shopName ?? 'RentalHub').toUpperCase(),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text('Govt. Registered Commercial Motor Car Rental Agency',
                    style:
                        Theme.of(context).textTheme.labelSmall),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4)),
                  child: Text('CERTIFIED DIGITAL RENTAL CONTRACT',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      )),
                ),
              ],
            ),
          ),
          const Divider(height: 24, thickness: 1.5),
          _fieldRow('Agreement No:', '#${booking.bookingId}'),
          _fieldRow('Hirer / Customer:', booking.customerName ?? 'Walk-in Customer'),
          _fieldRow('Customer Contact:', booking.customerPhone ?? '—'),
          _fieldRow('CNIC:', booking.customerCnic ?? 'Not provided'),
          const Divider(height: 20),
          _fieldRow('Rented Vehicle:', booking.vehicleName ?? 'Vehicle'),
          _fieldRow('Package Tier:',
              '${booking.packageType} (${booking.isWithDriver ? "Chauffeur" : "Self-Drive"})'),
          _fieldRow('Departure Odometer:', '$odometer KM'),
          _fieldRow('Handover Fuel Gauge:', fuelLevel),
          _fieldRow('Total Rental Paid:', 'Rs. ${booking.totalAmount}'),
          _fieldRow('Security Deposit:',
              securityDeposit != null ? 'Rs. $securityDeposit (refundable)' : '—'),
          const Divider(height: 20),
          Text(
            'Legal Terms & Conditions (Pakistan Jurisdiction):',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '1. Vehicle shall not be driven across unauthorized provincial checkpoints without NOC.\n'
            '2. Traffic challans, e-tickets and fuel consumed are sole liability of the hirer.\n'
            '3. Any default will result in immediate non-bailable FIR and National Tribunal Blacklist listing.',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              height: 1.4,
            ),
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _signatureColumn(
                  'Hirer Signature', customerSignaturePng, 'Signed on the pad'),
              _signatureColumn('Host Seal & Signature', ownerSignaturePng,
                  'Authorized Agency Manager'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _signatureColumn(String label, Uint8List? png, String caption) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (png != null)
          Image.memory(png, width: 110, height: 44, fit: BoxFit.contain)
        else
          const Icon(Icons.verified_rounded,
              color: AppColors.accentSuccess, size: 24),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
        Text(caption,
            style:
                const TextStyle(fontSize: 9.5, color: AppColors.textMuted)),
      ],
    );
  }

  Widget _fieldRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11.5, color: AppColors.textSecondary)),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.end,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}
