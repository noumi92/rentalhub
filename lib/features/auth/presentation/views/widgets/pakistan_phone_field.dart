import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';

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
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'WhatsApp Number',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          onChanged: onChanged,
          style: TextStyle(
            color: scheme.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: '3XX XXXXXXX',
            hintStyle:
                TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
            prefixIcon: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '🇵🇰 +92',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: scheme.onSurface,
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
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: errorMessage != null ? AppColors.error : AppColors.border,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: errorMessage != null
                    ? AppColors.error
                    : AppColors.sunsetOrange,
                width: 1.5,
              ),
            ),
          ),
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 5),
          Text(
            errorMessage!,
            style: const TextStyle(
              color: AppColors.error,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

