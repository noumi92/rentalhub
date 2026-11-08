import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Phase B (G3): the app's language and theme, persisted and
/// applied for real. The old language toggle was a local `setState`
/// on one screen and the theme was hardcoded to light in main.dart
/// — this cubit is what the settings screen and `MaterialApp` both
/// read. The `.arb` files under `lib/l10n/` carry the strings; the
/// settings screen is the first fully translated screen and the
/// rest of the app follows in the rulebook's language track.
class AppSettingsState extends Equatable {
  final String localeCode; // 'en' | 'ur'
  final ThemeMode themeMode;

  const AppSettingsState({
    this.localeCode = 'en',
    // Phone-test #16: Light is the default (was System). A saved user
    // choice is untouched — only fresh installs / unknown stored
    // values start in Light. Dark stays available in Settings.
    this.themeMode = ThemeMode.light,
  });

  Locale get locale => Locale(localeCode);

  AppSettingsState copyWith({String? localeCode, ThemeMode? themeMode}) {
    return AppSettingsState(
      localeCode: localeCode ?? this.localeCode,
      themeMode: themeMode ?? this.themeMode,
    );
  }

  @override
  List<Object?> get props => [localeCode, themeMode];
}

class AppSettingsCubit extends Cubit<AppSettingsState> {
  final SharedPreferences prefs;

  static const String localeKey = 'app_locale';
  static const String themeKey = 'app_theme_mode';

  AppSettingsCubit({required this.prefs})
      : super(_load(prefs));

  static AppSettingsState _load(SharedPreferences prefs) {
    final localeCode = prefs.getString(localeKey) ?? 'en';
    final themeRaw = prefs.getString(themeKey);
    final themeMode = switch (themeRaw) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      // 'system' stays a valid saved choice; an absent or unknown
      // stored value falls back to Light (#16), not System.
      'system' => ThemeMode.system,
      _ => ThemeMode.light,
    };
    return AppSettingsState(localeCode: localeCode, themeMode: themeMode);
  }

  Future<void> setLocale(String localeCode) async {
    if (localeCode != 'en' && localeCode != 'ur') return;
    await prefs.setString(localeKey, localeCode);
    emit(state.copyWith(localeCode: localeCode));
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final raw = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await prefs.setString(themeKey, raw);
    emit(state.copyWith(themeMode: mode));
  }
}
