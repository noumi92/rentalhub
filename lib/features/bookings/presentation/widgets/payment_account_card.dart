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
        border: Border.all(color: Theme.of(context).dividerColor),
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
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
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
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

