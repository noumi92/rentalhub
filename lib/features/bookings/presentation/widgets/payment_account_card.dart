import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../l10n/app_localizations.dart';

class PaymentAccountCard extends StatelessWidget {
  final String methodTitle;
  final String accountTitle;
  final String accountNumber;
  final String? iban;
  final Color brandColor;
  final IconData icon;

  const PaymentAccountCard({
    super.key,
    required this.methodTitle,
    required this.accountTitle,
    required this.accountNumber,
    this.iban,
    required this.brandColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: brandColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: brandColor, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    methodTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.copy_rounded,
                    size: 19),
                tooltip: l10n.paymentCopyNumber,
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: iban ?? accountNumber));
                  AppFeedback.showSuccess(
                      context, l10n.paymentCopied(methodTitle));
                },
              ),
            ],
          ),
          const Divider(height: 18),
          _buildInfoRow(context, l10n.paymentAccountTitle, accountTitle),
          const SizedBox(height: 6),
          _buildInfoRow(context, l10n.paymentAccountMobile, accountNumber),
          if (iban != null && iban!.isNotEmpty) ...[
            const SizedBox(height: 6),
            _buildInfoRow(context, l10n.paymentIban, iban!),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          // Audit 2026-11-15 DS-8: the 12 sp label is off-scale (§4.5:
          // 28/20/16/15/13/11) — labelSmall is the 11 sp slot.
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        Text(
          value,
          // Audit 2026-11-15 DS-8: 13 sp is bodyMedium, not a literal.
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

