import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/debounced_button.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../core/theme/card_decoration.dart';

class CnicScannerInputWidget extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onVerify;
  final VoidCallback onCameraScan;
  final bool isVerifying;

  /// Audit §19: inline field error for a <13-digit CNIC (was
  /// snackbar-only). Cleared by the owner via [onCnicChanged].
  final String? errorText;
  final ValueChanged<String>? onCnicChanged;

  const CnicScannerInputWidget({
    super.key,
    required this.controller,
    required this.onVerify,
    required this.onCameraScan,
    this.isVerifying = false,
    this.errorText,
    this.onCnicChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Phase F: the widget copy is localized (English fallback for
    // delegate-less pumps). The CNIC hint is a format example, not
    // prose, and stays as-is.
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppCardDecoration.shadow(context)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n?.cnicVerifyTitle ?? 'CNIC Check',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              IconButton(
                icon: const Icon(Icons.qr_code_scanner_rounded,
                    color: AppColors.secondary),
                tooltip: l10n?.cnicScanTooltip ?? 'Scan CNIC / Barcode',
                onPressed: onCameraScan,
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            onChanged: onCnicChanged,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9\-]')),
              LengthLimitingTextInputFormatter(15),
            ],
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
            decoration: InputDecoration(
              hintText: '35201-1234567-1',
              hintStyle: TextStyle(
                  letterSpacing: 1.0,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
              prefixIcon: const Icon(Icons.badge_rounded),
              suffixIcon: controller.text.isNotEmpty
                  ? IconButton(
                      tooltip: l10n?.handoverClear ?? 'Clear',
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => controller.clear(),
                    )
                  : null,
              errorText: errorText,
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Theme.of(context).dividerColor),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          ),
          const SizedBox(height: 12),
          // Audit §19/C7: 54dp DebouncedButton (was a 46dp
          // ElevatedButton). The navy fill is unchanged.
          DebouncedButton(
            text: isVerifying
                ? l10n?.cnicChecking ?? 'Checking RentalHub blacklist...'
                : l10n?.cnicVerifyButton ?? 'Verify CNIC & Blacklist',
            icon: isVerifying ? null : Icons.verified_user_rounded,
            isLoading: isVerifying,
            backgroundColor: AppColors.primary,
            onPressed: onVerify,
          ),
        ],
      ),
    );
  }
}
