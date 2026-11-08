import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';

/// G2: the big red SOS button on the emergency screen. Extracted from
/// [CustomerSosView] so the view stays under the 250-line cap.
class SosButton extends StatelessWidget {
  const SosButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        color: AppColors.accentDanger.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        border: Border.all(
            color: AppColors.accentDanger.withValues(alpha: 0.3), width: 2),
      ),
      child: Center(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(55),
          child: Container(
            width: 110,
            height: 110,
            decoration: const BoxDecoration(
              color: AppColors.accentDanger,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0x66EF4444),
                  blurRadius: 18,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: Text(
                l10n.sos,
                style: Theme.of(context).textTheme.displayLarge?.copyWith(fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
