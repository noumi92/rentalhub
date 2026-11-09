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
/// Audit impl (O33): the five in-app notification types the owner
/// can mute individually. These are preferences only — they send
/// nothing; the in-app notifications already exist, and the toggles
/// only record which types the owner wants to see.
enum NotificationPreference {
  bookingRequests,
  paymentProofs,
  handover,
  returns,
  maintenance,
}

class AppSettingsState extends Equatable {
  final String localeCode; // 'en' | 'ur'
  final ThemeMode themeMode;
  // Audit impl (O33): notification preferences, all on by default.
  final bool notifyBookingRequests;
  final bool notifyPaymentProofs;
  final bool notifyHandover;
  final bool notifyReturns;
  final bool notifyMaintenance;

  const AppSettingsState({
    this.localeCode = 'en',
    // Phone-test #16: Light is the default (was System). A saved user
    // choice is untouched — only fresh installs / unknown stored
    // values start in Light. Dark stays available in Settings.
    this.themeMode = ThemeMode.light,
    this.notifyBookingRequests = true,
    this.notifyPaymentProofs = true,
    this.notifyHandover = true,
    this.notifyReturns = true,
    this.notifyMaintenance = true,
  });

  Locale get locale => Locale(localeCode);

  AppSettingsState copyWith({
    String? localeCode,
    ThemeMode? themeMode,
    bool? notifyBookingRequests,
    bool? notifyPaymentProofs,
    bool? notifyHandover,
    bool? notifyReturns,
    bool? notifyMaintenance,
  }) {
    return AppSettingsState(
      localeCode: localeCode ?? this.localeCode,
      themeMode: themeMode ?? this.themeMode,
      notifyBookingRequests:
          notifyBookingRequests ?? this.notifyBookingRequests,
      notifyPaymentProofs: notifyPaymentProofs ?? this.notifyPaymentProofs,
      notifyHandover: notifyHandover ?? this.notifyHandover,
      notifyReturns: notifyReturns ?? this.notifyReturns,
      notifyMaintenance: notifyMaintenance ?? this.notifyMaintenance,
    );
  }

  @override
  List<Object?> get props => [
        localeCode,
        themeMode,
        notifyBookingRequests,
        notifyPaymentProofs,
        notifyHandover,
        notifyReturns,
        notifyMaintenance,
      ];
}

class AppSettingsCubit extends Cubit<AppSettingsState> {
  final SharedPreferences prefs;

  static const String localeKey = 'app_locale';
  static const String themeKey = 'app_theme_mode';
  // Audit impl (O33): one SharedPreferences bool per notification
  // type; absent means on (the default for a fresh install).
  static const String notifBookingRequestsKey = 'notif_booking_requests';
  static const String notifPaymentProofsKey = 'notif_payment_proofs';
  static const String notifHandoverKey = 'notif_handover';
  static const String notifReturnsKey = 'notif_returns';
  static const String notifMaintenanceKey = 'notif_maintenance';

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
    return AppSettingsState(
      localeCode: localeCode,
      themeMode: themeMode,
      notifyBookingRequests: prefs.getBool(notifBookingRequestsKey) ?? true,
      notifyPaymentProofs: prefs.getBool(notifPaymentProofsKey) ?? true,
      notifyHandover: prefs.getBool(notifHandoverKey) ?? true,
      notifyReturns: prefs.getBool(notifReturnsKey) ?? true,
      notifyMaintenance: prefs.getBool(notifMaintenanceKey) ?? true,
    );
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

  /// Audit impl (O33): persist one notification preference. The
  /// value is written first so a rebuild never shows a stale toggle.
  Future<void> setNotificationPreference(
      NotificationPreference pref, bool enabled) async {
    final key = switch (pref) {
      NotificationPreference.bookingRequests => notifBookingRequestsKey,
      NotificationPreference.paymentProofs => notifPaymentProofsKey,
      NotificationPreference.handover => notifHandoverKey,
      NotificationPreference.returns => notifReturnsKey,
      NotificationPreference.maintenance => notifMaintenanceKey,
    };
    await prefs.setBool(key, enabled);
    emit(switch (pref) {
      NotificationPreference.bookingRequests =>
        state.copyWith(notifyBookingRequests: enabled),
      NotificationPreference.paymentProofs =>
        state.copyWith(notifyPaymentProofs: enabled),
      NotificationPreference.handover =>
        state.copyWith(notifyHandover: enabled),
      NotificationPreference.returns =>
        state.copyWith(notifyReturns: enabled),
      NotificationPreference.maintenance =>
        state.copyWith(notifyMaintenance: enabled),
    });
  }
}
