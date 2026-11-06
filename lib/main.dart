import 'package:flutter/material.dart';
import 'features/notifications/data/services/push_token_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'firebase_options.dart';
import 'core/di/injection_container.dart';
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
  await initDependencies();
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
        return MaterialApp.router(
          title: 'RentalHub Pakistan',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
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
        );
      },
    );
  }
}
