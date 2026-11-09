import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// Audit impl (O51): the add-staff dialog — name, phone, role and
/// the three permission toggles. Extracted from
/// [OwnerStaffRolesView] so the view stays under the 250-line cap.
/// Returns the entered values, or null when cancelled / no name.
Future<
    ({
      String name,
      String phone,
      String role,
      bool viewBookings,
      bool addCars,
      bool manageFinance,
    })?> showAddStaffDialog(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  var role = 'Manager';
  var viewBookings = true;
  var addCars = false;
  var manageFinance = false;
  final saved = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        title: Text(l10n.staffAddTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: InputDecoration(
                    labelText: l10n.staffNameLabel,
                    border: const OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                    labelText: l10n.staffPhoneLabel,
                    border: const OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: role,
                decoration: InputDecoration(
                    labelText: l10n.staffRoleLabel,
                    border: const OutlineInputBorder()),
                items: ['Manager', 'Driver', 'Accountant', 'Support']
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (v) =>
                    setDialogState(() => role = v ?? 'Manager'),
              ),
              SwitchListTile(
                title: Text(l10n.staffPermissionViewBookings),
                value: viewBookings,
                onChanged: (v) => setDialogState(() => viewBookings = v),
              ),
              SwitchListTile(
                title: Text(l10n.staffPermissionAddCars),
                value: addCars,
                onChanged: (v) => setDialogState(() => addCars = v),
              ),
              SwitchListTile(
                title: Text(l10n.staffPermissionManageFinance),
                value: manageFinance,
                onChanged: (v) => setDialogState(() => manageFinance = v),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.staffAdd),
          ),
        ],
      ),
    ),
  );
  final name = nameController.text.trim();
  final phone = phoneController.text.trim();
  nameController.dispose();
  phoneController.dispose();
  if (saved != true || name.isEmpty) return null;
  return (
    name: name,
    phone: phone,
    role: role,
    viewBookings: viewBookings,
    addCars: addCars,
    manageFinance: manageFinance,
  );
}
