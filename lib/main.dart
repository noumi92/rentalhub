import 'dart:async';

import 'package:flutter/material.dart';
import 'features/notifications/data/services/push_token_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'firebase_options.dart';
import 'core/data/firestore_persistence.dart';
import 'core/data/sync_engine.dart';
import 'core/data/sync_status_cubit.dart';
import 'core/di/injection_container.dart';
import 'core/network/connectivity_service.dart';
import 'core/routing/app_router.dart';
import 'core/settings/app_settings_cubit.dart';
import 'core/theme/app_theme.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization notice: $e');
  }
  // Phase B (B1): pin the Firestore offline baseline before anything
  // touches Firestore — persistence on, 100 MB cache.
  FirestorePersistence.configure();
  await initDependencies();
  // Phase B (B2): start listening for reconnects — the sync engine
  // drains the offline queue on every offline → online transition —
  // and drain once at launch for entries left over from a previous
  // session (e.g. the app was killed while offline).
  final syncEngine = sl<SyncEngine>();
  final connectivity = sl<ConnectivityService>();
  syncEngine.startAutoSync(connectivity);
  await connectivity.start();
  // Phase B (B5): the visible sync state starts listening too.
  unawaited(sl<SyncStatusCubit>().start());
  if (connectivity.isOnline) {
    unawaited(syncEngine.drain());
  }
  // Phase E (E3): listen for FCM token rotation and register the
  // current token when the app starts (no-op when signed out).
  PushTokenService.startRefreshListener();
  await PushTokenService.registerToken();
  runApp(const RentalHubApp());
}

class RentalHubApp extends StatelessWidget {
  const RentalHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Phase B (G3): the locale and theme come from the settings
    // cubit now — the old build hardcoded ThemeMode.light and had
    // no locale at all.
    return BlocBuilder<AppSettingsCubit, AppSettingsState>(
      bloc: sl<AppSettingsCubit>(),
      builder: (context, settings) {
        // Phase B (B5): the sync-status cubit is provided app-wide
        // so every screen can show the offline banner / sync chips.
        return BlocProvider<SyncStatusCubit>.value(
          value: sl<SyncStatusCubit>(),
          child: MaterialApp.router(
          title: 'RentalHub Pakistan',
          debugShowCheckedModeBanner: false,
          // Phase A (A1): the font family follows the locale — Inter for
          // Latin, Noto Nastaliq Urdu for Urdu — so Urdu text never renders
          // in the default Material font.
          theme: AppTheme.lightThemeFor(
            fontFamily: AppTheme.fontFamilyFor(settings.locale),
          ),
          darkTheme: AppTheme.darkThemeFor(
            fontFamily: AppTheme.fontFamilyFor(settings.locale),
          ),
          themeMode: settings.themeMode,
          locale: settings.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          routerConfig: AppRouter.router,
          ),
        );
      },
    );
  }
}
