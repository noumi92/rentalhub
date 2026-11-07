import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/utils/whatsapp.dart';
import '../../../../../core/widgets/app_feedback.dart';
import '../../../../../core/widgets/debounced_button.dart';
import '../../../../fleet/domain/entities/vehicle_entity.dart';

/// Phase A (A1): the bottom action bar of the car detail screen —
/// WhatsApp the shop + Book Now — extracted so the view stays under the
/// 250-line cap.
class VehicleDetailActionBar extends StatelessWidget {
  const VehicleDetailActionBar({
    super.key,
    required this.vehicle,
    required this.shopName,
    required this.shopPhone,
    required this.selectedRate,
    required this.withDriver,
    this.onBookNow,
  });

  final VehicleEntity vehicle;
  final String shopName;
  final String shopPhone;
  final int selectedRate;
  final bool withDriver;
  final VoidCallback? onBookNow;

  @override
  Widget build(BuildContext context) {
    final v = vehicle;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Color(0x14000000), blurRadius: 10, offset: Offset(0, -3))
        ],
      ),
      child: Row(
        children: [
          OutlinedButton.icon(
            onPressed: () async {
              final uri = whatsappUri(
                phone: shopPhone,
                message: 'Hi $shopName, I am interested in the '
                    '${v.displayName} (${v.plateNumber}) on RentalHub.',
              );
              if (uri == null) {
                AppFeedback.showInfo(
                  context,
                  'This shop has no WhatsApp number listed.',
                );
                return;
              }
              if (!await launchUrl(
                uri,
                mode: LaunchMode.externalApplication,
              )) {
                if (context.mounted) {
                  AppFeedback.showError(
                    context,
                    'Could not open WhatsApp.',
                  );
                }
              }
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.accentSuccess,
              side: const BorderSide(color: Color(0xFF86EFAC)),
              backgroundColor: const Color(0xFFF0FDF4),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.chat_bubble_outline_rounded,
                size: 18, color: AppColors.accentSuccess),
            label: const Text('WhatsApp',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: DebouncedButton(
              text: 'Book Now (Rs. $selectedRate)',
              icon: Icons.check_circle_outline_rounded,
              onPressed: () async {
                if (onBookNow != null) {
                  onBookNow!.call();
                } else {
                  AppFeedback.showInfo(
                    context,
                    'Selected: ${withDriver ? "With Chauffeur" : "Self-Drive"}. Advance deposit required.',
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
