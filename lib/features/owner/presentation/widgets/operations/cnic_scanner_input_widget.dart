import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/constants/app_colors.dart';

class CnicScannerInputWidget extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onVerify;
  final VoidCallback onCameraScan;
  final bool isVerifying;

  const CnicScannerInputWidget({
    super.key,
    required this.controller,
    required this.onVerify,
    required this.onCameraScan,
    this.isVerifying = false,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'NADRA CNIC Verification',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.midnightNavy,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.sunsetOrange),
                tooltip: 'Scan CNIC / Barcode',
                onPressed: onCameraScan,
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9\-]')),
              LengthLimitingTextInputFormatter(15),
            ],
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: AppColors.midnightNavy,
            ),
            decoration: InputDecoration(
              hintText: '35201-1234567-1',
              hintStyle: const TextStyle(letterSpacing: 1.0, color: AppColors.textMuted),
              prefixIcon: const Icon(Icons.badge_rounded, color: AppColors.midnightNavy),
              suffixIcon: controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => controller.clear(),
                    )
                  : null,
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: isVerifying ? null : onVerify,
              icon: isVerifying
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.verified_user_rounded, size: 18),
              label: Text(
                isVerifying ? 'Checking National Tribunal...' : 'Verify CNIC & Blacklist',
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.midnightNavy,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

