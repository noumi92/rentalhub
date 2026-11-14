import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rentalhub/features/auth/data/datasources/auth_remote_data_source.dart';

/// Item 1: app sign-out must also sign out of GoogleSignIn, or the
/// next Google sign-in silently reuses the previous account instead
/// of showing the device account picker (GoogleSignIn.signIn only
/// shows the picker when no Google session is cached).
class _RecordingGoogleSignIn extends GoogleSignIn {
  _RecordingGoogleSignIn()
      : super(serverClientId: AuthRemoteDataSource.googleServerClientId);

  bool signOutCalled = false;

  @override
  Future<bool> isSignedIn() async => true;

  @override
  Future<GoogleSignInAccount?> signOut() async {
    signOutCalled = true;
    return null;
  }
}

class _ThrowingGoogleSignIn extends GoogleSignIn {
  @override
  Future<bool> isSignedIn() async => true;

  @override
  Future<GoogleSignInAccount?> signOut() async {
    throw Exception('no Google session');
  }
}

class _NoSessionGoogleSignIn extends GoogleSignIn {
  bool signOutCalled = false;

  @override
  Future<bool> isSignedIn() async => false;

  @override
  Future<GoogleSignInAccount?> signOut() async {
    signOutCalled = true;
    return null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  test('signOut signs out of GoogleSignIn and clears the session',
      () async {
    final googleSignIn = _RecordingGoogleSignIn();
    final dataSource =
        AuthRemoteDataSource(prefs: prefs, googleSignIn: googleSignIn);
    await dataSource.setLoggedIn(true);
    expect(dataSource.isLoggedIn, isTrue);

    await dataSource.signOut();

    expect(googleSignIn.signOutCalled, isTrue);
    expect(dataSource.isLoggedIn, isFalse);
  });

  test('a Google sign-out failure does not block app sign-out', () async {
    final dataSource = AuthRemoteDataSource(
      prefs: prefs,
      googleSignIn: _ThrowingGoogleSignIn(),
    );
    await dataSource.setLoggedIn(true);

    await dataSource.signOut();

    expect(dataSource.isLoggedIn, isFalse);
  });

  test('signOut skips GoogleSignIn when no Google session exists',
      () async {
    final googleSignIn = _NoSessionGoogleSignIn();
    final dataSource =
        AuthRemoteDataSource(prefs: prefs, googleSignIn: googleSignIn);
    await dataSource.setLoggedIn(true);

    await dataSource.signOut();

    expect(googleSignIn.signOutCalled, isFalse);
    expect(dataSource.isLoggedIn, isFalse);
  });
}
