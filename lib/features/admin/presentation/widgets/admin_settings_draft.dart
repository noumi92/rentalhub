import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../data/datasources/admin_support_data_source.dart';

/// The editable draft of `platform_settings/global`, extracted from
/// [AdminPlatformSettingsView] so the view stays under the 250-line
/// cap: the seven field controllers, the three toggles, the last
/// successfully loaded settings (the dirty guard compares against
/// it), and the range validation (AD-M12).
///
/// The draft never talks to Firestore — the view loads into it and
/// saves out of it — so it is unit-testable without Firebase.
class AdminSettingsDraft {
  final citiesController = TextEditingController();
  final categoriesController = TextEditingController();
  final advanceController = TextEditingController();
  final depositController = TextEditingController();
  final graceController = TextEditingController();
  final hoursController = TextEditingController();
  final termsController = TextEditingController();

  bool maintenanceMode = false;
  bool displayUnverifiedShops = true;
  bool allowBookingsFromUnverifiedShops = true;

  /// The last successfully loaded settings, or null before the
  /// first successful load. Null means "not loaded yet" — never
  /// "loaded, empty".
  PlatformSettings? loaded;

  void dispose() {
    citiesController.dispose();
    categoriesController.dispose();
    advanceController.dispose();
    depositController.dispose();
    graceController.dispose();
    hoursController.dispose();
    termsController.dispose();
  }

  /// Populate the draft from loaded settings (or the factory
  /// defaults when no document exists yet — the caller says so
  /// with the banner, not by faking a loaded document).
  void apply(PlatformSettings settings) {
    citiesController.text = settings.liveCities.join(', ');
    categoriesController.text = settings.carCategories.join(', ');
    advanceController.text = settings.advancePercent.toString();
    depositController.text = settings.defaultDepositPkr.toString();
    graceController.text = settings.lateGraceMinutes.toString();
    hoursController.text = settings.supportHours;
    termsController.text = settings.defaultAgreementTerms;
    maintenanceMode = settings.maintenanceMode;
    displayUnverifiedShops = settings.displayUnverifiedShops;
    allowBookingsFromUnverifiedShops =
        settings.allowBookingsFromUnverifiedShops;
    loaded = settings;
  }

  static List<String> _csv(TextEditingController controller) {
    return controller.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  /// The settings the draft currently holds. Callers validate
  /// first — the numbers here must parse (see [validate]).
  PlatformSettings toSettings({
    required int advance,
    required int deposit,
    required int grace,
  }) {
    return PlatformSettings(
      liveCities: _csv(citiesController),
      carCategories: _csv(categoriesController),
      advancePercent: advance,
      defaultDepositPkr: deposit,
      lateGraceMinutes: grace,
      supportHours: hoursController.text.trim(),
      defaultAgreementTerms: termsController.text.trim(),
      maintenanceMode: maintenanceMode,
      displayUnverifiedShops: displayUnverifiedShops,
      allowBookingsFromUnverifiedShops: allowBookingsFromUnverifiedShops,
    );
  }

  /// AD-M12: range validation with localised inline errors —
  /// advance 0–100, deposit >= 0, late grace >= 0. The keys are
  /// 'advance' | 'deposit' | 'grace'; an empty map means valid.
  /// A null [l10n] (tests without delegates) falls back to English.
  Map<String, String> validate(AppLocalizations? l10n) {
    final errors = <String, String>{};
    final advance = int.tryParse(advanceController.text.trim());
    final deposit = int.tryParse(depositController.text.trim());
    final grace = int.tryParse(graceController.text.trim());
    if (advance == null || advance < 0 || advance > 100) {
      errors['advance'] = l10n?.admin2_settingsAdvanceRange ??
          'Advance must be between 0 and 100.';
    }
    if (deposit == null || deposit < 0) {
      errors['deposit'] = l10n?.admin2_settingsDepositNegative ??
          'Security cannot be negative.';
    }
    if (grace == null || grace < 0) {
      errors['grace'] = l10n?.admin2_settingsGraceNegative ??
          'Late grace cannot be negative.';
    }
    return errors;
  }

  /// True when the draft differs from the last successfully loaded
  /// settings (AD-M12 dirty guard). False before the first load.
  bool get isDirty {
    final saved = loaded;
    if (saved == null) return false;
    final advance = int.tryParse(advanceController.text.trim());
    final deposit = int.tryParse(depositController.text.trim());
    final grace = int.tryParse(graceController.text.trim());
    if (advance == null || deposit == null || grace == null) return true;
    return toSettings(advance: advance, deposit: deposit, grace: grace) !=
        saved;
  }
}
