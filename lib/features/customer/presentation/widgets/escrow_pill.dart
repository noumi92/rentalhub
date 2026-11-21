import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/masked_value.dart';

/// One pill inside the wallet's navy escrow header (Advances Paid /
/// Security Escrow). Extracted from [CustomerWalletView] so the view
/// stays under the 250-line cap.
class EscrowPill extends StatelessWidget {
  final String label;
  final String value;

  const EscrowPill({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.primaryContainer)),
          // CU-m6: the pill amounts stay masked but carry no eye of their own — the wallet header has ONE visibility toggle (on the main balance above), not three independent ones.
          Text(MaskedValue.maskDigits(value), maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w500, color: Colors.white)),
        ],
      ),
    );
  }
}
