import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/pakistani_plate_widget.dart';

class BookingSummaryCard extends StatelessWidget {
  final String carName;
  final String plateNumber;
  final String shopName;
  final bool isWithDriver;
  final String packageType;
  final DateTime pickupTime;
  final DateTime returnTime;
  final int totalAmount;
  final int advanceRequired;
  // C2: the trip details the picker chose — shown when the caller has
  // them (the review screen does; older call sites omit them).
  final String tripType;
  final int? kmLimit;
  final int? securityDepositPkr;
  final String? destinationCity;

  const BookingSummaryCard({
    super.key,
    required this.carName,
    required this.plateNumber,
    required this.shopName,
    required this.isWithDriver,
    required this.packageType,
    required this.pickupTime,
    required this.returnTime,
    required this.totalAmount,
    required this.advanceRequired,
    this.tripType = 'in_city',
    this.kmLimit,
    this.securityDepositPkr,
    this.destinationCity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      carName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Showroom: $shopName',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
              ),
              PakistaniPlateWidget(plateNumber: plateNumber, isCompact: true),
            ],
          ),
          const Divider(height: 24),
          _buildRow(context, 'Mode', isWithDriver ? 'With Chauffeur' : 'Self-Drive'),
          const SizedBox(height: 8),
          _buildRow(context, 'Package Tier', '$packageType Rental'),
          const SizedBox(height: 8),
          _buildRow(context, 
            'Trip',
            tripType == 'out_of_city'
                ? 'Out of city${destinationCity != null ? ' → $destinationCity' : ''}'
                : 'In city',
          ),
          if (kmLimit != null) ...[
            const SizedBox(height: 8),
            _buildRow(context, 'KM Included', '$kmLimit km'),
          ],
          if (securityDepositPkr != null) ...[
            const SizedBox(height: 8),
            _buildRow(context, 
              'Security Deposit',
              'Rs. $securityDepositPkr (at handover)',
            ),
          ],
          const SizedBox(height: 8),
          _buildRow(context, 
            'Pickup Time',
            '${pickupTime.day}/${pickupTime.month}/${pickupTime.year} at ${pickupTime.hour.toString().padLeft(2, '0')}:${pickupTime.minute.toString().padLeft(2, '0')}',
          ),
          const SizedBox(height: 8),
          _buildRow(context, 
            'Return Due',
            '${returnTime.day}/${returnTime.month}/${returnTime.year} at ${returnTime.hour.toString().padLeft(2, '0')}:${returnTime.minute.toString().padLeft(2, '0')}',
          ),
          const Divider(height: 24),
          _buildRow(context, 'Total Rental Fare', 'Rs. $totalAmount', isBold: true),
          const SizedBox(height: 8),
          _buildRow(context, 
            'Advance Payable',
            'Rs. $advanceRequired',
            color: AppColors.secondary,
            isBold: true,
          ),
          const SizedBox(height: 8),
          _buildRow(context, 
            'Balance at Handover',
            'Rs. ${totalAmount - advanceRequired}',
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ],
      ),
    );
  }

  Widget _buildRow(BuildContext context, String label, String value,
      {bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isBold ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            color: color ?? Theme.of(context).colorScheme.onSurface,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

