import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import 'admin_settings_field.dart';

/// The settings form (fields, toggles, Save button), extracted from
/// [AdminPlatformSettingsView] so the view stays under the 250-line
/// cap. The APK download card stays in the view, below this form.
class AdminPlatformSettingsForm extends StatelessWidget {
  const AdminPlatformSettingsForm({
    super.key,
    required this.citiesController,
    required this.categoriesController,
    required this.advanceController,
    required this.depositController,
    required this.graceController,
    required this.hoursController,
    required this.termsController,
    required this.maintenanceMode,
    required this.displayUnverifiedShops,
    required this.allowBookingsFromUnverifiedShops,
    required this.isSaving,
    required this.onMaintenanceChanged,
    required this.onDisplayChanged,
    required this.onAllowChanged,
    required this.onSave,
  });

  final TextEditingController citiesController;
  final TextEditingController categoriesController;
  final TextEditingController advanceController;
  final TextEditingController depositController;
  final TextEditingController graceController;
  final TextEditingController hoursController;
  final TextEditingController termsController;
  final bool maintenanceMode;
  final bool displayUnverifiedShops;
  final bool allowBookingsFromUnverifiedShops;
  final bool isSaving;
  final ValueChanged<bool> onMaintenanceChanged;
  final ValueChanged<bool> onDisplayChanged;
  final ValueChanged<bool> onAllowChanged;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    // The admin panel pumps without localizations delegates in
    // tests, so every toggle label falls back to English.
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminSettingsField(
            label: 'Live cities (comma-separated)',
            controller: citiesController),
        AdminSettingsField(
            label: 'Car categories (comma-separated)',
            controller: categoriesController),
        AdminSettingsField(
            label: 'Advance %',
            controller: advanceController,
            keyboardType: TextInputType.number,
            digitsOnly: true),
        AdminSettingsField(
            label: 'Default deposit (Rs.)',
            controller: depositController,
            keyboardType: TextInputType.number,
            digitsOnly: true),
        AdminSettingsField(
            label: 'Late grace (minutes)',
            controller: graceController,
            keyboardType: TextInputType.number,
            digitsOnly: true),
        AdminSettingsField(
            label: 'Support hours', controller: hoursController),
        AdminSettingsField(
            label: 'Default agreement terms',
            controller: termsController,
            maxLines: 3),
        SwitchListTile(
          title: const Text('Maintenance mode'),
          subtitle:
              const Text('When on, the app shows a maintenance notice.'),
          value: maintenanceMode,
          onChanged: onMaintenanceChanged,
        ),
        SwitchListTile(
          title: Text(l10n?.admin2_displayUnverifiedShops ??
              'Display unverified shops'),
          subtitle: Text(l10n?.admin2_displayUnverifiedShopsHint ??
              'When off, unverified shops are hidden from the Shops tab.'),
          value: displayUnverifiedShops,
          onChanged: onDisplayChanged,
        ),
        SwitchListTile(
          title: Text(l10n?.admin2_allowBookingsFromUnverifiedShops ??
              'Allow bookings from unverified shops'),
          subtitle: Text(
              l10n?.admin2_allowBookingsFromUnverifiedShopsHint ??
                  'When off, customers cannot book from unverified shops.'),
          value: allowBookingsFromUnverifiedShops,
          onChanged: onAllowChanged,
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: isSaving ? null : onSave,
            style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
            child: isSaving
                ? const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child:
                            CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 10),
                      Text('Saving…'),
                    ],
                  )
                : const Text('Save settings'),
          ),
        ),
      ],
    );
  }
}
