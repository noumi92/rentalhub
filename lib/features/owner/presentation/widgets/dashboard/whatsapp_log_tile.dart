import 'package:flutter/material.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/theme/card_decoration.dart';

class WhatsAppLogTile extends StatelessWidget {
  final String recipientName;
  final String phone;
  final String messageType;
  final String timestamp;
  final String status; // 'delivered', 'read', 'failed'
  final VoidCallback onResend;

  const WhatsAppLogTile({
    super.key,
    required this.recipientName,
    required this.phone,
    required this.messageType,
    required this.timestamp,
    required this.status,
    required this.onResend,
  });

  @override
  Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
    final brightness = Theme.of(context).brightness;
    Color statusColor;
    IconData statusIcon;
    switch (status.toLowerCase()) {
      case 'read':
        // Audit 2026-11-15 AC-7: raw Colors.blue #2196F3 was 3.12:1
        // in light mode — the readable navy / light-navy pair.
        statusColor = brightness == Brightness.dark
            ? AppColors.primaryFocusedOnDark
            : AppColors.primary;
        statusIcon = Icons.done_all_rounded;
        break;
      case 'delivered':
        // Audit 2026-11-15 AC-7: accentSuccess #10B981 was 2.54:1
        // in light mode — the readable success token.
        statusColor = AppColors.successTextFor(brightness);
        statusIcon = Icons.check_circle_rounded;
        break;
      default:
        // Audit 2026-11-15 AC-7: raw Colors.red #F44336 was 3.68:1
        // in light mode — the readable danger token.
        statusColor = AppColors.dangerTextFor(brightness);
        statusIcon = Icons.error_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppCardDecoration.shadow(context)
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            // Audit 2026-11-15 AC-7: the #25D366 brand glyph on a
            // 30-alpha tint was 1.98:1 in light mode — the readable
            // success green on its own tint instead.
            backgroundColor: AppColors.successTextFor(brightness).withValues(alpha: 0.12),
            child: Icon(Icons.chat_bubble_rounded, color: AppColors.successTextFor(brightness), size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(recipientName, style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(width: 6),
                    Text(phone, style: Theme.of(context).textTheme.labelSmall),
                  ],
                ),
                const SizedBox(height: 2),
                Text('$messageType • $timestamp', style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(statusIcon, size: 14, color: statusColor),
                  const SizedBox(width: 4),
                  Text(_statusLabel(l10n, status).toUpperCase(), style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w500, color: statusColor)),
                ],
              ),
              const SizedBox(height: 2),
              // Audit 2026-11-15 AC-7: "Resend" was a bare InkWell
              // around 11 sp text (~14 px tall) in raw secondary
              // (3.29:1 light / 2.81:1 dark) — a 48 dp TextButton in
              // the readable orange text token instead.
              TextButton(
                onPressed: onResend,
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: Text(l10n.whatsappLogsResend, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w500, color: AppColors.orangeTextFor(brightness))),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


/// Stored log-status codes mapped to localized labels — the stored
/// value itself is never changed.
String _statusLabel(AppLocalizations l10n, String status) => {'delivered': l10n.whatsappLogsDelivered, 'read': l10n.whatsappLogsRead, 'failed': l10n.whatsappLogsFailed}[status.toLowerCase()] ?? status;
