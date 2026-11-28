import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';

/// The 4-step progress header of the Add/Edit Customer wizard
/// (extracted from [OwnerAddCustomerWizard] so the shell stays
/// under the 250-line cap): numbered circles + labels with a
/// connector line between steps, green once the step on its left
/// is done.
class KycStepperHeader extends StatelessWidget {
  const KycStepperHeader({
    super.key,
    required this.step,
    required this.labels,
  });

  final int step;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('kyc-stepper-header'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            Expanded(child: _stepItem(context, i, labels[i])),
            if (i < labels.length - 1) _stepConnector(context, i),
          ],
        ],
      ),
    );
  }

  Widget _stepItem(BuildContext context, int index, String label) {
    final done = index < step;
    final current = index == step;
    final color = done
        ? AppColors.accentSuccessStrong
        : current
            ? AppColors.orangeFill
            : Theme.of(context).colorScheme.onSurfaceVariant;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done || current
                ? color
                : Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          child: Center(
            child: done
                ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                : Text('${index + 1}',
                    // Audit 2026-11-15 DS-8: 13 sp is bodyMedium, not a literal.
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: current ? Colors.white : color)),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          // Urdu step labels need two lines at 360px — one line
          // truncated them with an ellipsis.
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          // Audit 2026-11-15 DS-8: 11 sp w500 is labelSmall — read
          // the theme slot instead of a hardcoded size. Done and
          // current labels read semibold so the progress stands out
          // against the grey upcoming steps.
          style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: done || current ? FontWeight.w600 : FontWeight.w500, color: color),
        ),
      ],
    );
  }

  /// Connector line between two steps, centred on the 28px circles
  /// (the box is the circle height, so the 2px line sits at the
  /// circle centre). Green once the step on its left is done — the
  /// line into the current step stays grey until that step is
  /// completed — grey for the road ahead.
  Widget _stepConnector(BuildContext context, int leftIndex) {
    final passed = leftIndex < step;
    return Container(
      width: 24,
      height: 28,
      alignment: Alignment.center,
      child: Container(
        height: 2,
        decoration: BoxDecoration(color: passed ? AppColors.accentSuccessStrong : Theme.of(context).dividerColor, borderRadius: BorderRadius.circular(1)),
      ),
    );
  }
}
