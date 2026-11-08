import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../../l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/constants/app_colors.dart';

class ShopDetailsStepWidget extends StatelessWidget {
  final XFile? shopLogoFile;
  final VoidCallback onPickLogo;
  final TextEditingController shopNameController;
  final TextEditingController ownerNameController;
  final TextEditingController cnicController;
  final TextEditingController whatsappController;
  final TextEditingController phoneController;
  final String openingHours;
  final ValueChanged<String> onOpeningHoursChanged;

  const ShopDetailsStepWidget({
    super.key,
    required this.shopLogoFile,
    required this.onPickLogo,
    required this.shopNameController,
    required this.ownerNameController,
    required this.cnicController,
    required this.whatsappController,
    required this.phoneController,
    required this.openingHours,
    required this.onOpeningHoursChanged,
  });

  @override
  Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Shop Logo Upload Avatar
        Center(
          child: Stack(
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  border: Border.all(color: AppColors.secondary, width: 2),
                ),
                child: ClipOval(
                  child: shopLogoFile != null
                      ? Image.file(File(shopLogoFile!.path), fit: BoxFit.cover)
                      : const Icon(Icons.storefront_rounded, size: 44, color: AppColors.secondary),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                // Audit §1: the 30dp visual stays, but the InkWell hit
                // area is padded to the 48dp minimum (9dp each side).
                child: InkWell(
                  onTap: onPickLogo,
                  child: Padding(
                    padding: const EdgeInsets.all(9),
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: const BoxDecoration(
                        color: AppColors.secondary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: TextButton.icon(
            onPressed: onPickLogo,
            // Audit §1/C3: small orange text uses the brightness-aware
            // token (AppColors.secondary is ~3.2:1 at this size).
            icon: Icon(Icons.upload_rounded, size: 16, color: AppColors.orangeTextFor(Theme.of(context).brightness)),
            label: Text(
              shopLogoFile != null ? l10n.onboardingChangeLogo : l10n.onboardingUploadLogo,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.orangeTextFor(Theme.of(context).brightness), fontWeight: FontWeight.w800),
            ),
          ),
        ),
        const SizedBox(height: 16),

        _inputField(
          context: context,
          label: l10n.onboardingShopLegalName,
          controller: shopNameController,
          hint: l10n.onboardingShopNameHint,
          icon: Icons.business_rounded,
        ),
        const SizedBox(height: 14),

        _inputField(
          context: context,
          label: l10n.onboardingOwnerName,
          controller: ownerNameController,
          hint: l10n.onboardingOwnerNameHint,
          icon: Icons.person_rounded,
        ),
        const SizedBox(height: 14),

        _inputField(
          context: context,
          label: l10n.onboardingOwnerCnic,
          controller: cnicController,
          hint: '35201-9876543-1',
          icon: Icons.credit_card_rounded,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 14),

        Row(
          children: [
            Expanded(
              child: _inputField(
                context: context,
                label: l10n.onboardingWhatsappBusinessNumber,
                controller: whatsappController,
                hint: '03001234567',
                icon: Icons.chat_rounded,
                keyboardType: TextInputType.phone,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _inputField(
                context: context,
                label: l10n.onboardingShopPhone,
                controller: phoneController,
                hint: '04235761234',
                icon: Icons.phone_rounded,
                keyboardType: TextInputType.phone,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Opening Hours Dropdown
        Text(l10n.onboardingOperatingHours, style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              dropdownColor: Theme.of(context).colorScheme.surface,
              value: openingHours,
              isExpanded: true,
              items: [
                '9:00 AM - 10:00 PM',
                '8:00 AM - Midnight',
                '24 Hours / 7 Days',
                '10:00 AM - 8:00 PM',
              ].map((h) => DropdownMenuItem(value: h, child: Text(_hoursLabel(l10n, h), style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)))).toList(),
              onChanged: (v) {
                if (v != null) onOpeningHoursChanged(v);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _inputField({
    required BuildContext context,
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppColors.secondary, size: 20),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            isDense: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).dividerColor)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).dividerColor)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.secondary, width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }
}


/// Stored opening-hours codes mapped to localized labels — the stored
/// value itself is never changed.
String _hoursLabel(AppLocalizations l10n, String h) => {'9:00 AM - 10:00 PM': l10n.onboardingHours9to10, '8:00 AM - Midnight': l10n.onboardingHours8toMidnight, '24 Hours / 7 Days': l10n.onboardingHours24x7, '10:00 AM - 8:00 PM': l10n.onboardingHours10to8}[h] ?? h;
