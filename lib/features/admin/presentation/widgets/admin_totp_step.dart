import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';


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
    final enrolling = otpauthUrl != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          enrolling
              ? 'Set up two-factor authentication'
              : 'Enter your authenticator code',
          style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          enrolling
              ? 'Scan this code with your authenticator app, then enter the 6-digit code it shows to confirm.'
              : 'Two-factor authentication is on for this account. Enter the 6-digit code from your authenticator app.',
          style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        if (enrolling) ...[
          const SizedBox(height: 16),
          Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: QrImageView(data: otpauthUrl!, size: 180),
            ),
          ),
          if (_manualKey != null) ...[
            const SizedBox(height: 12),
            SelectableText(
              'Manual setup key: $_manualKey',
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
          maxLength: 6,
          decoration: InputDecoration(
            hintText: '6-digit code',
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
                  fontWeight: FontWeight.w700,
                  color: Colors.red)),
        ],
        const SizedBox(height: 16),
        FilledButton(
          onPressed: isWorking ? null : onVerify,
          child: Text(isWorking
              ? 'Checking…'
              : enrolling
                  ? 'Confirm and finish setup'
                  : 'Verify and sign in'),
        ),
      ],
    );
  }
}
