import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../l10n/app_localizations.dart';

class PakistanPhoneField extends StatelessWidget {
  final TextEditingController controller;
  final String? errorMessage;
  final ValueChanged<String>? onChanged;

  const PakistanPhoneField({
    super.key,
    required this.controller,
    this.errorMessage,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.onboardingWhatsappNumber,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          onChanged: onChanged,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: '3XX XXXXXXX',
            hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '🇵🇰 +92',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 1,
                    height: 20,
                    color: scheme.outlineVariant,
                  ),
                ],
              ),
            ),
            suffixIcon: Icon(
              Icons.chat_outlined,
              size: 19,
              color: scheme.onSurfaceVariant,
            ),
            filled: true,
            fillColor: scheme.surfaceContainerHighest,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).dividerColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: errorMessage != null ? AppColors.accentDanger : Theme.of(context).dividerColor,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: errorMessage != null
                    ? AppColors.dangerTextFor(Theme.of(context).brightness)
                    : AppColors.secondary,
                width: 1.5,
              ),
            ),
          ),
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 5),
          Text(
            errorMessage!,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.dangerTextFor(Theme.of(context).brightness),
            ),
          ),
        ],
      ],
    );
  }
}

