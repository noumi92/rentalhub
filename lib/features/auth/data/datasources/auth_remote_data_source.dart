import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/error/exceptions.dart';
import '../models/user_model.dart';

class AuthRemoteDataSource {
  final SharedPreferences prefs;

  static const String _roleKey = 'rentalhub_locked_role';
  static const String _fullNameKey = 'rentalhub_user_full_name';
  static const String _phoneKey = 'rentalhub_user_phone';
  static const String _emailKey = 'rentalhub_user_email';

  AuthRemoteDataSource({required this.prefs});

  Future<UserModel> signInWithGoogle() async {
    final existingRole = prefs.getString(_roleKey);
    return UserModel(
      uid: 'usr_pk_001',
      email: prefs.getString(_emailKey) ?? 'ahmed.raza@rentalhub.pk',
      fullName: prefs.getString(_fullNameKey) ?? 'Ahmed Raza',
      phoneNumber: prefs.getString(_phoneKey) ?? '+92 300 4129811',
      role: existingRole,
      isVerified: true,
      trustScore: 4.9,
      totalTrips: 7,
    );
  }

  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (email.trim().isEmpty || password.length < 6) {
      throw const ServerException(
        message: 'Invalid email or password (min 6 characters).',
      );
    }
    await prefs.setString(_emailKey, email.trim());
    final existingRole = prefs.getString(_roleKey);
    return UserModel(
      uid: 'usr_pk_001',
      email: email.trim(),
      fullName: prefs.getString(_fullNameKey) ?? 'Ahmed Raza',
      phoneNumber: prefs.getString(_phoneKey) ?? '+92 300 4129811',
      role: existingRole,
      isVerified: true,
      trustScore: 4.9,
      totalTrips: 7,
    );
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

    return UserModel(
      uid: 'usr_pk_001',
      email: prefs.getString(_emailKey) ?? 'ahmed.raza@rentalhub.pk',
      fullName: fullName,
      phoneNumber: phone,
      role: role,
      isVerified: true,
      trustScore: 4.9,
      totalTrips: 7,
    );
  }

  Future<UserModel?> getCurrentUser() async {
    final role = prefs.getString(_roleKey);
    return UserModel(
      uid: 'usr_pk_001',
      email: prefs.getString(_emailKey) ?? 'ahmed.raza@rentalhub.pk',
      fullName: prefs.getString(_fullNameKey) ?? 'Ahmed Raza',
      phoneNumber: prefs.getString(_phoneKey) ?? '+92 300 4129811',
      role: role,
      isVerified: true,
      trustScore: 4.9,
      totalTrips: 7,
    );
  }

  Future<void> signOut() async {
    await prefs.remove(_emailKey);
  }
}

class RoleImmutableException implements Exception {
  final String message;
  RoleImmutableException(this.message);

  @override
  String toString() => message;
}
