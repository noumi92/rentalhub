import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

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
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildOption(
              label: 'Self Drive',
              sublabel: 'Requires CNIC + Deposit',
              icon: Icons.directions_car_filled_rounded,
              isSelected: !isWithDriver,
              onTap: () => onChanged(false),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildOption(
              label: 'With Chauffeur',
              sublabel: 'Verified Driver Included',
              icon: Icons.person_pin_circle_rounded,
              isSelected: isWithDriver,
              onTap: () => onChanged(true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOption({
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
          color: isSelected ? Colors.white : Colors.transparent,
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
                      ? AppColors.sunsetOrange
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected
                        ? AppColors.midnightNavy
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              sublabel,
              style: TextStyle(
                fontSize: 10,
                color: isSelected
                    ? AppColors.textPrimary
                    : AppColors.textSecondary.withValues(alpha: 0.7),
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

