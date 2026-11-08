import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';

class AuthStepperBar extends StatelessWidget {
  final int currentStep; // 1 or 2

  const AuthStepperBar({super.key, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      color: Theme.of(context).colorScheme.surface,
      child: Row(
        children: [
          Expanded(
            child: _stepPill(
              context,
              step: 1,
              title: '1. Profile Info',
              isDone: currentStep > 1,
              isCurrent: currentStep == 1,
              icon: Icons.person_rounded,
            ),
          ),
          Container(
            width: 20,
            height: 2,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            color: currentStep > 1 ? AppColors.accentSuccess : Theme.of(context).dividerColor,
          ),
          Expanded(
            child: _stepPill(
              context,
              step: 2,
              title: '2. Select Role',
              isDone: false,
              isCurrent: currentStep == 2,
              icon: Icons.verified_user_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepPill(
    BuildContext context, {
    required int step,
    required String title,
    required bool isDone,
    required bool isCurrent,
    required IconData icon,
  }) {
    final color = isDone
        ? AppColors.accentSuccess
        : isCurrent
            ? AppColors.secondary
            : Theme.of(context).colorScheme.onSurfaceVariant;

    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDone || isCurrent ? color : Theme.of(context).colorScheme.surfaceContainerHighest,
            border: Border.all(color: color, width: 1.5),
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check, size: 15, color: Colors.white)
                : Icon(
                    icon,
                    size: 13,
                    color: isCurrent ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
              color: isCurrent ? AppColors.primary : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

