import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// The CNIC back-QR number on the admin customer detail view.
///
/// Visibility rule (user, 2026-11-10): the QR number is visible ONLY
/// to a super admin, ONLY in the admin panel — never in the customer
/// or owner apps, never for operations/support. The widget renders
/// nothing at all unless [isSuperAdmin] is true and [qrCode] is
/// non-empty; the Firestore rules on `customer_qr_codes/{id}` are the
/// backstop (read: super admin only).
class AdminQrCodeRow extends StatelessWidget {
  const AdminQrCodeRow({
    super.key,
    required this.isSuperAdmin,
    required this.qrCode,
  });

  final bool isSuperAdmin;
  final String? qrCode;

  @override
  Widget build(BuildContext context) {
    final code = qrCode?.trim() ?? '';
    if (!isSuperAdmin || code.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        '${l10n?.kyc2_qrCode ?? 'QR Code'}: $code',
        style: const TextStyle(fontSize: 13),
      ),
    );
  }
}
