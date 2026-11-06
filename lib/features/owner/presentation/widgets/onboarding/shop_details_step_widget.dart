import 'dart:io';
import 'package:flutter/material.dart';
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
                  color: AppColors.backgroundLight,
                  border: Border.all(color: AppColors.sunsetOrange, width: 2),
                ),
                child: ClipOval(
                  child: shopLogoFile != null
                      ? Image.file(File(shopLogoFile!.path), fit: BoxFit.cover)
                      : const Icon(Icons.storefront_rounded, size: 44, color: AppColors.sunsetOrange),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: InkWell(
                  onTap: onPickLogo,
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: const BoxDecoration(
                      color: AppColors.sunsetOrange,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
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
            icon: const Icon(Icons.upload_rounded, size: 16, color: AppColors.sunsetOrange),
            label: Text(
              shopLogoFile != null ? 'Change Shop Logo' : 'Upload Shop Logo / Storefront',
              style: const TextStyle(color: AppColors.sunsetOrange, fontWeight: FontWeight.w800, fontSize: 12),
            ),
          ),
        ),
        const SizedBox(height: 16),

        _inputField(
          context: context,
          label: 'Shop Registered Legal Name',
          controller: shopNameController,
          hint: 'e.g. Al-Falah Rent a Car',
          icon: Icons.business_rounded,
        ),
        const SizedBox(height: 14),

        _inputField(
          context: context,
          label: 'Owner Full Name (as on CNIC)',
          controller: ownerNameController,
          hint: 'e.g. Ahmed Raza',
          icon: Icons.person_rounded,
        ),
        const SizedBox(height: 14),

        _inputField(
          context: context,
          label: 'Owner CNIC Number',
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
                label: 'WhatsApp Business Number',
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
                label: 'Shop Landline / Alt Phone',
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
        const Text('Operating Hours', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.midnightNavy)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: openingHours,
              isExpanded: true,
              items: [
                '9:00 AM - 10:00 PM',
                '8:00 AM - Midnight',
                '24 Hours / 7 Days',
                '10:00 AM - 8:00 PM',
              ].map((h) => DropdownMenuItem(value: h, child: Text(h, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)))).toList(),
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
        Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppColors.sunsetOrange, size: 20),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            isDense: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.sunsetOrange, width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }
}

