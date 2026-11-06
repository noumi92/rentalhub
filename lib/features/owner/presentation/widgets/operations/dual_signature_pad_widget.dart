import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

import '../../../../../core/constants/app_colors.dart';

/// Phase B (E2): two real signature pads. The caller owns the
/// controllers and exports the PNG bytes at handover time — the old
/// version only toggled a boolean and passed a hardcoded SVG string,
/// so no signature ever existed.
class DualSignaturePadWidget extends StatelessWidget {
  final SignatureController customerController;
  final SignatureController ownerController;

  const DualSignaturePadWidget({
    super.key,
    required this.customerController,
    required this.ownerController,
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
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.midnightNavy),
          ),
          const SizedBox(height: 12),
          _pad(
            title: 'Customer / Hirer Digital Signature',
            subtitle: 'Certifies physical receipt of car & documents',
            controller: customerController,
          ),
          const SizedBox(height: 12),
          _pad(
            title: 'Showroom Host / Manager Signature',
            subtitle: 'Authorized release by showroom representative',
            controller: ownerController,
          ),
        ],
      ),
    );
  }

  Widget _pad({
    required String title,
    required String subtitle,
    required SignatureController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: AppColors.midnightNavy)),
        Text(subtitle,
            style: const TextStyle(
                fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        Container(
          height: 120,
          decoration: BoxDecoration(
            color: AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Signature(
              controller: controller,
              backgroundColor: Colors.white,
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: controller.clear,
            icon: const Icon(Icons.clear_rounded, size: 16),
            label: const Text('Clear'),
          ),
        ),
      ],
    );
  }
}
