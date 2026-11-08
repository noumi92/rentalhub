import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/data/offline_sync_queue.dart';
import '../../../../core/data/queued_upload.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/cpanel_storage_client.dart';
import '../../../../core/network/firestore_service.dart';
import '../models/user_model.dart';
import '../../../notifications/data/services/push_token_service.dart';

class AuthRemoteDataSource {
  final SharedPreferences prefs;
  final fb.FirebaseAuth? auth;
  final FirestoreService? firestoreService;
  final CPanelStorageClient? storageClient;

  /// Phase B (B3): the persisted pending-write store. When set, a
  /// failed profile-photo upload is queued instead of filed as a
  /// made-up URL.
  final OfflineSyncQueue? syncQueue;

  static const String _isLoggedInKey = 'rentalhub_is_logged_in';
  static const String _onboardingCompletedKey = 'rentalhub_onboarding_completed';
  static const String _roleKey = 'rentalhub_locked_role';
  static const String _fullNameKey = 'rentalhub_user_full_name';
  static const String _phoneKey = 'rentalhub_user_phone';
  static const String _emailKey = 'rentalhub_user_email';
  static const String _uidKey = 'rentalhub_user_uid';
  static const String _profilePhotoKey = 'rentalhub_user_profile_photo';

  bool get isLoggedIn => prefs.getBool(_isLoggedInKey) ?? (auth?.currentUser != null);
  bool get isOnboardingCompleted => prefs.getBool(_onboardingCompletedKey) ?? false;
  String? get lockedRole => prefs.getString(_roleKey);
  String get fullName => prefs.getString(_fullNameKey) ?? '';
  String get phoneNumber => prefs.getString(_phoneKey) ?? '';
  String get email => prefs.getString(_emailKey) ?? (auth?.currentUser?.email ?? '');
  String? get profilePhotoUrl => prefs.getString(_profilePhotoKey);
  bool get hasProfileInfo => fullName.trim().isNotEmpty && phoneNumber.trim().isNotEmpty;

  /// Phone-test #2: restores the Firestore profile into the local
  /// prefs cache after a successful sign-in. A fresh device (or
  /// cleared app data) has no role/onboarding state locally, but the
  /// `users/{uid}` doc does — without this restore the guard sends
  /// every returning user back to the role screen. Best-effort: a
  /// missing doc (offline read failure) or a prefs failure keeps the
  /// current behaviour instead of blocking sign-in. Local values win
  /// when present (the locked role is immutable); only missing fields
  /// are filled, and onboarding is only ever flipped to completed.
  Future<void> _restoreProfileFromRemote(UserModel? remote) async {
    if (remote == null) return;
    try {
      if (prefs.getString(_roleKey) == null &&
          remote.role != null &&
          remote.role!.isNotEmpty) {
        await prefs.setString(_roleKey, remote.role!);
      }
      if (remote.isOnboardingCompleted) {
        await prefs.setBool(_onboardingCompletedKey, true);
      }
      if ((prefs.getString(_fullNameKey) ?? '').isEmpty &&
          remote.fullName.trim().isNotEmpty) {
        await prefs.setString(_fullNameKey, remote.fullName.trim());
      }
      if ((prefs.getString(_phoneKey) ?? '').isEmpty &&
          remote.phoneNumber.trim().isNotEmpty) {
        await prefs.setString(_phoneKey, remote.phoneNumber.trim());
      }
    } catch (_) {
      debugPrint('Profile restore notice: could not cache remote profile');
    }
  }

  Future<void> setLoggedIn(bool value) async => await prefs.setBool(_isLoggedInKey, value);
  Future<void> setOnboardingCompleted(bool value) async => await prefs.setBool(_onboardingCompletedKey, value);

