import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/widgets/app_feedback.dart';
import '../../../../l10n/app_localizations.dart';

/// §17: the camera failure state for the QR scanner. A denied /
/// unavailable camera used to render a black box with no explanation
/// and no path forward. The manual entry below stays visible as the
/// fallback; the "Open settings" action is only offered where an
/// already-present dependency supports it — `url_launcher` opens the
/// `app-settings:` URL on iOS. Android has no equivalent here (no new
/// package may be added), so Android shows guidance text with no
/// button instead of a dead one.
class QrCameraErrorState extends StatelessWidget {
  const QrCameraErrorState({super.key, required this.error});

  final MobileScannerException error;

  Future<void> _openSettings(BuildContext context) async {
    final launched = await launchUrl(Uri.parse('app-settings:'));
    if (!launched && context.mounted) {
      AppFeedback.showError(context,
          AppLocalizations.of(context)!.qrCameraSettingsError);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDenied =
        error.errorCode == MobileScannerErrorCode.permissionDenied;
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.no_photography_rounded,
              size: 44,
              color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(
            isDenied
                ? l10n.qrCameraDenied
                : l10n.qrCameraUnavailable(error.errorCode.message),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            isDenied
                ? l10n.qrCameraDeniedHint
                : l10n.qrCameraUnavailableHint,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (isDenied && Platform.isIOS) ...[
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: () => _openSettings(context),
              icon: const Icon(Icons.settings_rounded, size: 18),
              label: Text(l10n.qrScanOpenSettings),
            ),
          ],
        ],
      ),
    );
  }
}
