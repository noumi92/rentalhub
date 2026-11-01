import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';

class LocationPermissionDialog extends StatelessWidget {
  final VoidCallback onAllow;
  final VoidCallback onManualCity;

  const LocationPermissionDialog({
    super.key,
    required this.onAllow,
    required this.onManualCity,
  });

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onAllow,
    required VoidCallback onManualCity,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => LocationPermissionDialog(
        onAllow: () {
          Navigator.of(ctx).pop();
          onAllow();
        },
        onManualCity: () {
          Navigator.of(ctx).pop();
          onManualCity();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.sunsetOrange.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_on_rounded,
                color: AppColors.sunsetOrange,
                size: 34,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Enable Precise Location',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.midnightNavy,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'RentalHub uses your real-time GPS coordinates to calculate road distances and discover verified rental showrooms within 1–5 km around you in Pakistan.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: onAllow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.sunsetOrange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.my_location_rounded, size: 18),
                label: const Text(
                  'Allow While Using App',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton(
                onPressed: onManualCity,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.midnightNavy,
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Select City Manually (Lahore)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