  Future<void> saveProfileInfo({
    required String fullName,
    required String phone,
    File? profilePhotoFile,
  }) async {
    await prefs.setString(_fullNameKey, fullName.trim());
    await prefs.setString(_phoneKey, phone.trim());

    String uid = 'usr_pk_001';
    if (auth?.currentUser != null) {
      uid = auth!.currentUser!.uid;
    } else if (prefs.getString(_uidKey) != null) {
      uid = prefs.getString(_uidKey)!;
    }

    String? photoUrl = prefs.getString(_profilePhotoKey);

    // Upload to cPanel if image file provided.
    // Phase B (B3): a failed upload is queued (the photo lands on
    // sync) — never a made-up signed URL filed as the user's photo.
    if (profilePhotoFile != null && storageClient != null) {
      try {
        if (await profilePhotoFile.exists()) {
          final fileKey = await storageClient!.uploadFile(
            file: profilePhotoFile,
            userUid: uid,
            folder: 'profile',
          );
          photoUrl = storageClient!.getSignedMediaUrl(fileKey, uid);
        }
      } catch (e) {
        debugPrint('cPanel profile upload notice: $e (queuing for sync)');
        final queue = syncQueue;
        if (queue != null && await profilePhotoFile.exists()) {
          await enqueueUpload(
            file: profilePhotoFile,
            userUid: uid,
            folder: 'profile',
            queue: queue,
            targetCollection: 'users',
            targetDocId: uid,
            targetField: 'profile_photo_url',
          );
        }
      }
      if (photoUrl != null) {
        await prefs.setString(_profilePhotoKey, photoUrl);
      }
    }

    final existingUser = firestoreService != null ? await firestoreService!.getUser(uid) : null;
    final user = UserModel(
      uid: uid,
      email: prefs.getString(_emailKey) ?? (auth?.currentUser?.email ?? ''),
      fullName: fullName.trim(),
      phoneNumber: phone.trim(),
      profilePhotoUrl: photoUrl ?? existingUser?.profilePhotoUrl,
      role: prefs.getString(_roleKey) ?? existingUser?.role,
      isVerified: existingUser?.isVerified ?? false,
      trustScore: existingUser?.trustScore ?? 5.0,
      totalTrips: existingUser?.totalTrips ?? 0,
      isOnboardingCompleted: isOnboardingCompleted || (existingUser?.isOnboardingCompleted ?? false),
    );

    if (firestoreService != null) {
      await firestoreService!.saveUser(user);
    // Phase E (E3): register this device for push announcements.
    // Fire-and-forget — a push failure must never block sign-in.
    unawaited(PushTokenService.registerToken());
    }
  }

  AuthRemoteDataSource({
    required this.prefs,
    this.auth,
    this.firestoreService,
    this.storageClient,
    this.syncQueue,
  });

