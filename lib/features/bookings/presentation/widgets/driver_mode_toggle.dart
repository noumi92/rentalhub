import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';

class DriverModeToggle extends StatelessWidget {
  final bool isWithDriver;
  final ValueChanged<bool> onChanged;

  const DriverModeToggle({
    super.key,
    required this.isWithDriver,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildOption(context, 
              label: l10n.selfDrive,
              sublabel: l10n.driverRequiresCnic,
              icon: Icons.directions_car_filled_rounded,
              isSelected: !isWithDriver,
              onTap: () => onChanged(false),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildOption(context, 
              label: l10n.withChauffeur,
              sublabel: l10n.driverVerifiedIncluded,
              icon: Icons.person_pin_circle_rounded,
              isSelected: isWithDriver,
              onTap: () => onChanged(true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOption(BuildContext context, {
    required String label,
    required String sublabel,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          // CU-M4: the selected option used a hardcoded light
          // surface — it now follows the theme (the container is
          // surfaceContainerHighest, so the selected option lifts
          // on plain surface).
          color: isSelected
              ? Theme.of(context).colorScheme.surface
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 17,
                  color: isSelected
                      ? AppColors.secondary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    // CU-m1: the old AppColors.primary (navy) is
                    // unreadable on a dark surface — theme text now.
                    color: isSelected
                        ? Theme.of(context).colorScheme.onSurface
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              sublabel,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: isSelected
                    ? Theme.of(context).colorScheme.onSurface
                    : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

