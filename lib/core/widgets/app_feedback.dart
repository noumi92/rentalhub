import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../../l10n/app_localizations.dart';

/// Unified alert, notification, and dialog feedback system for RentalHub.
class AppFeedback {
  AppFeedback._();

  /// Displays an Emerald Green success alert banner.
  static void showSuccess(BuildContext context, String message) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    _showSnackBar(
      context: context,
      message: message,
      // Dark-mode snackbars use the dark container tones: the light
      // status colour with white text is ~2.9:1, and the lighter dark
      // accent token as a background would drop it to ~2.2:1.
      // Audit SH-M2: light mode was white on `accentSuccess` #10B981
      // (2.54:1 — fails AA for the 13 sp w700 text). Light now uses
      // `accentSuccessStrong` #047857 (5.48:1 with white).
      backgroundColor:
          dark ? AppColors.successContainerDark : AppColors.accentSuccessStrong,
      foregroundColor:
          dark ? AppColors.successOnContainerDark : Colors.white,
      icon: Icons.check_circle_rounded,
    );
  }

  /// Displays a Crimson Red error alert banner.
  static void showError(BuildContext context, String message) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    _showSnackBar(
      context: context,
      message: message,
      // Audit SH-M2: light mode was white on `accentDanger` #EF4444
      // (3.76:1 — fails AA). Light now uses `errorDark` #DC2626
      // (4.83:1 with white).
      backgroundColor:
          dark ? AppColors.errorContainerDark : AppColors.errorDark,
      foregroundColor: dark ? AppColors.errorOnContainerDark : Colors.white,
      icon: Icons.error_outline_rounded,
    );
  }

  /// Displays a Sunset Orange warning alert banner.
  static void showWarning(BuildContext context, String message) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    _showSnackBar(
      context: context,
      message: message,
      // Audit SH-M2: light mode was white on `secondary` #F95700
      // (3.29:1 — fails AA). Light now uses `orangeFill` #C2410C
      // (5.18:1 with white).
      backgroundColor:
          dark ? AppColors.warningContainerDark : AppColors.orangeFill,
      foregroundColor:
          dark ? AppColors.warningOnContainerDark : Colors.white,
      icon: Icons.warning_amber_rounded,
    );
  }

  /// Displays a Midnight Navy informational alert banner.
  static void showInfo(BuildContext context, String message) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    _showSnackBar(
      context: context,
      message: message,
      backgroundColor:
          dark ? AppColors.primaryContainerOnDark : AppColors.primary,
      foregroundColor: Colors.white,
      icon: Icons.info_outline_rounded,
    );
  }

  static void _showSnackBar({
    required BuildContext context,
    required String message,
    required Color backgroundColor,
    required Color foregroundColor,
    required IconData icon,
    Duration duration = const Duration(seconds: 3),
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: foregroundColor, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: foregroundColor,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: duration,
      ),
    );
  }

  /// Displays a styled confirmation modal dialog for high-stakes irreversible actions
  /// (e.g. permanent role selection, vehicle deletion, or booking cancellations).
  static Future<bool> showConfirmDialog({
    required BuildContext context,
    required String title,
    required String message,
    String? confirmLabel,
    String? cancelLabel,
    bool isDestructive = false,
    IconData icon = Icons.security_rounded,
  }) async {
    // Phase F: the action labels default to the localized
    // 'Confirm'/'Cancel' (English fallback for delegate-less pumps).
    final l10n = AppLocalizations.of(context);
    final effectiveConfirmLabel =
        confirmLabel ?? l10n?.commonConfirm ?? 'Confirm';
    final effectiveCancelLabel =
        cancelLabel ?? l10n?.cancel ?? 'Cancel';
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (isDestructive ? AppColors.accentDanger : AppColors.secondary)
                    .withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isDestructive ? AppColors.accentDanger : AppColors.secondary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
            color: Theme.of(ctx).colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              effectiveCancelLabel,
              style: TextStyle(
                fontWeight: FontWeight.w400,
                color: Theme.of(ctx).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              // Audit SH-M2: the destructive confirm was white on
              // `accentDanger` #EF4444 (3.76:1 — fails AA). It now
              // uses `errorDark` #DC2626 (4.83:1 with white), the
              // same fill as the error snackbar.
              // Audit SH-N9: radius 16 (AppDimensions.buttonRadius);
              // no custom padding — the theme owns it.
              backgroundColor: isDestructive
                  ? AppColors.errorDark
                  : Theme.of(ctx).colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppDimensions.buttonRadius),
              ),
            ),
            child: Text(
              effectiveConfirmLabel,
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

