import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../blacklist/domain/entities/blacklist_entity.dart';

class BlacklistStatusBanner extends StatelessWidget {
  final bool isChecked;
  final BlacklistEntity? blacklistedRecord;
  final VoidCallback? onProceed;
  final VoidCallback? onDecline;

  const BlacklistStatusBanner({
    super.key,
    required this.isChecked,
    this.blacklistedRecord,
    this.onProceed,
    this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    if (!isChecked) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.lavenderMist.withAlpha(50),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: const Row(
          children: [
            Icon(Icons.shield_outlined, color: AppColors.textMuted, size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Enter CNIC above to run an instant real-time scan against the National Car Rental Fraud & Blacklist Database.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
              ),
            ),
          ],
        ),
      );
    }

    final isBlacklisted = blacklistedRecord != null;

    if (isBlacklisted) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF0F0),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.shade400, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.dangerous_rounded, color: Colors.red, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CRITICAL ALERT: BLACKLISTED CITIZEN',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.red),
                      ),
                      Text(
                        'Incident Ref: ${blacklistedRecord!.blacklistId}',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.red.shade900),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Reason: ${blacklistedRecord!.reasonCategory}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.black87)),
                  const SizedBox(height: 4),
                  Text(blacklistedRecord!.description, style: const TextStyle(fontSize: 11.5, color: Colors.black54)),
                  const SizedBox(height: 4),
                  Text('Reported By: ${blacklistedRecord!.reportedByShopId}', style: TextStyle(fontSize: 10.5, fontStyle: FontStyle.italic, color: Colors.red.shade700)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: onDecline,
                icon: const Icon(Icons.block, size: 18),
                label: const Text('Decline / Refuse Service', style: TextStyle(fontWeight: FontWeight.w800)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Clean Record
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FFF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade400, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CLEAN NADRA RECORD VERIFIED',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.green),
                    ),
                    Text(
                      'Zero active defaults or tribunal complaints on file.',
                      style: TextStyle(fontSize: 11, color: Colors.green),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: onProceed,
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: const Text('Proceed to Walk-in Booking Wizard', style: TextStyle(fontWeight: FontWeight.w800)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.sunsetOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