  Future<UserModel> signInWithGoogle() async {
    String uid = prefs.getString(_uidKey) ?? 'usr_pk_001';
    String email = prefs.getString(_emailKey) ?? 'ahmed.raza@rentalhub.pk';
    String fullName = prefs.getString(_fullNameKey) ?? 'Ahmed Raza';

    if (auth != null) {
      try {
        final GoogleSignIn googleSignIn = GoogleSignIn(
          serverClientId: '139498327816-k5sjvum2hpuo30oiooh7u6ap8nsu71m7.apps.googleusercontent.com',
        );
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
        if (googleUser == null) {
          throw const ServerException(message: 'Google Sign-In was cancelled.');
        }

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final fb.AuthCredential credential = fb.GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final userCredential = await auth!.signInWithCredential(credential);
        if (userCredential.user != null) {
          final fbUser = userCredential.user!;
          uid = fbUser.uid;
          email = fbUser.email ?? email;
          fullName = fbUser.displayName ?? (fullName.isNotEmpty ? fullName : 'RentalHub User');
        }
      } on fb.FirebaseAuthException catch (e) {
        throw ServerException(message: e.message ?? 'Google Sign-In failed via Firebase.');
      } on PlatformException catch (e) {
        debugPrint('Google Sign-In PlatformException: code=${e.code}, message=${e.message}, details=${e.details}');
        final msg = e.message ?? '';
        if (e.code == 'sign_in_canceled' || msg.contains('12501')) {
          throw const ServerException(message: 'Google Sign-In was cancelled.');
        } else if (msg.contains('10')) {
          throw const ServerException(
            message: 'Google Sign-In configuration error (ApiException: 10). Ensure the app with package com.primedigit.renthub.rent_hub is running and clean installed.',
          );
        } else if (msg.contains('12500')) {
          throw const ServerException(
            message: 'Google Sign-In failed (ApiException: 12500). Please ensure Support Email is set in Firebase Console Settings.',
          );
        } else if (msg.contains('7')) {
          throw const ServerException(
            message: 'Network error during Google Sign-In. Please check your internet connection.',
          );
        }
        throw ServerException(message: 'Google Sign-In failed: ${e.message ?? e.code}');
      } catch (e) {
        if (e is ServerException) rethrow;
        throw ServerException(message: 'Google Sign-In failed: $e');
      }
    }

    await prefs.setString(_emailKey, email);
    await prefs.setString(_uidKey, uid);
    if (fullName.isNotEmpty && (prefs.getString(_fullNameKey) == null || prefs.getString(_fullNameKey)!.isEmpty)) {
      await prefs.setString(_fullNameKey, fullName);
    }
    await prefs.setBool(_isLoggedInKey, true);

    final existingUser = firestoreService != null ? await firestoreService!.getUser(uid) : null;
    // Phone-test #2: restore the Firestore role/profile into the
    // local cache BEFORE the destination is resolved, so a returning
    // user on a fresh device goes to their dashboard, not the role
    // screen. A failed/offline read leaves existingUser null and the
    // behaviour below is unchanged.
    await _restoreProfileFromRemote(existingUser);
    final existingRole = prefs.getString(_roleKey);
    final user = UserModel(
      uid: uid,
      email: email,
      fullName: prefs.getString(_fullNameKey) ?? (existingUser?.fullName.isNotEmpty == true ? existingUser!.fullName : fullName),
      phoneNumber: prefs.getString(_phoneKey) ?? existingUser?.phoneNumber ?? '',
      profilePhotoUrl: prefs.getString(_profilePhotoKey) ?? existingUser?.profilePhotoUrl,
      role: existingRole ?? existingUser?.role,
      isVerified: existingUser?.isVerified ?? false,
      trustScore: existingUser?.trustScore ?? 5.0,
      totalTrips: existingUser?.totalTrips ?? 0,
      isOnboardingCompleted: isOnboardingCompleted || (existingUser?.isOnboardingCompleted ?? false),
    );

    if (firestoreService != null) {
      await firestoreService!.saveUser(user);
    // Phase E (E3): register this device for push announcements.
    // Fire-and-forget — a push failure must never block sign-in.
    unawaited(PushTokenService.registerToken());
    }
    return user;
  }

  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty || password.length < 6) {
      throw const ServerException(
        message: 'Invalid email or password (min 6 characters).',
      );
    }

    String uid = 'usr_pk_001';

    // If live FirebaseAuth is available, authenticate strictly against registered Firebase accounts
    if (auth != null) {
      try {
        final credential = await auth!.signInWithEmailAndPassword(
          email: trimmedEmail,
          password: password,
        );
        if (credential.user != null) {
          uid = credential.user!.uid;
        }
      } on fb.FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found') {
          throw const ServerException(
            message: 'No registered account found with this email. Please check your email or contact support.',
          );
        } else if (e.code == 'wrong-password') {
          throw const ServerException(
            message: 'Incorrect password. Please try again.',
          );
        } else if (e.code == 'invalid-credential') {
          throw const ServerException(
            message: 'Invalid email or password. Please verify your credentials.',
          );
        } else if (e.code == 'invalid-email') {
          throw const ServerException(
            message: 'Invalid email address format.',
          );
        } else if (e.code == 'user-disabled') {
          throw const ServerException(
            message: 'This user account has been disabled.',
          );
        } else {
          throw ServerException(
            message: e.message ?? 'Firebase authentication failed.',
          );
        }
      } catch (e) {
        if (e is ServerException) rethrow;
        throw ServerException(message: 'Authentication error: $e');
      }
    }

    await prefs.setString(_emailKey, trimmedEmail);
    await prefs.setString(_uidKey, uid);
    await prefs.setBool(_isLoggedInKey, true);

    final existingUser = firestoreService != null ? await firestoreService!.getUser(uid) : null;
    // Phone-test #2: restore the Firestore role/profile into the
    // local cache BEFORE the destination is resolved (see Google
    // sign-in above).
    await _restoreProfileFromRemote(existingUser);
    final existingRole = prefs.getString(_roleKey);
    final user = UserModel(
      uid: uid,
      email: trimmedEmail,
      fullName: prefs.getString(_fullNameKey) ?? existingUser?.fullName ?? '',
      phoneNumber: prefs.getString(_phoneKey) ?? existingUser?.phoneNumber ?? '',
      profilePhotoUrl: prefs.getString(_profilePhotoKey) ?? existingUser?.profilePhotoUrl,
      role: existingRole ?? existingUser?.role,
      isVerified: existingUser?.isVerified ?? false,
      trustScore: existingUser?.trustScore ?? 5.0,
      totalTrips: existingUser?.totalTrips ?? 0,
      isOnboardingCompleted: isOnboardingCompleted || (existingUser?.isOnboardingCompleted ?? false),
    );

    if (firestoreService != null) {
      await firestoreService!.saveUser(user);
    // Phase E (E3): register this device for push announcements.
    // Fire-and-forget — a push failure must never block sign-in.
    unawaited(PushTokenService.registerToken());
    }

    return user;
  }

  /// Enforces DOC-2 & DOC-8 single-role immutability: once a role is set,
  /// attempting to overwrite it with a different role throws RoleImmutableException.
  Future<UserModel> assignPermanentRole({
    required String role,
    required String fullName,
    required String phone,
  }) async {
    if (role != 'customer' && role != 'owner') {
      throw ServerException(message: 'Invalid role: $role');
    }
    final existingRole = prefs.getString(_roleKey);
    if (existingRole != null && existingRole != role) {
      throw RoleImmutableException(
        'Permanent role "$existingRole" is already locked for this account and cannot be changed to "$role".',
      );
    }
    await prefs.setString(_roleKey, role);
    await prefs.setString(_fullNameKey, fullName);
    await prefs.setString(_phoneKey, phone);

    if (role == 'customer') {
      await prefs.setBool(_onboardingCompletedKey, true);
    }

    final uid = prefs.getString(_uidKey) ?? 'usr_pk_001';
    final existingUser = firestoreService != null ? await firestoreService!.getUser(uid) : null;
    final user = UserModel(
      uid: uid,
      email: prefs.getString(_emailKey) ?? existingUser?.email ?? '',
      fullName: fullName,
      phoneNumber: phone,
      profilePhotoUrl: prefs.getString(_profilePhotoKey) ?? existingUser?.profilePhotoUrl,
      role: role,
      isVerified: existingUser?.isVerified ?? false,
      trustScore: existingUser?.trustScore ?? 5.0,
      totalTrips: existingUser?.totalTrips ?? 0,
      isOnboardingCompleted: isOnboardingCompleted,
    );

    if (firestoreService != null) {
      await firestoreService!.saveUser(user);
    // Phase E (E3): register this device for push announcements.
    // Fire-and-forget — a push failure must never block sign-in.
    unawaited(PushTokenService.registerToken());
    }

    return user;
  }

  Future<UserModel?> getCurrentUser() async {
    if (!isLoggedIn) return null;
    final role = prefs.getString(_roleKey);
    final uid = prefs.getString(_uidKey) ?? (auth?.currentUser?.uid ?? 'usr_pk_001');

    if (firestoreService != null) {
      final remoteUser = await firestoreService!.getUser(uid);
      if (remoteUser != null) return remoteUser;
    }

    return UserModel(
      uid: uid,
      email: prefs.getString(_emailKey) ?? (auth?.currentUser?.email ?? ''),
      fullName: prefs.getString(_fullNameKey) ?? '',
      phoneNumber: prefs.getString(_phoneKey) ?? '',
      profilePhotoUrl: prefs.getString(_profilePhotoKey),
      role: role,
      isVerified: false,
      trustScore: 5.0,
      totalTrips: 0,
      isOnboardingCompleted: isOnboardingCompleted,
    );
  }

  Future<void> signOut() async {
    if (auth != null) {
      try {
        await auth!.signOut();
      } catch (e) {
        debugPrint('FirebaseAuth signOut error: $e');
      }
    }
    await prefs.setBool(_isLoggedInKey, false);
    await prefs.setBool(_onboardingCompletedKey, false);
    await prefs.remove(_emailKey);
    await prefs.remove(_uidKey);
    await prefs.remove(_profilePhotoKey);
    await prefs.remove(_fullNameKey);
    await prefs.remove(_phoneKey);
    await prefs.remove(_roleKey);
  }
}

class RoleImmutableException implements Exception {
  final String message;
  RoleImmutableException(this.message);

  @override
  String toString() => message;
}
