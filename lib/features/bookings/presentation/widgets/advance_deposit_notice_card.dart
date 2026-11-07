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
        color: AppColors.secondaryContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded,
                  color: AppColors.secondary, size: 18),
              SizedBox(width: 8),
              Text(
                'Advance & Verification Notice',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800, color: AppColors.secondary),
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
            style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.primary, height: 1.45),
          ),
        ],
      ),
    );
  }
}

