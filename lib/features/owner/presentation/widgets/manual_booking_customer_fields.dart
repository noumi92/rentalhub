import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';

/// The customer KYC fields of the walk-in booking wizard: name,
/// phone and CNIC. Extracted from [OwnerManualBookingView] so the
/// view stays under the 250-line cap.
class ManualBookingCustomerFields extends StatelessWidget {
  const ManualBookingCustomerFields({
    super.key,
    required this.nameController,
    required this.phoneController,
    required this.cnicController,
  });

  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController cnicController;

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboard = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.midnightNavy, size: 20),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _inputField(
            controller: nameController,
            label: 'Customer Full Name',
            icon: Icons.person_rounded),
        const SizedBox(height: 10),
        _inputField(
            controller: phoneController,
            label: 'Phone Number',
            icon: Icons.phone_rounded,
            keyboard: TextInputType.phone),
        const SizedBox(height: 10),
        _inputField(
            controller: cnicController,
            label: 'NADRA CNIC',
            icon: Icons.badge_rounded,
            keyboard: TextInputType.number),
      ],
    );
  }
}
