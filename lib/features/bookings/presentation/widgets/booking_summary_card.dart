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
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
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
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.midnightNavy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Showroom: $shopName',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              PakistaniPlateWidget(plateNumber: plateNumber, isCompact: true),
            ],
          ),
          const Divider(height: 24),
          _buildRow('Mode', isWithDriver ? 'With Chauffeur' : 'Self-Drive'),
          const SizedBox(height: 8),
          _buildRow('Package Tier', '$packageType Rental'),
          const SizedBox(height: 8),
          _buildRow(
            'Pickup Time',
            '${pickupTime.day}/${pickupTime.month}/${pickupTime.year} at ${pickupTime.hour.toString().padLeft(2, '0')}:${pickupTime.minute.toString().padLeft(2, '0')}',
          ),
          const SizedBox(height: 8),
          _buildRow(
            'Return Due',
            '${returnTime.day}/${returnTime.month}/${returnTime.year} at ${returnTime.hour.toString().padLeft(2, '0')}:${returnTime.minute.toString().padLeft(2, '0')}',
          ),
          const Divider(height: 24),
          _buildRow('Total Rental Fare', 'Rs. $totalAmount', isBold: true),
          const SizedBox(height: 8),
          _buildRow(
            'Advance Payable',
            'Rs. $advanceRequired',
            color: AppColors.sunsetOrange,
            isBold: true,
          ),
          const SizedBox(height: 8),
          _buildRow(
            'Balance at Handover',
            'Rs. ${totalAmount - advanceRequired}',
            color: AppColors.midnightNavy,
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value,
      {bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isBold ? AppColors.midnightNavy : AppColors.textSecondary,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            color: color ?? AppColors.midnightNavy,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
