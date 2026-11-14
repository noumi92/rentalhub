import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../l10n/app_localizations.dart';


/// The TOTP step of the admin login: either verifying the 6-digit code
/// from the admin's authenticator app (login), or enrolling for the
/// first time (scan the QR code, then enter the first code to confirm).
class AdminTotpStep extends StatelessWidget {
  const AdminTotpStep({
    super.key,
    required this.codeController,
    required this.isWorking,
    required this.error,
    required this.onVerify,
    this.otpauthUrl,
  });

  final TextEditingController codeController;
  final bool isWorking;
  final String? error;
  final VoidCallback onVerify;

  /// Set when enrolling: the otpauth:// URL returned once by the server.
  final String? otpauthUrl;

  String? get _manualKey {
    final url = otpauthUrl;
    if (url == null) return null;
    final uri = Uri.tryParse(url);
    return uri?.queryParameters['secret'];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final enrolling = otpauthUrl != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          enrolling
              ? l10n.admin2_totpSetupTitle
              : l10n.admin2_totpVerifyTitle,
          style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          enrolling
              ? l10n.admin2_totpSetupHint
              : l10n.admin2_totpEnabledHint,
          style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        if (enrolling) ...[
          const SizedBox(height: 16),
          Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                // AD-M4: a forced white slab behind the QR in both
                // modes — on a dark surface the black QR modules are
                // unscannable. Same pattern as the customer QR pass.
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: QrImageView(
                data: otpauthUrl!,
                size: 180,
                backgroundColor: Colors.white,
              ),
            ),
          ),
          if (_manualKey != null) ...[
            const SizedBox(height: 12),
            SelectableText(
              l10n.admin2_totpManualKey(_manualKey ?? ''),
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ],
        const SizedBox(height: 16),
        TextField(
          controller: codeController,
          keyboardType: TextInputType.number,
          // AD-m6: non-digits are rejected at the keyboard, not by
          // the length check after typing.
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          maxLength: 6,
          decoration: InputDecoration(
            hintText: l10n.admin2_totpCodeLabel,
            counterText: '',
            filled: true,
            fillColor:
                Theme.of(context).colorScheme.surfaceContainerHighest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).dividerColor),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 12),
          Text(error!,
              style: const TextStyle(
                  fontSize: 13,
                  color: Colors.red)),
        ],
        const SizedBox(height: 16),
        FilledButton(
          onPressed: isWorking ? null : onVerify,
          style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 48)),
          child: Text(isWorking
              ? l10n.admin2_totpChecking
              : enrolling
                  ? l10n.admin2_totpConfirmSetup
                  : l10n.admin2_totpVerifySignIn),
        ),
      ],
    );
  }
}
