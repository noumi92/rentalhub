import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/utils/whatsapp.dart';
import '../../../../../core/widgets/app_feedback.dart';
import '../../../../../core/widgets/debounced_button.dart';
import '../../../../fleet/domain/entities/vehicle_entity.dart';
import '../../../../../l10n/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context)!;
    final v = vehicle;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
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
                message: l10n.vehicleWhatsappInterest(shopName, v.displayName, v.plateNumber),
              );
              if (uri == null) {
                AppFeedback.showInfo(
                  context,
                  l10n.shopNoWhatsapp,
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
                    l10n.couldNotOpenWhatsapp,
                  );
                }
              }
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.successOnContainerFor(Theme.of(context).brightness),
              side: BorderSide(color: AppColors.successBorderFor(Theme.of(context).brightness)),
              backgroundColor: AppColors.successContainerFor(Theme.of(context).brightness),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            icon: Icon(Icons.chat_bubble_outline_rounded,
                size: 18, color: AppColors.successOnContainerFor(Theme.of(context).brightness)),
            label:  Text(l10n.whatsapp,
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: DebouncedButton(
              text: l10n.bookNowWithRate(selectedRate),
              icon: Icons.check_circle_outline_rounded,
              onPressed: () async {
                if (onBookNow != null) {
                  onBookNow!.call();
                } else {
                  AppFeedback.showInfo(
                    context,
                    l10n.vehicleSelectedMode(withDriver ? l10n.withChauffeur : l10n.selfDriveHyphen),
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
