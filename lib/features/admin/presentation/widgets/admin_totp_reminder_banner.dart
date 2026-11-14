import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// The 2FA-off reminder banner on the admin sign-in screen (F-m4):
/// a super admin asked this admin to turn on two-factor
/// authentication (`admin_totp_reminders/{uid}`), so the TOTP step
/// says so instead of silently offering enrolment again. The banner
/// stays until TOTP is actually enabled.
class AdminTotpReminderBanner extends StatelessWidget {
  const AdminTotpReminderBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_outlined, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n?.admin2_totpReminderLogin ??
                  'A super admin asked you to turn on two-factor authentication.',
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
