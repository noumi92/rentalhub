import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';

class DualSignaturePadWidget extends StatelessWidget {
  final bool customerSigned;
  final bool ownerSigned;
  final VoidCallback onCustomerSign;
  final VoidCallback onOwnerSign;

  const DualSignaturePadWidget({
    super.key,
    required this.customerSigned,
    required this.ownerSigned,
    required this.onCustomerSign,
    required this.onOwnerSign,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dual Legal Endorsement & Signatures',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.midnightNavy),
          ),
          const SizedBox(height: 12),
          _signatureTile(
            title: 'Customer / Hirer Digital Signature',
            subtitle: 'Certifies physical receipt of car & documents',
            isSigned: customerSigned,
            onSign: onCustomerSign,
          ),
          const SizedBox(height: 12),
          _signatureTile(
            title: 'Showroom Host / Manager Signature',
            subtitle: 'Authorized release by showroom representative',
            isSigned: ownerSigned,
            onSign: onOwnerSign,
          ),
        ],
      ),
    );
  }

  Widget _signatureTile({
    required String title,
    required String subtitle,
    required bool isSigned,
    required VoidCallback onSign,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isSigned ? AppColors.emeraldGreen : AppColors.border),
      ),
      child: Row(
        children: [
          Icon(
            isSigned ? Icons.check_circle_rounded : Icons.draw_rounded,
            color: isSigned ? AppColors.emeraldGreen : AppColors.sunsetOrange,
            size: 26,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.midnightNavy),
                ),
                Text(
                  isSigned ? 'Vector Signature Captured (SHA-256)' : subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: isSigned ? AppColors.emeraldGreen : AppColors.textSecondary,
                    fontWeight: isSigned ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onSign,
            child: Text(
              isSigned ? 'Resign' : 'Sign Now',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: isSigned ? AppColors.textSecondary : AppColors.sunsetOrange,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
