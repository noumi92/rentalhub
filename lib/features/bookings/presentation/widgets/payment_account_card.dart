import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_feedback.dart';

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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
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
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: AppColors.primary),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.copy_rounded,
                    size: 19, color: AppColors.primary),
                tooltip: 'Copy Number',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: iban ?? accountNumber));
                  AppFeedback.showSuccess(
                      context, '$methodTitle account copied to clipboard');
                },
              ),
            ],
          ),
          const Divider(height: 18),
          _buildInfoRow('Account Title', accountTitle),
          const SizedBox(height: 6),
          _buildInfoRow('Account / Mobile', accountNumber),
          if (iban != null && iban!.isNotEmpty) ...[
            const SizedBox(height: 6),
            _buildInfoRow('IBAN Number', iban!),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}

