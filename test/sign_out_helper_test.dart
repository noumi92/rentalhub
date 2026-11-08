import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalhub/core/di/injection_container.dart';
import 'package:rentalhub/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:rentalhub/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:rentalhub/features/auth/domain/repositories/auth_repository.dart';
import 'package:rentalhub/features/auth/presentation/utils/sign_out_helper.dart';

/// Phone-test #9: sign-out goes through the repository (which already
/// catches errors), shows feedback on failure, and always lands on
/// the login screen on success.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    await sl.reset();
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  tearDown(() async {
    await sl.reset();
  });

  GoRouter testRouter(Widget home) {
    return GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => Scaffold(body: home),
        ),
        GoRoute(
          path: '/auth',
          builder: (context, state) =>
              const Scaffold(body: Text('Login screen')),
        ),
      ],
    );
  }

  Widget signOutButton() {
    return Builder(
      builder: (context) => FilledButton(
        onPressed: () => signOutToAuth(context),
        child: const Text('Sign out'),
      ),
    );
  }

  testWidgets('sign out clears the session and lands on /auth',
      (tester) async {
    final dataSource = AuthRemoteDataSource(prefs: prefs);
    sl.registerLazySingleton<AuthRepository>(
        () => AuthRepositoryImpl(remoteDataSource: dataSource));
    await dataSource.setLoggedIn(true);
    expect(dataSource.isLoggedIn, isTrue);

    await tester.pumpWidget(
        MaterialApp.router(routerConfig: testRouter(signOutButton())));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    expect(find.text('Login screen'), findsOneWidget);
    expect(dataSource.isLoggedIn, isFalse);
  });

  testWidgets('sign out with no repository shows feedback and stays put',
      (tester) async {
    // No AuthRepository registered: sl throws, the helper must catch
    // it and tell the user instead of crashing or navigating.
    await tester.pumpWidget(
        MaterialApp.router(routerConfig: testRouter(signOutButton())));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    expect(find.text('Login screen'), findsNothing);
    expect(
      find.text('Could not sign out. Please try again.'),
      findsOneWidget,
    );
  });
}
