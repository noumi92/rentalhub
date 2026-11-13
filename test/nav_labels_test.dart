// Audit 2026-11-13, SH-N15 — nav label localisation.
//
// The `labelFor` switch used to map keys to inconsistently-named
// getters (`navFleet` → `dashboardFleet`, `navWallet` → `walletLabel`,
// `navCustomers` → `customersTitle`) and one key was literally
// `tab2_navShops` — a leftover numbering artefact. A renamed key fell
// back to the English `label` silently. The keys are now normalised
// (`nav*` with a 1:1 getter); this test asserts every shipped tab's
// key resolves to a non-empty localised string in both locales, and
// that the Urdu label is not just the English fallback (which is what
// an unmapped key would produce).
import 'package:flutter_test/flutter_test.dart';
import 'package:rentalhub/core/routing/app_router.dart';
import 'package:rentalhub/core/widgets/app_shell_nav.dart';
import 'package:rentalhub/l10n/app_localizations_en.dart';
import 'package:rentalhub/l10n/app_localizations_ur.dart';

void main() {
  test('every ShellNavItem.l10nKey resolves in both locales (SH-N15)', () {
    final en = AppLocalizationsEn();
    final ur = AppLocalizationsUr();
    final items = [...AppRouter.customerTabs, ...AppRouter.ownerTabs];
    expect(items.length, 10,
        reason: 'Expected 10 tabs (5 customer + 5 owner).');
    final keys = <String>{};
    for (final item in items) {
      expect(item.l10nKey, isNotNull, reason: 'Tab "${item.label}" has no l10nKey.');
      expect(item.l10nKey, startsWith('nav'),
          reason: 'Tab key "${item.l10nKey}" is not a normalised nav* key.');
      expect(keys.add(item.l10nKey!), isTrue,
          reason: 'Duplicate nav key "${item.l10nKey}".');
      final enLabel = AppShellNav.labelFor(en, item);
      final urLabel = AppShellNav.labelFor(ur, item);
      expect(enLabel.trim(), isNotEmpty,
          reason: 'Tab key "${item.l10nKey}" resolves to an empty English label.');
      expect(urLabel.trim(), isNotEmpty,
          reason: 'Tab key "${item.l10nKey}" resolves to an empty Urdu label.');
      expect(urLabel, isNot(enLabel),
          reason:
              'Tab key "${item.l10nKey}" fell back to the English label in Urdu — the key is unmapped in labelFor.');
    }
  });
}
