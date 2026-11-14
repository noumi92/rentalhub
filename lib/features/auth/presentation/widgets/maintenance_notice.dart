import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';

/// F-M13 (admin audit 2026-11-14): the visible effect of the
/// `maintenance_mode` toggle in platform settings. When
/// `platform_settings/global.maintenance_mode` is explicitly true,
/// the customer / owner app stops at the splash with this notice
/// instead of routing onward, with a retry that re-checks.
///
/// Extracted from [SplashView] so the view stays under the 250-line
/// rulebook cap: the notice is the whole branch, unchanged.
class MaintenanceNotice extends StatelessWidget {
  const MaintenanceNotice({
    super.key,
    required this.onRetry,
    this.isChecking = false,
  });

  /// Re-checks maintenance mode (the splash re-runs its check).
  final VoidCallback onRetry;

  /// While a re-check is in flight the retry button is disabled.
  final bool isChecking;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.splashGradientTop,
              AppColors.splashGradientMiddle,
              AppColors.splashGradientBottom,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.construction_rounded,
                  size: 56,
                  color: Colors.white,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n?.maintenanceTitle ?? 'RentalHub is under maintenance',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n?.maintenanceBody ??
                      'We are doing scheduled maintenance. Please try again in a little while.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(
                          color: Colors.white.withValues(alpha: 0.8)),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: isChecking ? null : onRetry,
                  style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 48)),
                  child: Text(l10n?.maintenanceRetry ?? 'Try again'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
