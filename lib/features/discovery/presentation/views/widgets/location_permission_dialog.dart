import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../l10n/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context)!;
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(22),
        // Scrollable content: at 360px with Urdu labels and a large
        // text scale the title + explainer + two 48dp buttons are
        // taller than the viewport, and the plain Column overflowed
        // by 38px. At default scale nothing changes visually.
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_on_rounded,
                color: AppColors.secondary,
                size: 34,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.locationEnablePrecise,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.locationPermissionExplainer,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.4),
            ),
            const SizedBox(height: 22),
            ElevatedButton.icon(
              onPressed: onAllow,
              style: ElevatedButton.styleFrom(
                // White on AppColors.secondary (#F95700) is 3.29:1
                // and fails WCAG AA for the 14sp label; orangeFill
                // (#C2410C) is 5.18:1. minimumSize (not a fixed
                // 48dp SizedBox) lets the Urdu label wrap to two
                // lines at large text scale instead of clipping.
                backgroundColor: AppColors.orangeFill,
                foregroundColor: AppColors.surfaceLight,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.my_location_rounded, size: 18),
              label: Text(
                l10n.locationAllowWhileUsing,
                maxLines: 2,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: onManualCity,
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.onSurface,
                side: BorderSide(color: Theme.of(context).dividerColor),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                l10n.locationSelectCityManually,
                maxLines: 2,
                textAlign: TextAlign.center,
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }
}

