import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';

/// Tone-based info box for the Add Customer wizard (step 4).
///
/// The on-file box is the success tone, the KYC-complete box the
/// info tone. Colours come from theme tokens — never raw
/// `Colors.green` / `Colors.blue` (those glare in dark mode and
/// have no contrast story).
enum KycInfoTone { success, info }

class KycInfoBox extends StatelessWidget {
  final KycInfoTone tone;
  final IconData icon;
  final String text;

  const KycInfoBox({
    super.key,
    required this.tone,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final Color background;
    final Color foreground;
    switch (tone) {
      case KycInfoTone.success:
        background = AppColors.successContainerFor(brightness);
        // accentSuccessStrong on the light container is 5.48:1;
        // the dark variant is the light green on the dark container.
        foreground = brightness == Brightness.dark
            ? AppColors.accentSuccessDark
            : AppColors.accentSuccessStrong;
      case KycInfoTone.info:
        background = Theme.of(context).colorScheme.primaryContainer;
        foreground = Theme.of(context).colorScheme.primary;
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: foreground.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: foreground, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
