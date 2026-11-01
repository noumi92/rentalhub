import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class AdvanceDepositNoticeCard extends StatelessWidget {
  final bool isWithDriver;

  const AdvanceDepositNoticeCard({
    super.key,
    required this.isWithDriver,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.softOrangeTint,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.sunsetOrange.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.info_outline_rounded,
                  color: AppColors.sunsetOrange, size: 18),
              SizedBox(width: 8),
              Text(
                'Advance & Verification Notice',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.sunsetOrange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isWithDriver
                ? '• Chauffeur arrives at showroom/pickup point 15 mins early.\n'
                    '• Advance payment confirms vehicle lock and fuel reservation.\n'
                    '• Outstation overnight stay: Rs. 1,500/night driver food & lodge.'
                : '• Original NADRA CNIC & valid Driving License required at handover.\n'
                    '• Advance confirms vehicle booking lock with showroom.\n'
                    '• Refundable security deposit collected digitally or in cash at handover.',
            style: const TextStyle(
              fontSize: 12,
              height: 1.45,
              fontWeight: FontWeight.w500,
              color: AppColors.midnightNavy,
            ),
          ),
        ],
      ),
    );
  }
}

