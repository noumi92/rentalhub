import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/settings/app_settings_cubit.dart';
import '../../../../l10n/app_localizations.dart';
import 'admin_settings_draft.dart';
import 'admin_settings_field.dart';

/// The settings form (fields, toggles, Save button), extracted from
/// [AdminPlatformSettingsView] so the view stays under the 250-line
/// cap. The APK download card stays in the view, below this form.
///
/// The editable state lives in [AdminSettingsDraft]; the form
/// mutates the draft's toggles and calls [onChanged] so the view
/// rebuilds (dirty guard, toggle state). Range errors arrive via
/// [fieldErrors] (keys 'advance' | 'deposit' | 'grace', AD-M12).
/// [noDocument] shows the "no settings saved yet" banner (F-M12):
/// the fields show factory defaults, and Save creates the document.
class AdminPlatformSettingsForm extends StatelessWidget {
  const AdminPlatformSettingsForm({
    super.key,
    required this.draft,
    required this.isSaving,
    required this.noDocument,
    required this.fieldErrors,
    required this.onChanged,
    required this.onSave,
  });

  final AdminSettingsDraft draft;
  final bool isSaving;
  final bool noDocument;
  final Map<String, String> fieldErrors;
  final VoidCallback onChanged;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    // The admin panel pumps without localizations delegates in
    // tests, so every toggle label falls back to English.
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (noDocument)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n?.admin2_settingsNoDocument ??
                        'No platform settings saved yet — showing defaults. Save to create them.',
                  ),
                ),
              ],
            ),
          ),
        AdminSettingsField(
            label: l10n?.admin2_settingsCities ??
                'Live cities (comma-separated)',
            controller: draft.citiesController),
        AdminSettingsField(
            label: l10n?.admin2_settingsCategories ??
                'Car categories (comma-separated)',
            controller: draft.categoriesController),
        AdminSettingsField(
            label: l10n?.admin2_settingsAdvance ?? 'Advance %',
            controller: draft.advanceController,
            keyboardType: TextInputType.number,
            digitsOnly: true,
            errorText: fieldErrors['advance']),
        AdminSettingsField(
            label: l10n?.admin2_settingsDeposit ?? 'Default deposit (Rs.)',
            controller: draft.depositController,
            keyboardType: TextInputType.number,
            digitsOnly: true,
            errorText: fieldErrors['deposit']),
        AdminSettingsField(
            label: l10n?.admin2_settingsGrace ?? 'Late grace (minutes)',
            controller: draft.graceController,
            keyboardType: TextInputType.number,
            digitsOnly: true,
            errorText: fieldErrors['grace']),
        AdminSettingsField(
            label: l10n?.admin2_settingsSupportHours ?? 'Support hours',
            controller: draft.hoursController),
        AdminSettingsField(
            label: l10n?.admin2_settingsAgreementTerms ??
                'Default agreement terms',
            controller: draft.termsController,
            maxLines: 3),
        SwitchListTile(
          title: Text(l10n?.admin2_settingsMaintenance ?? 'Maintenance mode'),
          subtitle: Text(l10n?.admin2_settingsMaintenanceHint ??
              'When on, the app shows a maintenance notice at startup.'),
          value: draft.maintenanceMode,
          onChanged: (v) {
            draft.maintenanceMode = v;
            onChanged();
          },
        ),
        SwitchListTile(
          title: Text(l10n?.admin2_displayUnverifiedShops ??
              'Display unverified shops'),
          subtitle: Text(l10n?.admin2_displayUnverifiedShopsHint ??
              'When off, unverified shops are hidden from the Shops tab.'),
          value: draft.displayUnverifiedShops,
          onChanged: (v) {
            draft.displayUnverifiedShops = v;
            onChanged();
          },
        ),
        SwitchListTile(
          title: Text(l10n?.admin2_allowBookingsFromUnverifiedShops ??
              'Allow bookings from unverified shops'),
          subtitle: Text(
              l10n?.admin2_allowBookingsFromUnverifiedShopsHint ??
                  'When off, customers cannot book from unverified shops.'),
          value: draft.allowBookingsFromUnverifiedShops,
          onChanged: (v) {
            draft.allowBookingsFromUnverifiedShops = v;
            onChanged();
          },
        ),
        // AD-M2: the platform's own app language + theme, persisted
        // under the same `app_locale` / `app_theme_mode` keys the
        // customer/owner settings use (AppSettingsCubit). Changing
        // them here changes the admin panel itself, live.
        BlocBuilder<AppSettingsCubit, AppSettingsState>(
          bloc: sl<AppSettingsCubit>(),
          builder: (context, settings) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(l10n?.language ?? 'Language',
                    style: Theme.of(context).textTheme.titleMedium),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: Text(
                          l10n?.languageEnglish ?? 'English'),
                      selected: settings.localeCode == 'en',
                      onSelected: (_) =>
                          sl<AppSettingsCubit>().setLocale('en'),
                    ),
                    ChoiceChip(
                      label:
                          Text(l10n?.languageUrdu ?? 'Urdu'),
                      selected: settings.localeCode == 'ur',
                      onSelected: (_) =>
                          sl<AppSettingsCubit>().setLocale('ur'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(l10n?.theme ?? 'Theme',
                    style: Theme.of(context).textTheme.titleMedium),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: Text(l10n?.themeLight ?? 'Light'),
                      selected: settings.themeMode == ThemeMode.light,
                      onSelected: (_) => sl<AppSettingsCubit>()
                          .setThemeMode(ThemeMode.light),
                    ),
                    ChoiceChip(
                      label: Text(l10n?.themeDark ?? 'Dark'),
                      selected: settings.themeMode == ThemeMode.dark,
                      onSelected: (_) => sl<AppSettingsCubit>()
                          .setThemeMode(ThemeMode.dark),
                    ),
                    ChoiceChip(
                      label: Text(l10n?.themeSystem ?? 'System'),
                      selected: settings.themeMode == ThemeMode.system,
                      onSelected: (_) => sl<AppSettingsCubit>()
                          .setThemeMode(ThemeMode.system),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: isSaving ? null : onSave,
            style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
            child: isSaving
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child:
                            CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 10),
                      Text(l10n?.admin2_saving ?? 'Saving…'),
                    ],
                  )
                : Text(l10n?.admin2_settingsSave ?? 'Save settings'),
          ),
        ),
      ],
    );
  }
}
