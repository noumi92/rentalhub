import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/debounced_button.dart';

/// The Confirm / Reject action pair at the foot of
/// [OwnerPaymentVerificationView], extracted so the view stays under
/// the 250-line cap. Labels come from the caller (they embed the
/// verified amount); this widget only owns the layout and the
/// processing state.
class PaymentVerificationActions extends StatelessWidget {
  const PaymentVerificationActions({
    super.key,
    required this.processing,
    required this.confirmLabel,
    required this.rejectLabel,
    required this.onConfirm,
    required this.onReject,
  });

  final bool processing;
  final String confirmLabel;
  final String rejectLabel;
  final VoidCallback onConfirm;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: DebouncedButton(
            text: confirmLabel,
            icon: Icons.check_circle_rounded,
            isLoading: processing,
            onPressed: onConfirm,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: processing ? null : onReject,
            icon: Icon(Icons.close_rounded,
                color: AppColors.dangerTextFor(
                    Theme.of(context).brightness)),
            label: Text(rejectLabel,
                style: TextStyle(
                    color: AppColors.dangerTextFor(
                        Theme.of(context).brightness))),
          ),
        ),
      ],
    );
  }
}
