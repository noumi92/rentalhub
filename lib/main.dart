import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'features/notifications/data/services/announcement_push_handler.dart';
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
import 'core/platform/app_platform.dart';
import 'core/routing/app_router.dart';
import 'core/routing/route_names.dart';
import 'core/settings/app_settings_cubit.dart';
import 'core/theme/app_theme.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  // Phase D (D2): edge-to-edge — the app draws behind the status and
  // navigation bars. The bars themselves are styled per theme by the
  // AnnotatedRegion around MaterialApp.router below (never a
  // setSystemUIOverlayStyle side effect inside build); every screen
  // insets its own content with SafeArea.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

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
  // Admin-integration audit (2026-11-10): listen for taps on admin
  // announcement pushes (data: {announcementId}); the subscription
  // just below routes them to the announcement detail screen.
  AnnouncementPushHandler.start();
  // Admin final pass (2026-11-10): the consumer — a tapped push
  // routes to the announcement detail screen. The handler never
  // navigates itself and never throws; a bad id is still a route
  // the detail screen answers with its not-found state.
  AnnouncementPushHandler.announcementOpened.listen((id) {
    try {
      AppRouter.router.go(
        RouteNames.customerAnnouncement.replaceFirst(':id', id),
      );
    } catch (e) {
      debugPrint('Announcement push navigation failed: $e');
    }
  });
  runApp(const RentalHubApp());
  // Web admin panel: there is no SplashView to dismiss the native
  // splash, so remove it once the first frame renders. Mobile keeps
  // SplashView, which removes it itself.
  if (AppPlatform.isWeb) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
    });
  }
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
        // Phase D (D2): the system bars follow the theme — light icons
        // on the dark header / dark scaffold, dark icons on the light
        // one. The region wins over MaterialApp's own default overlay
        // style; transparent bars keep the edge-to-edge draw.
        final isDark = settings.themeMode == ThemeMode.dark ||
            (settings.themeMode == ThemeMode.system &&
                MediaQuery.platformBrightnessOf(context) == Brightness.dark);
        final overlayStyle = SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness:
              isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness:
              isDark ? Brightness.light : Brightness.dark,
        );
        // Phase B (B5): the sync-status cubit is provided app-wide
        // so every screen can show the offline banner / sync chips.
        return BlocProvider<SyncStatusCubit>.value(
          value: sl<SyncStatusCubit>(),
          child: AnnotatedRegion<SystemUiOverlayStyle>(
            value: overlayStyle,
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
          ),
        );
      },
    );
  }
}
